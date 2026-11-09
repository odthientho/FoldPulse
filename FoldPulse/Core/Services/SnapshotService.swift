import Foundation
import WidgetKit
import FoldPulseCore

/// Writes the widget snapshot after data changes and asks WidgetKit to reload.
///
/// Reload policy (WIDGET_DESIGN §2): reloads are free while the app is in the
/// foreground; from the background they are budgeted (~40–70/day), so they are
/// coalesced to at most one per 5 minutes. The last-reload time is kept in the
/// App Group defaults, so the throttle holds across the short-lived processes
/// that run Shortcuts intents. A throttled reload is not lost: the widget's own
/// timeline re-reads the snapshot every 30 minutes (TodayWidget).
@MainActor
final class SnapshotService {
    static let widgetKind = "TodayWidget"
    static let backgroundReloadInterval: TimeInterval = 5 * 60
    static let lastReloadKey = "widget.lastBackgroundReload"

    private let url: URL?
    private let defaults: UserDefaults?
    private let reloadWidgets: @MainActor () -> Void

    init(url: URL? = SnapshotFile.defaultURL,
         defaults: UserDefaults? = UserDefaults(suiteName: AppGroup.identifier),
         reloadWidgets: @escaping @MainActor () -> Void = { WidgetCenter.shared.reloadTimelines(ofKind: SnapshotService.widgetKind) }) {
        self.url = url
        self.defaults = defaults
        self.reloadWidgets = reloadWidgets
    }

    /// Writes `snapshot` and reloads widgets per policy. Returns whether a reload was requested.
    @discardableResult
    func publish(_ snapshot: WidgetSnapshot, now: Date = .now, appIsActive: Bool) throws -> Bool {
        if let url { try SnapshotFile.write(snapshot, to: url) }
        if appIsActive {
            reloadWidgets()
            return true
        }
        if let last = defaults?.object(forKey: Self.lastReloadKey) as? Date,
           now.timeIntervalSince(last) < Self.backgroundReloadInterval {
            return false
        }
        defaults?.set(now, forKey: Self.lastReloadKey)
        reloadWidgets()
        return true
    }
}
