import Foundation

/// Everything the Today screen and the widget need, computed in one pass
/// group off the main thread (Phase 3 performance review).
public struct DashboardStats: Sendable, Equatable {
    public var snapshot: WidgetSnapshot
    /// Fold capture by source over the last 7 days including today.
    public var coverage: Coverage
    /// Folds per day for the last 7 days, oldest first, ending today.
    public var lastSevenDays: [DayCount]

    public init(snapshot: WidgetSnapshot, coverage: Coverage, lastSevenDays: [DayCount]) {
        self.snapshot = snapshot
        self.coverage = coverage
        self.lastSevenDays = lastSevenDays
    }

    public static func make(from events: [FoldEvent], now: Date, timeZone: TimeZone, includeInferred: Bool = false) -> DashboardStats {
        let snapshot = WidgetSnapshot.make(from: events, now: now, timeZone: timeZone, includeInferred: includeInferred)
        let week = LocalDay.range(from: snapshot.localDay.adding(days: -6), through: snapshot.localDay)
        return DashboardStats(snapshot: snapshot,
                              coverage: Statistics.coverage(events, days: Set(week)),
                              lastSevenDays: Statistics.series(events, days: week, includeInferred: includeInferred))
    }

    public static func empty(now: Date, timeZone: TimeZone) -> DashboardStats {
        make(from: [], now: now, timeZone: timeZone)
    }
}
