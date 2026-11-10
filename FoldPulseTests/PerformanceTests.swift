import XCTest
import SwiftData
import FoldPulseCore
@testable import FoldPulse

/// PF-01…PF-03, PF-07: store and statistics performance at heavy-user volumes.
/// Timings are printed as "PERF <id> …" lines (collected into TEST_RESULTS.md).
/// Simulator timings on a CI runner are indicative; targets have headroom for that.
@MainActor
final class PerformanceTests: XCTestCase {
    /// A heavy user's year: ~150 folds a day → ~110,000 events (folds + unfolds).
    private func seededStore(events count: Int) async throws -> EventStore {
        try await seeded(events: count).store
    }

    private func seeded(events count: Int) async throws -> (store: EventStore, container: ModelContainer) {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let store = EventStore(modelContainer: container)
        let start = Date.now.addingTimeInterval(-Double(count) * 290)
        let sources: [DetectionSource] = [.hinge, .hinge, .hinge, .shortcut, .shortcut, .manual]
        var batch: [FoldEvent] = []
        batch.reserveCapacity(10_000)
        for i in 0..<count {
            batch.append(FoldEvent(type: i % 2 == 0 ? .unfold : .fold, source: sources[i % sources.count],
                                   timestamp: start.addingTimeInterval(Double(i) * 290)))
            if batch.count == 10_000 {
                try await store.add(contentsOf: batch, checkingDuplicates: false)
                batch.removeAll(keepingCapacity: true)
            }
        }
        if !batch.isEmpty { try await store.add(contentsOf: batch, checkingDuplicates: false) }
        return (store, container)
    }

    /// Median of `runs` timings, in milliseconds.
    private func medianMilliseconds(runs: Int = 5, _ body: () async throws -> Void) async rethrows -> Double {
        var samples: [Double] = []
        for _ in 0..<runs {
            let clock = ContinuousClock()
            let elapsed = try await clock.measure { try await body() }
            samples.append(Double(elapsed.components.seconds) * 1000 + Double(elapsed.components.attoseconds) / 1e15)
        }
        return samples.sorted()[samples.count / 2]
    }

    /// "first" = the first load after launch (a new store builds its day counts);
    /// "median" = later loads (after a fold, a return to the app, midnight).
    func testLoadStateAt50kAnd110kEvents() async throws {
        for count in [50_000, 110_000] {
            let seeded = try await seeded(events: count)
            let fresh = EventStore(modelContainer: seeded.container)
            let first = try await medianMilliseconds(runs: 1) { _ = try await fresh.loadState(now: .now, timeZone: .current) }
            let ms = try await medianMilliseconds { _ = try await fresh.loadState(now: .now, timeZone: .current) }
            print("PERF PF-01 loadState events=\(count) first_ms=\(Int(first)) median_ms=\(Int(ms))")
            XCTAssertLessThan(first, 3_000, "first load too slow at \(count) events")
            XCTAssertLessThan(ms, 1_000, "loadState too slow at \(count) events")
        }
    }

    func testRecordingOneEventWith110kStored() async throws {
        let store = try await seededStore(events: 110_000)
        _ = try await store.loadState(now: .now, timeZone: .current) // the app has loaded once before anyone records
        let ms = try await medianMilliseconds {
            _ = try await store.record(FoldEvent(type: .fold, source: .manual, timestamp: .now), now: .now, timeZone: .current)
        }
        print("PERF PF-02 record+reconcile+loadState events=110000 median_ms=\(Int(ms))")
        let reconcileMs = try await medianMilliseconds { try await store.reconcile(around: [.now], now: .now) }
        let loadMs = try await medianMilliseconds { _ = try await store.loadState(now: .now, timeZone: .current) }
        print("PERF PF-02 parts reconcile_ms=\(Int(reconcileMs)) loadState_ms=\(Int(loadMs))")
        // Device target 300 ms (TEST_PLAN PF-02) is checked in Part B; the shared CI simulator gets 1.5 s.
        XCTAssertLessThan(ms, 1_500)
    }

    func testInsightsSummaryAt110kEvents() async throws {
        let store = try await seededStore(events: 110_000)
        for period in InsightPeriod.allCases {
            let ms = try await medianMilliseconds(runs: 3) { _ = try await store.summary(period, now: .now, timeZone: .current) }
            print("PERF PF-03 summary period=\(period.rawValue) events=110000 median_ms=\(Int(ms))")
            XCTAssertLessThan(ms, 1_000)
        }
    }

    func testHistoryQueryIsCappedAt50kEvents() async throws {
        let store = try await seededStore(events: 50_000)
        var result: [FoldEvent] = []
        let ms = try await medianMilliseconds(runs: 3) { result = try await store.history(since: nil, sources: nil) }
        print("PERF PF-05 history events=50000 returned=\(result.count) median_ms=\(Int(ms))")
        XCTAssertEqual(result.count, EventStore.historyLimit)
        XCTAssertLessThan(ms, 3_000)
    }
}
