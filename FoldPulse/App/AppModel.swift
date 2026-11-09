import Foundation
import Observation
import SwiftData
import FoldPulseCore

/// App-wide state: dashboard numbers and recent events, plus the services that
/// change them. Feature logic (hinge tracking, recording, editing) arrives in Phase 4.
@MainActor
@Observable
final class AppModel {
    private(set) var dashboard: DashboardStats
    private(set) var recentEvents: [FoldEvent] = []
    private(set) var lastError: String?

    /// Created on a background task: a `@ModelActor` initialised on the main
    /// thread can end up doing its database work there (Phase 3 performance review).
    @ObservationIgnored private let storeTask: Task<EventStore, Never>
    @ObservationIgnored private let snapshots: SnapshotService

    init(container: ModelContainer, snapshots: SnapshotService = SnapshotService()) {
        storeTask = Task.detached { EventStore(modelContainer: container) }
        self.snapshots = snapshots
        dashboard = .empty(now: .now, timeZone: .current)
    }

    var store: EventStore {
        get async { await storeTask.value }
    }

    /// Reloads from the store (statistics computed off the main thread) and
    /// refreshes the widget snapshot.
    func reload(appIsActive: Bool = true) async {
        do {
            let state = try await store.loadState(now: .now, timeZone: .current)
            dashboard = state.dashboard
            recentEvents = state.recentEvents
            try snapshots.publish(state.dashboard.snapshot, appIsActive: appIsActive)
            lastError = nil
        } catch {
            lastError = String(describing: error)
        }
    }

    #if DEBUG
    /// Developer-only: inserts the Phase 2 sample week so the UI can be reviewed on device.
    func insertSampleData(now: Date = .now, timeZone: TimeZone = .current) async {
        let today = LocalDay(date: now, timeZone: timeZone)
        let perDay = [58, 77, 69, 81, 74, 73]
        let sources: [DetectionSource] = [.hinge, .hinge, .shortcut, .hinge, .shortcut, .manual]
        var events: [FoldEvent] = []
        for (offset, count) in perDay.enumerated() {
            let start = today.adding(days: offset - perDay.count).start(in: timeZone)
            for i in 0..<count {
                let t = start.addingTimeInterval(7 * 3600 + Double(i) * 600)
                events.append(FoldEvent(type: .unfold, source: sources[i % sources.count], timestamp: t, timeZone: timeZone))
                events.append(FoldEvent(type: .fold, source: sources[(i + 1) % sources.count], timestamp: t.addingTimeInterval(240), timeZone: timeZone))
            }
        }
        do { try await store.add(contentsOf: events) } catch { lastError = String(describing: error) }
        await reload()
    }

    func deleteAllData() async {
        do { try await store.deleteAll() } catch { lastError = String(describing: error) }
        await reload()
    }
    #endif
}
