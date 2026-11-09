import XCTest
@testable import FoldPulseCore

final class ReconcilerTests: XCTestCase {
    private let now = Fixture.date("2026-11-09T14:00:00Z")
    private func e(_ type: EventType, _ source: DetectionSource, _ iso: String) -> FoldEvent {
        Fixture.event(type, source, at: iso)
    }

    /// Applies a plan to an in-memory log (what EventStore does with SwiftData).
    private func apply(_ plan: ReconcilePlan, to events: [FoldEvent]) -> [FoldEvent] {
        var result = events.map { event -> FoldEvent in
            var event = event
            if let of = plan.markDuplicate[event.id] { event.duplicateOf = of }
            if plan.clearDuplicate.contains(event.id) { event.duplicateOf = nil }
            if plan.removeGaps.contains(event.id) { event.deletedAt = now }
            return event
        }
        result += plan.addGaps
        return result
    }

    func testHingeAndShortcutForSameFoldAreMergedKeepingHinge() {
        let hinge = e(.fold, .hinge, "2026-11-09T10:00:00Z")
        let shortcut = e(.fold, .shortcut, "2026-11-09T10:00:04Z")
        let plan = Reconciler.plan(for: [hinge, shortcut], now: now)
        XCTAssertEqual(plan.markDuplicate, [shortcut.id: hinge.id])
        XCTAssertTrue(plan.addGaps.isEmpty)
    }

    func testShortcutArrivingBeforeHingeIsStillMergedIntoHinge() {
        // The automation can run before the debounced hinge event is committed.
        let shortcut = e(.fold, .shortcut, "2026-11-09T10:00:00Z")
        let hinge = FoldEvent(type: .fold, source: .hinge, timestamp: shortcut.timestamp.addingTimeInterval(0.3), timeZone: Fixture.london)
        let plan = Reconciler.plan(for: [shortcut, hinge], now: now)
        XCTAssertEqual(plan.markDuplicate, [shortcut.id: hinge.id], "either order; hinge wins")
    }

    func testEventsFurtherApartThanTenSecondsAreNotMergedAndLeaveAGap() {
        let first = e(.fold, .hinge, "2026-11-09T10:00:00Z")
        let second = e(.fold, .shortcut, "2026-11-09T10:00:11Z")
        let plan = Reconciler.plan(for: [first, second], now: now)
        XCTAssertTrue(plan.markDuplicate.isEmpty)
        XCTAssertEqual(plan.addGaps.count, 1)
        let gap = plan.addGaps[0]
        XCTAssertEqual(gap.type, .unfold)
        XCTAssertEqual(gap.source, .inferred)
        XCTAssertEqual(gap.inferredIntervalStart, first.timestamp)
        XCTAssertEqual(gap.inferredIntervalEnd, second.timestamp)
    }

    func testOppositeEventInBetweenPreventsMerging() {
        let fold1 = e(.fold, .hinge, "2026-11-09T10:00:00Z")
        let unfold = e(.unfold, .hinge, "2026-11-09T10:00:03Z")
        let fold2 = e(.fold, .shortcut, "2026-11-09T10:00:06Z")
        let plan = Reconciler.plan(for: [fold1, unfold, fold2], now: now)
        XCTAssertTrue(plan.markDuplicate.isEmpty, "a quick close-open-close is three real events")
        XCTAssertTrue(plan.addGaps.isEmpty)
    }

    func testManualTapRightAfterAutomaticFoldIsNotDoubleCounted() {
        let hinge = e(.fold, .hinge, "2026-11-09T10:00:00Z")
        let manual = e(.fold, .manual, "2026-11-09T10:00:07Z")
        let plan = Reconciler.plan(for: [hinge, manual], now: now)
        XCTAssertEqual(plan.markDuplicate, [manual.id: hinge.id])
    }

    func testSameSourceRepeatWithinOneSecondIsADuplicate() {
        let a = e(.fold, .shortcut, "2026-11-09T10:00:00Z")
        let b = FoldEvent(type: .fold, source: .shortcut, timestamp: a.timestamp.addingTimeInterval(0.5), timeZone: Fixture.london)
        XCTAssertEqual(Reconciler.plan(for: [a, b], now: now).markDuplicate, [b.id: a.id])
    }

    func testPairingIsOneToOnePerSource() {
        let hinge = e(.fold, .hinge, "2026-11-09T10:00:00Z")
        let s1 = e(.fold, .shortcut, "2026-11-09T10:00:02Z")
        let s2 = e(.fold, .shortcut, "2026-11-09T10:00:05Z")
        let plan = Reconciler.plan(for: [hinge, s1, s2], now: now)
        XCTAssertEqual(plan.markDuplicate, [s1.id: hinge.id])
        XCTAssertEqual(plan.addGaps.count, 1, "the second shortcut fold is a separate (suspicious) fold → gap")
    }

    func testPlanIsIdempotent() {
        let events = [e(.fold, .hinge, "2026-11-09T10:00:00Z"), e(.fold, .shortcut, "2026-11-09T10:00:03Z"),
                      e(.fold, .manual, "2026-11-09T11:00:00Z"), e(.unfold, .hinge, "2026-11-09T12:00:00Z")]
        let first = Reconciler.plan(for: events, now: now)
        XCTAssertFalse(first.isEmpty)
        let applied = apply(first, to: events)
        XCTAssertEqual(Reconciler.plan(for: applied, now: now), ReconcilePlan(), "second run changes nothing")
    }

    func testDeletingTheKeptEventRestoresTheDuplicate() {
        let hinge = e(.fold, .hinge, "2026-11-09T10:00:00Z")
        var shortcut = e(.fold, .shortcut, "2026-11-09T10:00:03Z")
        shortcut.duplicateOf = hinge.id
        var deletedHinge = hinge
        deletedHinge.deletedAt = now
        let plan = Reconciler.plan(for: [deletedHinge, shortcut], now: now)
        XCTAssertEqual(plan.clearDuplicate, [shortcut.id])
    }

    func testGapIsRemovedWhenTheMissingEventIsAddedLater() {
        let f1 = e(.fold, .hinge, "2026-11-09T10:00:00Z")
        let f2 = e(.fold, .hinge, "2026-11-09T11:00:00Z")
        let withGap = apply(Reconciler.plan(for: [f1, f2], now: now), to: [f1, f2])
        let gap = try! XCTUnwrap(withGap.first { $0.source == .inferred })
        // The user records the missed unfold by hand.
        let manualUnfold = e(.unfold, .manual, "2026-11-09T10:30:00Z")
        let plan = Reconciler.plan(for: withGap + [manualUnfold], now: now)
        XCTAssertEqual(plan.removeGaps, [gap.id])
        XCTAssertTrue(plan.addGaps.isEmpty)
    }

    func testGapIsBucketedOnTheLaterEventsDay() {
        let f1 = e(.fold, .hinge, "2026-11-08T23:00:00Z")
        let f2 = e(.fold, .hinge, "2026-11-09T08:00:00Z")
        let gap = Reconciler.plan(for: [f1, f2], now: now).addGaps.first
        XCTAssertEqual(gap?.localDay, LocalDay(year: 2026, month: 11, day: 9))
    }
}
