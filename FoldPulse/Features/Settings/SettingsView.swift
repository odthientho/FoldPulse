import SwiftUI

/// Settings (SCREEN_SPECIFICATIONS §9; lean v1: no import, no gap toggle).
struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @AppStorage(AppSettings.Key.theme, store: AppServices.sharedDefaults) private var theme = AppTheme.system.rawValue
    @AppStorage(AppSettings.Key.milestoneNotifications, store: AppServices.sharedDefaults) private var notifications = false
    @State private var showingExport = false
    @State private var showingReset = false

    var body: some View {
        NavigationStack {
            List {
                Section("Counting") {
                    // Manual-only devices (no hinge) have nothing to set up (SCREEN_SPECIFICATIONS §12).
                    if model.hasSeenHinge {
                        NavigationLink { SetupView() } label: { BackgroundStatusRow() }
                        NavigationLink("Coverage") { CoverageView() }
                    }
                    Toggle("Milestone notifications", isOn: $notifications)
                        .onChange(of: notifications) { _, enabled in
                            guard enabled else { return }
                            Task { if !(await MilestoneNotifier.requestAuthorization()) { notifications = false } }
                        }
                }
                Section("Appearance") {
                    Picker("Theme", selection: $theme) {
                        ForEach(AppTheme.allCases) { Text($0.label).tag($0.rawValue) }
                    }
                }
                Section("Your data") {
                    Button("Export data") { showingExport = true }
                    Button("Reset all data", role: .destructive) { showingReset = true }
                }
                Section("About") {
                    NavigationLink("Privacy") { PrivacyView() }
                    LabeledContent("Version", value: Bundle.main.shortVersion)
                }
                #if DEBUG
                Section {
                    Button("Insert sample week") { Task { await model.insertSampleData() } }
                } header: {
                    Text("Developer (debug builds only)")
                } footer: {
                    Text("For reviewing the design on a device. Not present in release builds.")
                }
                #endif
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingExport) { ExportSheet() }
            .sheet(isPresented: $showingReset) { ResetSheet() }
        }
    }
}

enum AppTheme: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

/// Export with a privacy note (SCREEN_SPECIFICATIONS §10, PRIVACY_REVIEW P-4).
struct ExportSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var format: AppModel.ExportFormat = .csv
    @State private var file: URL?
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Picker("Format", selection: $format) {
                    ForEach(AppModel.ExportFormat.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                Label {
                    Text("FoldPulse never uploads anything. Fold times can reveal daily routines like sleep, so share the file only with people you trust.")
                } icon: {
                    Image(systemName: "lock")
                }
                .font(.subheadline)
                // The file is written only when asked for, and deleted when this sheet closes.
                if let file {
                    ShareLink(item: file) { Label("Share \(file.lastPathComponent)", systemImage: "square.and.arrow.up") }
                } else {
                    Button("Create export file") {
                        Task {
                            do { file = try await model.makeExportFile(format) } catch { self.error = String(describing: error) }
                        }
                    }
                }
                if let error { Text(error).foregroundStyle(FPColor.destructive) }
            }
            .navigationTitle("Export data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
            .onChange(of: format) { _, _ in
                file = nil
                AppModel.removeExports()
            }
        }
        .presentationDetents([.medium])
        .onDisappear { AppModel.removeExports() }
    }
}

/// Two-step reset: explanation, then type RESET (USER_FLOWS F5).
struct ResetSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var confirmation = ""
    @State private var failed = false

    var body: some View {
        NavigationStack {
            Form {
                Text("This deletes all \(model.dashboard.snapshot.totalSinceInstall.formatted()) folds and their history on this iPhone. It can't be undone. Export first if you want a copy.")
                TextField("Type RESET to confirm", text: $confirmation)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                Button("Delete everything", role: .destructive) {
                    Task { if await model.resetAllData() { dismiss() } else { failed = true } }
                }
                .disabled(confirmation != "RESET")
                if failed {
                    Text("Nothing was deleted: the data couldn't be erased. Restart FoldPulse and try again.")
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle("Reset all data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
    }
}

/// In-app privacy statement (PRIVACY_REVIEW P-7).
struct PrivacyView: View {
    var body: some View {
        List {
            Text("Your fold history stays on this iPhone. FoldPulse has no account, no servers, no analytics and no ads, and never sends your data anywhere.")
            Text("Your data is included in your own iCloud or computer backups of this iPhone, if you use them. Deleting FoldPulse deletes the data.")
            Text("Exports are created only when you ask, and shared only where you choose.")
            Text("When you delete an event, it's hidden and its note is erased; its time stays on this iPhone so totals stay consistent. Reset all data erases everything.")
        }
        .navigationTitle("Privacy")
    }
}

extension Bundle {
    var shortVersion: String {
        (infoDictionary?["CFBundleShortVersionString"] as? String) ?? "—"
    }
}
