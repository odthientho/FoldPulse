import Foundation

/// Shared-container locations used by the app and the widget extension.
enum AppGroup {
    static let identifier = "group.io.github.odthientho.foldpulse"

    /// The App Group container. Falls back to Application Support when the
    /// group is unavailable (e.g. unsigned simulator builds in CI), so the app
    /// still runs; widgets then simply show the empty state.
    static var containerURL: URL {
        if let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier) {
            return url
        }
        let fallback = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: fallback, withIntermediateDirectories: true)
        return fallback
    }

    /// SwiftData store (event log).
    static var storeURL: URL { containerURL.appendingPathComponent("FoldPulse.store") }
}
