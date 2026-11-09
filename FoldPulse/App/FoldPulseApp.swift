import SwiftUI
import SwiftData

@main
struct FoldPulseApp: App {
    @State private var model: AppModel?
    @State private var startupError: String?
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // UI tests run against a fresh in-memory store.
        let inMemory = ProcessInfo.processInfo.arguments.contains("-ui-testing")
        do {
            let container = try PersistenceController.makeContainer(inMemory: inMemory)
            _model = State(initialValue: AppModel(container: container))
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
                } else {
                    ContentUnavailableView("FoldPulse couldn't open its data",
                                           systemImage: "exclamationmark.triangle",
                                           description: Text(startupError ?? "Unknown error"))
                }
            }
            .tint(FPColor.accent)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active, let model { Task { await model.reload() } }
        }
    }
}
