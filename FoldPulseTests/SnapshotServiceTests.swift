import XCTest
import FoldPulseCore
@testable import FoldPulse

@MainActor
final class SnapshotServiceTests: XCTestCase {
    private var url: URL!
    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() async throws {
        url = FileManager.default.temporaryDirectory.appendingPathComponent("snapshot-\(UUID().uuidString).json")
        suiteName = "test-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: url)
        defaults.removePersistentDomain(forName: suiteName)
    }

    func testPublishWritesReadableSnapshot() throws {
        var reloads = 0
        let service = SnapshotService(url: url, defaults: defaults, reloadWidgets: { reloads += 1 })
        let now = Date(timeIntervalSince1970: 1_794_200_000)
        let events = [FoldEvent(type: .fold, source: .hinge, timestamp: now.addingTimeInterval(-60), timeZone: .current)]
        try service.publish(WidgetSnapshot.make(from: events, now: now, timeZone: .current), now: now, appIsActive: true)
        let snapshot = try XCTUnwrap(SnapshotFile.read(from: url))
        XCTAssertEqual(snapshot.totalSinceInstall, 1)
        XCTAssertEqual(snapshot.todayFolds, 1)
        XCTAssertEqual(reloads, 1)
    }

    func testBackgroundReloadsAreCoalescedAcrossProcesses() throws {
        var reloads = 0
        let t0 = Date(timeIntervalSince1970: 1_794_200_000)
        let empty = WidgetSnapshot.empty(now: t0, timeZone: .current)
        // Two service instances sharing defaults model two short-lived intent processes.
        let first = SnapshotService(url: url, defaults: defaults, reloadWidgets: { reloads += 1 })
        let second = SnapshotService(url: url, defaults: defaults, reloadWidgets: { reloads += 1 })
        XCTAssertTrue(try first.publish(empty, now: t0, appIsActive: false))
        XCTAssertFalse(try second.publish(empty, now: t0.addingTimeInterval(60), appIsActive: false))
        XCTAssertTrue(try second.publish(empty, now: t0.addingTimeInterval(301), appIsActive: false))
        XCTAssertTrue(try first.publish(empty, now: t0.addingTimeInterval(320), appIsActive: true), "foreground is never throttled")
        XCTAssertEqual(reloads, 3)
    }

    func testProtectedDirectoryIsCreated() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("store-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        try PersistenceController.prepareProtectedDirectory(dir)
        var isDirectory: ObjCBool = false
        XCTAssertTrue(FileManager.default.fileExists(atPath: dir.path, isDirectory: &isDirectory))
        XCTAssertTrue(isDirectory.boolValue)
    }
}
