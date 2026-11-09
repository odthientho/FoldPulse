// FoldProbe — throwaway diagnostic app for the FoldPulse Phase 1b device spike.
// NOT production code. Logs raw hinge callbacks, scene changes and Shortcuts
// automation runs to a local JSON-lines file. No networking of any kind.
import SwiftUI

@main
struct FoldProbeApp: App {
    init() {
        ProbeLog.shared.append(kind: "launch", detail: "process start")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
