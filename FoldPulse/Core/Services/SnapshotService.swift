import Foundation
import WidgetKit
import FoldPulseCore

/// Writes the widget snapshot after data changes and asks WidgetKit to reload.
///
/// Reload policy (WIDGET_DESIGN §2): reloads are free while the app is in the
/// foreground; from the background they are budgeted (~40–70/day), so they are
/// coalesced to at most one per 5 minutes.
@MainActor
final class SnapshotService {
    static let widgetKind = "TodayWidget"
    static let backgroundReloadInterval: TimeInterval = 5 * 60

    private let url: URL
    private let reloadWidgets: @MainActor () -> Void
    private(set) var lastBackgroundReload: Date?

    init(url: URL = SnapshotFile.defaultURL,
         reloadWidgets: @escaping @MainActor () -> Void = { WidgetCenter.shared.reloadTimelines(ofKind: SnapshotService.widgetKind) }) {
        self.url = url
        self.reloadWidgets = reloadWidgets
    }

    /// Recomputes the snapshot from `events`, writes it, and reloads widgets per policy.
    /// Returns whether a widget reload was requested.
    @discardableResult
    func publish(events: [FoldEvent], now: Date = .now, timeZone: TimeZone = .current, appIsActive: Bool) throws -> Bool {
        let snapshot = WidgetSnapshot.make(from: events, now: now, timeZone: timeZone)
        try SnapshotFile.write(snapshot, to: url)
        if appIsActive {
            reloadWidgets()
            return true
        }
        if let last = lastBackgroundReload, now.timeIntervalSince(last) < Self.backgroundReloadInterval {
            return false
        }
        lastBackgroundReload = now
        reloadWidgets()
        return true
    }
}
