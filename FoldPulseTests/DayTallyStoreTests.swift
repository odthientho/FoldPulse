import XCTest
import SwiftData
import FoldPulseCore
@testable import FoldPulse

/// The store keeps day counts between loads (Phase 5 performance). These tests
/// check that, after every kind of write, its numbers equal the numbers computed
/// from the full event log — including writes far in the past and time moving on.
final class DayTallyStoreTests: XCTestCase {
    private let zone = TimeZone(identifier: "Europe/London")!

    private func assertMatchesFullLog(_ store: EventStore, now: Date, file: StaticString = #filePath, line: UInt = #line) async throws {
        let all = try await store.allEvents()
        let state = try await store.loadState(now: now, timeZone: zone)
        XCTAssertEqual(state.dashboard, DashboardStats.make(from: all, now: now, timeZone: zone), file: file, line: line)
        XCTAssertEqual(state.recentEvents, Array(all.filter(\.isLive).suffix(500).reversed()), file: file, line: line)
        for period in InsightPeriod.allCases {
            let summary = try await store.summary(period, now: now, timeZone: zone)
            XCTAssertEqual(summary, Statistics.summary(all, period: period, now: now, timeZone: zone),
                           "\(period)", file: file, line: line)
        }
    }

    func testKeptCountsStayExactThroughOldAndNewWrites() async throws {
        let store = EventStore(modelContainer: try PersistenceController.makeContainer(inMemory: true))
        let now = Date(timeIntervalSince1970: 1_794_300_000)
        // 40 days of folds/unfolds every ~3 hours, mixed sources.
        let sources: [DetectionSource] = [.hinge, .shortcut, .manual]
        let seed = (0..<320).map { i in
            FoldEvent(type: i % 2 == 0 ? .fold : .unfold, source: sources[i % 3],
                      timestamp: now.addingTimeInterval(-40 * 86_400 + Double(i) * 10_800), timeZone: zone)
        }
        try await store.add(contentsOf: seed)
        try await assertMatchesFullLog(store, now: now) // builds the kept counts

        // Delete a fold from 30 days ago (behind the kept boundary).
        let old = try XCTUnwrap(seed.first { $0.type == .fold && $0.timestamp < now.addingTimeInterval(-29 * 86_400) })
        try await store.delete(id: old.id, now: now)
        try await assertMatchesFullLog(store, now: now)

        // Edit a 20-day-old unfold into a fold and move it to 25 days ago.
        var edited = try XCTUnwrap(seed.first { $0.type == .unfold && $0.timestamp > now.addingTimeInterval(-20 * 86_400) })
        edited.type = .fold
        edited.setTimestamp(now.addingTimeInterval(-25 * 86_400))
        try await store.edit(edited, now: now)
        try await assertMatchesFullLog(store, now: now)

        // A duplicate pair recorded now (hinge + Shortcut within 10 s) counts once.
        _ = try await store.record(FoldEvent(type: .fold, source: .hinge, timestamp: now.addingTimeInterval(-60), timeZone: zone),
                                   now: now, timeZone: zone)
        _ = try await store.record(FoldEvent(type: .fold, source: .shortcut, timestamp: now.addingTimeInterval(-55), timeZone: zone),
                                   now: now, timeZone: zone)
        try await assertMatchesFullLog(store, now: now)

        // Time moves on by 12 days (the kept boundary advances), then an old manual entry.
        let later = now.addingTimeInterval(12 * 86_400)
        try await assertMatchesFullLog(store, now: later)
        _ = try await store.record(FoldEvent(type: .fold, source: .manual, timestamp: now.addingTimeInterval(-35 * 86_400), timeZone: zone),
                                   now: later, timeZone: zone)
        try await assertMatchesFullLog(store, now: later)

        // Reset clears everything.
        try await store.deleteAll()
        try await assertMatchesFullLog(store, now: later)
    }

    /// Travel (several capture zones), the public update/softDelete, and the clock going backwards.
    func testKeptCountsWithTravelUpdatesAndClockChanges() async throws {
        let store = EventStore(modelContainer: try PersistenceController.makeContainer(inMemory: true))
        let now = Date(timeIntervalSince1970: 1_794_300_000)
        let zones = ["Pacific/Kiritimati", "Etc/GMT+12", "Asia/Tokyo", "America/New_York"].compactMap(TimeZone.init(identifier:))
        let seed = (0..<240).map { i in
            FoldEvent(type: i % 2 == 0 ? .fold : .unfold, source: .hinge,
                      timestamp: now.addingTimeInterval(-30 * 86_400 + Double(i) * 10_800), timeZone: zones[(i / 8) % zones.count])
        }
        try await store.add(contentsOf: seed)
        _ = try await store.summary(.year, now: now, timeZone: zone) // builds the kept counts
        try await assertMatchesFullLog(store, now: now)

        // Public update (no reconcile): an old fold becomes an unfold.
        var changed = try XCTUnwrap(seed.first { $0.type == .fold && $0.timestamp < now.addingTimeInterval(-20 * 86_400) })
        changed.type = .unfold
        try await store.update(changed, now: now)
        try await assertMatchesFullLog(store, now: now)

        // Public softDelete of an old fold.
        let old = try XCTUnwrap(seed.last { $0.type == .fold && $0.timestamp < now.addingTimeInterval(-15 * 86_400) })
        try await store.softDelete(id: old.id, now: now)
        try await assertMatchesFullLog(store, now: now)

        // The clock jumps 20 days back, then forward again.
        try await assertMatchesFullLog(store, now: now.addingTimeInterval(-20 * 86_400))
        try await assertMatchesFullLog(store, now: now.addingTimeInterval(3 * 86_400))
    }
}
