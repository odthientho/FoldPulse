import XCTest
import FoldPulseCore
@testable import FoldPulse

/// Regression tests for the Phase 4 agent-review findings.
@MainActor
final class ReviewFixPhase4Tests: XCTestCase {
    private var suite: String!

    private func makeServices(startupError: String? = nil) throws -> AppServices {
        suite = "p4-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        return AppServices(container: try PersistenceController.makeContainer(inMemory: true),
                           snapshots: SnapshotService(url: nil, defaults: defaults, reloadWidgets: {}),
                           settings: AppSettings(defaults: defaults), startupError: startupError)
    }

    override func tearDown() async throws {
        if let suite { UserDefaults().removePersistentDomain(forName: suite) }
    }

    func testShortcutFailsVisiblyWhenTheStoreIsUnavailable() async throws {
        let services = try makeServices(startupError: "disk full")
        do {
            _ = try await services.record(.fold, source: .shortcut, at: .now, appIsActive: false)
            XCTFail("must throw rather than record into the temporary store")
        } catch is AppServices.StoreUnavailableError {
            XCTAssertNil(services.settings.lastShortcutFold, "a lost run must not count toward the self-test")
        }
    }

    func testSelfTestPassesOnlyWhenBothAutomationsRanInTime() throws {
        let model = AppModel(services: try makeServices())
        model.startSelfTest()
        let started = try XCTUnwrap(model.settings.selfTestStartedAt)
        XCTAssertEqual(model.selfTestState, .waiting(since: started))
        model.settings.lastShortcutFold = started.addingTimeInterval(5)
        model.checkSelfTest()
        XCTAssertEqual(model.selfTestState, .waiting(since: started), "the unfold hasn't run yet")
        model.settings.lastShortcutUnfold = started.addingTimeInterval(9)
        model.checkSelfTest(now: started.addingTimeInterval(10))
        XCTAssertEqual(model.selfTestState, .passed(started.addingTimeInterval(10)))
        XCTAssertTrue(model.backgroundCountingVerified)
    }

    func testSelfTestFailureNamesTheMissingAutomation() throws {
        let model = AppModel(services: try makeServices())
        model.settings.selfTestStartedAt = Date.now.addingTimeInterval(-120) // window elapsed
        model.settings.lastShortcutFold = Date.now.addingTimeInterval(-110)
        guard case .failed(let reason) = model.selfTestState else { return XCTFail("expected failure") }
        XCTAssertTrue(reason.contains("Opened"), reason)
    }

    func testDeleteClearsTheNoteAndExportOmitsDeletedEvents() async throws {
        let services = try makeServices()
        let event = FoldEvent(type: .fold, source: .manual, timestamp: .now.addingTimeInterval(-60), note: "private")
        try await services.store.add(event)
        try await services.store.delete(id: event.id, now: .now)
        let all = try await services.store.allEvents(includeDeleted: true)
        XCTAssertNil(all.first?.note)
        let exported = try await services.store.exportEvents()
        XCTAssertTrue(exported.isEmpty)
    }

    func testExportFileIsCreatedAndRemovedAndResetClearsEverything() async throws {
        let services = try makeServices()
        let model = AppModel(services: services)
        await model.record(.fold, source: .manual)
        let url = try await model.makeExportFile(.csv)
        let csv = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(csv.hasPrefix(Exporter.csvHeader))
        XCTAssertEqual(csv.split(separator: "\n").count, 2)
        AppModel.removeExports()
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))

        _ = try await model.makeExportFile(.json)
        await model.resetAllData()
        XCTAssertEqual(model.dashboard.snapshot.totalSinceInstall, 0)
        XCTAssertFalse(FileManager.default.fileExists(atPath: AppModel.exportDirectory.path))
        XCTAssertNil(model.settings.pendingMilestone)
    }
}
