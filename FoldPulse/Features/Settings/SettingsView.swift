import SwiftUI

/// Settings shell. Background counting, export and reset arrive in Phase 4.
struct SettingsView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        NavigationStack {
            List {
                Section("About") {
                    LabeledContent("Privacy", value: "Data stays on this iPhone")
                    LabeledContent("Version", value: Bundle.main.shortVersion)
                }
                #if DEBUG
                Section {
                    Button("Insert sample week") { Task { await model.insertSampleData() } }
                    Button("Delete all data", role: .destructive) { Task { await model.deleteAllData() } }
                } header: {
                    Text("Developer (debug builds only)")
                } footer: {
                    Text("For reviewing the design on a device. Not present in release builds.")
                }
                #endif
            }
            .navigationTitle("Settings")
        }
    }
}

extension Bundle {
    var shortVersion: String {
        (infoDictionary?["CFBundleShortVersionString"] as? String) ?? "—"
    }
}
