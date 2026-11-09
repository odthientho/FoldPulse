import XCTest
@testable import FoldPulseCore

final class WidgetSnapshotTests: XCTestCase {
    private let now = Fixture.date("2026-11-09T14:04:00Z")

    func testMakeComputesTodayTotalsAverageAndMilestone() {
        let events = [
            Fixture.event(.fold, .hinge, at: "2026-11-08T09:00:00Z"),
            Fixture.event(.unfold, .hinge, at: "2026-11-08T09:05:00Z"),
            Fixture.event(.fold, .shortcut, at: "2026-11-09T08:00:00Z"),
            Fixture.event(.unfold, .shortcut, at: "2026-11-09T08:30:00Z"),
            Fixture.event(.fold, .manual, at: "2026-11-09T13:00:00Z"),
            Fixture.event(.fold, .inferred, at: "2026-11-09T12:00:00Z"),
        ]
        let snapshot = WidgetSnapshot.make(from: events, now: now, timeZone: Fixture.london)
        XCTAssertEqual(snapshot.localDay, LocalDay(year: 2026, month: 11, day: 9))
        XCTAssertEqual(snapshot.todayFolds, 2)
        XCTAssertEqual(snapshot.todayUnfolds, 1)
        XCTAssertEqual(snapshot.totalSinceInstall, 3)
        XCTAssertEqual(snapshot.dailyAverage7d, 1)
        XCTAssertEqual(snapshot.nextMilestone, 100)
    }

    func testRoundTripEncoding() throws {
        let snapshot = WidgetSnapshot.make(from: [Fixture.event(at: "2026-11-09T10:00:00Z")], now: now, timeZone: Fixture.london)
        let data = try snapshot.encoded()
        XCTAssertEqual(WidgetSnapshot.decode(data), snapshot)
    }

    func testRejectsGarbageAndNewerSchema() throws {
        XCTAssertNil(WidgetSnapshot.decode(Data("not json".utf8)))
        var future = WidgetSnapshot.empty(now: now, timeZone: Fixture.london)
        future.schemaVersion = WidgetSnapshot.currentSchemaVersion + 1
        XCTAssertNil(WidgetSnapshot.decode(try future.encoded()))
    }

    func testMidnightRuleAndStaleness() {
        let snapshot = WidgetSnapshot.make(from: [Fixture.event(at: "2026-11-09T10:00:00Z")], now: now, timeZone: Fixture.london)
        let fresh = snapshot.display(at: now.addingTimeInterval(60), timeZone: Fixture.london)
        XCTAssertEqual(fresh.todayFolds, 1)
        XCTAssertFalse(fresh.isStale)

        let later = snapshot.display(at: now.addingTimeInterval(20 * 60), timeZone: Fixture.london)
        XCTAssertTrue(later.isStale)

        let midnight = WidgetSnapshot.nextMidnight(after: now, timeZone: Fixture.london)
        XCTAssertEqual(midnight, Fixture.date("2026-11-10T00:00:00Z"))
        let afterMidnight = snapshot.display(at: midnight.addingTimeInterval(1), timeZone: Fixture.london)
        XCTAssertNil(afterMidnight.todayFolds, "after midnight 'today' must not show yesterday's count")
        XCTAssertEqual(afterMidnight.totalSinceInstall, 1)
    }
}
