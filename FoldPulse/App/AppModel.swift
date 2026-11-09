import Foundation
import Observation
import SwiftData
import FoldPulseCore

/// App-wide state: the loaded event log plus the services that change it.
/// Feature logic (hinge tracking, recording, editing) arrives in Phase 4.
@MainActor
@Observable
final class AppModel {
    private(set) var events: [FoldEvent] = []
    private(set) var lastError: String?

    let store: EventStore
    private let snapshots: SnapshotService

    init(container: ModelContainer, snapshots: SnapshotService = SnapshotService()) {
        self.store = EventStore(modelContainer: container)
        self.snapshots = snapshots
    }

    /// Reloads events from the store and refreshes the widget snapshot.
    func reload(appIsActive: Bool = true) async {
        do {
            events = try await store.allEvents()
            try snapshots.publish(events: events, appIsActive: appIsActive)
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
        do {
            for (offset, count) in perDay.enumerated() {
                let start = today.adding(days: offset - perDay.count).start(in: timeZone)
                for i in 0..<count {
                    let t = start.addingTimeInterval(7 * 3600 + Double(i) * 600)
                    try await store.add(FoldEvent(type: .unfold, source: sources[i % sources.count], timestamp: t, timeZone: timeZone))
                    try await store.add(FoldEvent(type: .fold, source: sources[(i + 1) % sources.count], timestamp: t.addingTimeInterval(240), timeZone: timeZone))
                }
            }
        } catch {
            lastError = String(describing: error)
        }
        await reload()
    }

    func deleteAllData() async {
        do { try await store.deleteAll() } catch { lastError = String(describing: error) }
        await reload()
    }
    #endif
}
