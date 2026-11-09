import SwiftUI

struct ContentView: View {
    static let conditions = [
        "A-foreground-300",
        "B-foreground-automation-50",
        "C-background-unlocked-100",
        "D-locked-300",
        "E-locked-lowpower-100",
        "F-rotation-only",
        "G-slow-and-bounce-50",
        "free-play",
    ]

    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(ProbeLog.conditionKey) private var condition = "free-play"
    @State private var statusText = "waiting…"
    @State private var angleText = "–"
    @State private var callbacks = 0
    @State private var windowSize: CGSize = .zero
    @State private var recent: [String] = []
    @State private var confirmReset = false

    var body: some View {
        NavigationStack {
            List {
                Section("Live hinge (onHingeChange)") {
                    LabeledContent("Status", value: statusText)
                    LabeledContent("Angle", value: angleText)
                    LabeledContent("Callbacks", value: "\(callbacks)")
                    LabeledContent("Window", value: "\(Int(windowSize.width)) × \(Int(windowSize.height)) pt")
                }
                Section("Test run") {
                    Picker("Condition", selection: $condition) {
                        ForEach(Self.conditions, id: \.self) { Text($0).tag($0) }
                    }
                    Button("Mark START of run") { mark("start") }
                    Button("Mark END of run") { mark("end") }
                }
                Section("Log file") {
                    ShareLink(item: ProbeLog.shared.fileURL) {
                        Label("Share log file", systemImage: "square.and.arrow.up")
                    }
                    Button("Refresh preview") { refresh() }
                    Button("Clear log…", role: .destructive) { confirmReset = true }
                    if let error = ProbeLog.shared.lastError {
                        Text("Last write error: \(error)").foregroundStyle(.red).font(.caption)
                    }
                }
                Section("Last 30 lines") {
                    ForEach(Array(recent.enumerated().reversed()), id: \.offset) { _, line in
                        Text(line).font(.caption2.monospaced()).lineLimit(3)
                    }
                }
            }
            .navigationTitle("FoldProbe")
        }
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear { windowSize = geo.size }
                    .onChange(of: geo.size) { _, newSize in
                        windowSize = newSize
                        ProbeLog.shared.append(kind: "size", detail: "\(Int(newSize.width))x\(Int(newSize.height))")
                    }
            }
        )
        // Raw hinge callbacks: no debouncing here — analysis happens offline.
        .onHingeChange { _, newContext in
            callbacks += 1
            if let hinge = newContext.hinge {
                let name = Self.name(of: hinge.status)
                let degrees = hinge.angle.degrees
                statusText = name
                angleText = String(format: "%.1f°", degrees)
                ProbeLog.shared.append(kind: "hinge", status: name, angleDeg: degrees)
            } else {
                statusText = "nil"
                angleText = "–"
                ProbeLog.shared.append(kind: "hinge", status: "nil")
            }
        }
        .onChange(of: scenePhase) { _, phase in
            ProbeLog.shared.append(kind: "scene", detail: String(describing: phase))
        }
        .onAppear { refresh() }
        .confirmationDialog("Delete the whole log file?", isPresented: $confirmReset) {
            Button("Delete log", role: .destructive) { ProbeLog.shared.reset(); refresh() }
        }
    }

    private func mark(_ edge: String) {
        ProbeLog.shared.append(kind: "note", detail: "\(edge) \(condition)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { refresh() }
    }

    private func refresh() {
        recent = ProbeLog.shared.tail(30)
    }

    static func name(of status: DeviceHinge.Status) -> String {
        if status == .closed { return "closed" }
        if status == .partiallyOpen { return "partiallyOpen" }
        if status == .fullyOpen { return "fullyOpen" }
        return "other(\(String(describing: status)))"
    }
}
