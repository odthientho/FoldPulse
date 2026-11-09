import AppIntents
import FoldPulseCore

/// "Record Fold" — for the Shortcuts "Opened or Closed" automation (Closed).
/// Runs in the background without opening the app (F2).
struct RecordFoldIntent: AppIntent {
    static var title: LocalizedStringResource { "Record Fold" }
    static var description: IntentDescription {
        IntentDescription("Records a fold in FoldPulse. Use it with the “Opened or Closed” automation, set to Closed.")
    }
    static var supportedModes: IntentModes { .background }

    func perform() async throws -> some IntentResult {
        try await ShortcutRecorder.record(.fold)
        return .result()
    }
}

/// "Record Unfold" — for the Shortcuts "Opened or Closed" automation (Opened).
struct RecordUnfoldIntent: AppIntent {
    static var title: LocalizedStringResource { "Record Unfold" }
    static var description: IntentDescription {
        IntentDescription("Records an unfold in FoldPulse. Use it with the “Opened or Closed” automation, set to Opened.")
    }
    static var supportedModes: IntentModes { .background }

    func perform() async throws -> some IntentResult {
        try await ShortcutRecorder.record(.unfold)
        return .result()
    }
}

/// Makes the actions easy to find in Shortcuts and Siri.
struct FoldPulseShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: RecordFoldIntent(), phrases: ["Record a fold in \(.applicationName)"],
                    shortTitle: "Record Fold", systemImageName: "arrow.down.right.and.arrow.up.left")
        AppShortcut(intent: RecordUnfoldIntent(), phrases: ["Record an unfold in \(.applicationName)"],
                    shortTitle: "Record Unfold", systemImageName: "arrow.up.left.and.arrow.down.right")
    }
}

@MainActor
enum ShortcutRecorder {
    static func record(_ type: EventType) async throws {
        let services = AppServices.shared
        let outcome = try await services.record(type, source: .shortcut, at: .now, appIsActive: false)
        if services.settings.milestoneNotificationsEnabled, let milestone = outcome.newMilestones.max() {
            await MilestoneNotifier.notify(milestone: milestone)
        }
    }
}
