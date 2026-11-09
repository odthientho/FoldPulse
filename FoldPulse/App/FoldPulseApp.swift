import SwiftUI

@main
struct FoldPulseApp: App {
    @State private var model = AppModel(services: AppServices.shared)
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            Group {
                if let error = model.services.startupError {
                    ContentUnavailableView("FoldPulse couldn't open its data",
                                           systemImage: "exclamationmark.triangle", description: Text(error))
                } else {
                    RootView()
                        // Order matters: the hinge modifier reads AppModel from the environment.
                        .hingeTracking()
                        .environment(model)
                        .task { await model.reload() }
                        // "Today" rolls over at local midnight without waiting for a data change.
                        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
                            Task { await model.reload() }
                        }
                }
            }
            .tint(FPColor.accent)
        }
        .onChange(of: scenePhase) { old, phase in
            // Launch is handled by `.task`; reload when returning from the background
            // (background Shortcuts may have recorded events meanwhile).
            if old == .background, phase != .background { Task { await model.reload() } }
        }
    }
}
