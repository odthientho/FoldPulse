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
        make(tally: DayTally(events: events, includeInferred: includeInferred), recent: events, now: now,
             timeZone: timeZone, includeInferred: includeInferred)
    }

    /// Builds the dashboard from a day tally plus every event whose local day is
    /// in the last 7 days (`recent` may hold more; older ones are ignored).
    public static func make(tally: DayTally, recent: [FoldEvent], now: Date, timeZone: TimeZone,
                            includeInferred: Bool = false) -> DashboardStats {
        let snapshot = WidgetSnapshot.make(tally: tally, recent: recent, now: now, timeZone: timeZone, includeInferred: includeInferred)
        let week = LocalDay.range(from: snapshot.localDay.adding(days: -6), through: snapshot.localDay)
        return DashboardStats(snapshot: snapshot,
                              coverage: Statistics.coverage(recent, days: Set(week)),
                              lastSevenDays: tally.series(week))
    }

    public static func empty(now: Date, timeZone: TimeZone) -> DashboardStats {
        make(from: [], now: now, timeZone: timeZone)
    }
}
