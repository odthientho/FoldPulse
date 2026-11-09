import AppIntents
import UIKit

/// Called by the Shortcuts automation "When my iPhone is closed".
struct ProbeClosedIntent: AppIntent {
    static let title: LocalizedStringResource = "Probe: Phone Closed"
    static let description = IntentDescription("Logs a 'closed' event for the FoldPulse device test.")
    static let supportedModes: IntentModes = .background

    func perform() async throws -> some IntentResult {
        let unlockedData = await MainActor.run { UIApplication.shared.isProtectedDataAvailable }
        ProbeLog.shared.appendNow(kind: "shortcut", status: "closed",
                                  detail: "protectedData=\(unlockedData)")
        return .result()
    }
}

/// Called by the Shortcuts automation "When my iPhone is opened".
struct ProbeOpenedIntent: AppIntent {
    static let title: LocalizedStringResource = "Probe: Phone Opened"
    static let description = IntentDescription("Logs an 'opened' event for the FoldPulse device test.")
    static let supportedModes: IntentModes = .background

    func perform() async throws -> some IntentResult {
        let unlockedData = await MainActor.run { UIApplication.shared.isProtectedDataAvailable }
        ProbeLog.shared.appendNow(kind: "shortcut", status: "opened",
                                  detail: "protectedData=\(unlockedData)")
        return .result()
    }
}
