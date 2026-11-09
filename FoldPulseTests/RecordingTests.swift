import XCTest
import FoldPulseCore
@testable import FoldPulse

/// End-to-end recording through AppServices with an in-memory store.
@MainActor
final class RecordingTests: XCTestCase {
    private var suite: String!

    private func makeServices() throws -> AppServices {
        suite = "rec-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        let snapshotURL = FileManager.default.temporaryDirectory.appendingPathComponent("rec-\(UUID().uuidString).json")
        return AppServices(container: try PersistenceController.makeContainer(inMemory: true),
                           snapshots: SnapshotService(url: snapshotURL, defaults: defaults, reloadWidgets: {}),
                           settings: AppSettings(defaults: defaults))
    }

    override func tearDown() async throws {
        if let suite { UserDefaults().removePersistentDomain(forName: suite) }
    }

    func testHingeAndShortcutForTheSameFoldCountOnce() async throws {
        let services = try makeServices()
        let t = Date.now.addingTimeInterval(-60)
        _ = try await services.record(.fold, source: .hinge, at: t, appIsActive: true)
        let outcome = try await services.record(.fold, source: .shortcut, at: t.addingTimeInterval(3), appIsActive: false)
        XCTAssertEqual(outcome.state.dashboard.snapshot.totalSinceInstall, 1)
        XCTAssertEqual(outcome.state.recentEvents.map(\.source), [.hinge], "the shortcut duplicate is hidden")
        XCTAssertNotNil(services.settings.lastShortcutFold)
    }

    func testMissedUnfoldCreatesAGapThatIsNotCounted() async throws {
        let services = try makeServices()
        let t = Date.now.addingTimeInterval(-3_600)
        _ = try await services.record(.fold, source: .hinge, at: t, appIsActive: true)
        let outcome = try await services.record(.fold, source: .hinge, at: t.addingTimeInterval(600), appIsActive: true)
        XCTAssertEqual(outcome.state.dashboard.snapshot.totalSinceInstall, 2)
        let gaps = outcome.state.recentEvents.filter { $0.source == .inferred }
        XCTAssertEqual(gaps.count, 1)
        XCTAssertEqual(gaps.first?.type, .unfold)
    }

    func testUndoRemovesTheManualEventAndRestoresTotals() async throws {
        let services = try makeServices()
        let model = AppModel(services: services)
        let event = await model.record(.fold, source: .manual)
        XCTAssertEqual(model.dashboard.snapshot.totalSinceInstall, 1)
        XCTAssertEqual(model.lastManualEvent?.id, event?.id)
        await model.undo(try XCTUnwrap(event))
        XCTAssertEqual(model.dashboard.snapshot.totalSinceInstall, 0)
        XCTAssertNil(model.lastManualEvent)
    }

    func testEditingTimeMarksEditedAndMovesTheDay() async throws {
        let services = try makeServices()
        let model = AppModel(services: services)
        var event = try XCTUnwrap(await model.record(.fold, source: .hinge))
        event.setTimestamp(event.timestamp.addingTimeInterval(-2 * 86_400))
        await model.edit(event)
        let stored = try await services.store.allEvents().first { $0.id == event.id }
        XCTAssertEqual(stored?.isEdited, true)
        XCTAssertEqual(stored?.localDay, event.localDay)
        XCTAssertEqual(model.dashboard.snapshot.todayFolds, 0)
    }

    func testFirstMilestoneIsPendingOnceAndNeverReturns() async throws {
        let services = try makeServices()
        let start = Date.now.addingTimeInterval(-200 * 120)
        let events = (0..<99).map { FoldEvent(type: .fold, source: .hinge, timestamp: start.addingTimeInterval(Double($0) * 120)) }
        try await services.store.add(contentsOf: events)
        let model = AppModel(services: services)
        await model.reload()
        XCTAssertNil(model.pendingMilestone, "99 folds: no milestone yet (gaps are not counted)")
        await model.record(.fold, source: .manual)
        XCTAssertEqual(model.pendingMilestone, 100)
        model.dismissMilestone()
        await model.undo(try XCTUnwrap(model.lastManualEvent))
        await model.record(.fold, source: .manual)
        XCTAssertNil(model.pendingMilestone, "a milestone is celebrated once, even after deletions")
    }
}
