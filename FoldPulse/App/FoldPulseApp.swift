import SwiftUI
import SwiftData

@main
struct FoldPulseApp: App {
    @State private var model: AppModel?
    @State private var startupError: String?
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // UI tests run against a fresh in-memory store (debug builds only).
        #if DEBUG
        let inMemory = ProcessInfo.processInfo.arguments.contains("-ui-testing")
        #else
        let inMemory = false
        #endif
        do {
            let container = try PersistenceController.makeContainer(inMemory: inMemory)
            // UI tests must never touch the real widget snapshot or reload widgets.
            let snapshots = inMemory
                ? SnapshotService(url: FileManager.default.temporaryDirectory.appendingPathComponent("ui-test-snapshot.json"),
                                  defaults: nil, reloadWidgets: {})
                : SnapshotService()
            _model = State(initialValue: AppModel(container: container, snapshots: snapshots))
        } catch {
            _startupError = State(initialValue: String(describing: error))
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if let model {
                    RootView()
                        .environment(model)
                        .task { await model.reload() }
                        // "Today" rolls over at local midnight without waiting for a data change.
                        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
                            Task { await model.reload() }
                        }
                } else {
                    ContentUnavailableView("FoldPulse couldn't open its data",
                                           systemImage: "exclamationmark.triangle",
                                           description: Text(startupError ?? "Unknown error"))
                }
            }
            .tint(FPColor.accent)
        }
        .onChange(of: scenePhase) { old, phase in
            // Launch is handled by `.task`; reload only when returning from the background.
            if old == .background, phase != .background, let model { Task { await model.reload() } }
        }
    }
}
