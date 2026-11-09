import XCTest
import FoldPulseCore
@testable import FoldPulse

@MainActor
final class SnapshotServiceTests: XCTestCase {
    private var url: URL!

    override func setUp() async throws {
        url = FileManager.default.temporaryDirectory.appendingPathComponent("snapshot-\(UUID().uuidString).json")
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: url)
    }

    func testPublishWritesReadableSnapshot() throws {
        var reloads = 0
        let service = SnapshotService(url: url, reloadWidgets: { reloads += 1 })
        let now = Date(timeIntervalSince1970: 1_794_200_000)
        let events = [FoldEvent(type: .fold, source: .hinge, timestamp: now.addingTimeInterval(-60), timeZone: .current)]
        try service.publish(events: events, now: now, timeZone: .current, appIsActive: true)
        let snapshot = try XCTUnwrap(SnapshotFile.read(from: url))
        XCTAssertEqual(snapshot.totalSinceInstall, 1)
        XCTAssertEqual(snapshot.todayFolds, 1)
        XCTAssertEqual(reloads, 1)
    }

    func testBackgroundReloadsAreCoalescedToFiveMinutes() throws {
        var reloads = 0
        let service = SnapshotService(url: url, reloadWidgets: { reloads += 1 })
        let t0 = Date(timeIntervalSince1970: 1_794_200_000)
        XCTAssertTrue(try service.publish(events: [], now: t0, appIsActive: false))
        XCTAssertFalse(try service.publish(events: [], now: t0.addingTimeInterval(60), appIsActive: false))
        XCTAssertTrue(try service.publish(events: [], now: t0.addingTimeInterval(301), appIsActive: false))
        XCTAssertTrue(try service.publish(events: [], now: t0.addingTimeInterval(320), appIsActive: true), "foreground is never throttled")
        XCTAssertEqual(reloads, 3)
    }
}
