import Foundation
import SwiftData
import FoldPulseCore

/// Shared services for the UI and for background App Intents (which run in the
/// app process, possibly without any UI). One store, one writer.
@MainActor
final class AppServices {
    static let shared = AppServices.makeDefault()

    /// App Group defaults, shared with `@AppStorage` in views.
    nonisolated(unsafe) static let sharedDefaults: UserDefaults = {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-ui-testing") {
            let name = "ui-testing"
            UserDefaults().removePersistentDomain(forName: name)
            return UserDefaults(suiteName: name) ?? .standard
        }
        #endif
        return UserDefaults(suiteName: AppGroup.identifier) ?? .standard
    }()

    let snapshots: SnapshotService
    let settings: AppSettings
    let isUITesting: Bool
    /// Set when the persistent store couldn't be opened; the UI shows it.
    let startupError: String?
    private let storeTask: Task<EventStore, Never>

    init(container: ModelContainer, snapshots: SnapshotService, settings: AppSettings,
         isUITesting: Bool = false, startupError: String? = nil) {
        // Created off the main thread so its context work stays off it (Phase 3 review).
        storeTask = Task.detached { EventStore(modelContainer: container) }
        self.snapshots = snapshots
        self.settings = settings
        self.isUITesting = isUITesting
        self.startupError = startupError
    }

    var store: EventStore {
        get async { await storeTask.value }
    }

    /// The outcome of recording one event.
    struct RecordOutcome: Sendable {
        let event: FoldEvent
        let state: LoadedState
        let newMilestones: [Int]
    }

    /// Records an event from any source: stores it, reconciles duplicates and gaps,
    /// refreshes the widget snapshot and claims milestones.
    func record(_ type: EventType, source: DetectionSource, at time: Date, appIsActive: Bool) async throws -> RecordOutcome {
        let event = FoldEvent(type: type, source: source, timestamp: time, timeZone: .current)
        let state = try await store.record(event, now: .now, timeZone: .current)
        try snapshots.publish(state.dashboard.snapshot, appIsActive: appIsActive)
        if source == .shortcut {
            if type == .fold { settings.lastShortcutFold = time } else { settings.lastShortcutUnfold = time }
        }
        let milestones = settings.claimMilestones(total: state.dashboard.snapshot.totalSinceInstall)
        return RecordOutcome(event: event, state: state, newMilestones: milestones)
    }

    private static func makeDefault() -> AppServices {
        #if DEBUG
        let uiTesting = ProcessInfo.processInfo.arguments.contains("-ui-testing")
        #else
        let uiTesting = false
        #endif
        let settings = AppSettings(defaults: sharedDefaults)
        // UI tests must never touch the real widget snapshot or reload widgets.
        let snapshots = uiTesting
            ? SnapshotService(url: FileManager.default.temporaryDirectory.appendingPathComponent("ui-test-snapshot.json"),
                              defaults: nil, reloadWidgets: {})
            : SnapshotService()
        do {
            let container = try PersistenceController.makeContainer(inMemory: uiTesting)
            return AppServices(container: container, snapshots: snapshots, settings: settings, isUITesting: uiTesting)
        } catch {
            // Keep the process alive (e.g. for an intent) with an empty in-memory store; the UI shows the error.
            let fallback = try! PersistenceController.makeContainer(inMemory: true)
            return AppServices(container: fallback, snapshots: SnapshotService(url: nil, defaults: nil, reloadWidgets: {}),
                               settings: settings, isUITesting: uiTesting, startupError: String(describing: error))
        }
    }
}
