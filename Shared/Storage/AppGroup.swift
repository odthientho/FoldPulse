import Foundation

/// Shared-container locations used by the app and the widget extension.
enum AppGroup {
    static let identifier = "group.io.github.odthientho.foldpulse"

    /// The App Group container, or nil if the group isn't configured.
    ///
    /// Debug builds (simulator/CI, unsigned) fall back to Application Support so the
    /// app can run without signing. Release builds never fall back: data written to a
    /// fallback location would be stranded once the group returns (Phase 3 review).
    static var containerURL: URL? {
        if let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier) {
            return url
        }
        #if DEBUG
        let fallback = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: fallback, withIntermediateDirectories: true)
        return fallback
        #else
        return nil
        #endif
    }

    /// Directory holding the SwiftData store. Created with explicit
    /// `completeUntilFirstUserAuthentication` protection, which new files inherit.
    static var storeDirectory: URL? {
        containerURL?.appendingPathComponent("Store", isDirectory: true)
    }

    static var storeURL: URL? { storeDirectory?.appendingPathComponent("FoldPulse.store") }
}
