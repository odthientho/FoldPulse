import SwiftUI

/// Optional background counting via the Shortcuts "Opened or Closed" automation
/// (SCREEN_SPECIFICATIONS §8). FoldPulse can't see what the user does in Shortcuts,
/// so steps are plain instructions and only the self-test reports a status.
struct SetupView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase

    private var supportsTrigger: Bool {
        ProcessInfo.processInfo.isOperatingSystemAtLeast(OperatingSystemVersion(majorVersion: 27, minorVersion: 2, patchVersion: 0))
    }

    var body: some View {
        let _ = model.selfTestVersion
        List {
            Section {
                Text("Optional. Count folds even when FoldPulse is closed. To stop later, delete the two automations in Shortcuts.")
                    .font(.subheadline).foregroundStyle(FPColor.text2)
                    .listRowBackground(Color.clear)
            }
            if !supportsTrigger {
                Section {
                    Label("The “Opened or Closed” trigger needs iOS 27.2 or later. Update in Settings → General → Software Update. FoldPulse still counts automatically while it's open.",
                          systemImage: "exclamationmark.triangle")
                        .foregroundStyle(FPColor.warning)
                }
            }
            Section("Steps") {
                step(1, "Open Shortcuts → Automation → New Automation.")
                step(2, "Choose the “Opened or Closed” trigger → Closed.")
                step(3, "Choose Run Immediately, then add the action “Record Fold” (FoldPulse).")
                step(4, "Repeat with Opened → “Record Unfold” (FoldPulse).")
                Button("Open Shortcuts") {
                    if let url = URL(string: "shortcuts://") { openURL(url) }
                }
            }
            Section {
                switch model.selfTestState {
                case .notRun:
                    Text("Close your iPhone, wait a moment, then open it. FoldPulse checks that both automations ran — that's the only way it can know.")
                        .font(.subheadline)
                    Button("Start self-test") { model.startSelfTest() }
                case .waiting(let since):
                    Label("Waiting since \(since.formatted(date: .omitted, time: .shortened)): close your iPhone, then open it and come back here.", systemImage: "hourglass")
                    Button("Check now") { model.checkSelfTest() }
                    Button("Start again") { model.startSelfTest() }
                case .passed(let date):
                    Label("Working — passed \(date.formatted(date: .abbreviated, time: .shortened))", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(FPColor.positive)
                    Button("Run self-test again") { model.startSelfTest() }
                }
            } header: {
                Text("Self-test")
            }
            Section("Troubleshooting") {
                Text("Can't find the trigger? Check your iOS version (Settings → General → About).")
                Text("Asked to confirm each time? Edit the automation and choose Run Immediately.")
                Text("Nothing recorded? Make sure the action is FoldPulse's “Record Fold” or “Record Unfold”.")
            }
            .font(.footnote)
            .foregroundStyle(FPColor.text2)
        }
        .navigationTitle("Background counting")
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await model.reload() } }
        }
    }

    private func step(_ number: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: FPSpace.m) {
            Text("\(number)").font(.subheadline.weight(.bold)).frame(width: 24, height: 24)
                .background(FPColor.chip, in: Circle())
            Text(text).font(.subheadline)
        }
        .accessibilityElement(children: .combine)
    }
}
