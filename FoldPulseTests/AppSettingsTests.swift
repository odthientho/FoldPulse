import XCTest
@testable import FoldPulse

@MainActor
final class AppSettingsTests: XCTestCase {
    func testClaimMilestonesOnceAndKeepTheHighestPending() throws {
        let suite = "settings-\(UUID().uuidString)"
        defer { UserDefaults().removePersistentDomain(forName: suite) }
        let settings = AppSettings(defaults: try XCTUnwrap(UserDefaults(suiteName: suite)))
        XCTAssertEqual(settings.claimMilestones(total: 99), [])
        XCTAssertEqual(settings.claimMilestones(total: 1_200), [100, 500, 1_000])
        XCTAssertEqual(settings.pendingMilestone, 1_000)
        XCTAssertEqual(settings.claimMilestones(total: 1_300), [])
        settings.resetData()
        XCTAssertNil(settings.pendingMilestone)
        XCTAssertEqual(settings.celebratedMilestones, [])
    }
}
