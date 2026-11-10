import Foundation

/// Counted folds per local day, plus the first tracked day: everything the
/// long-range statistics need, without holding every event in memory
/// (Phase 5 performance, PF-01…PF-03). The app keeps one up to date in
/// `EventStore`; the event-based functions build one on the fly, so both
/// paths share the same arithmetic.
public struct DayTally: Sendable, Equatable {
    /// Counted folds per local day (days without folds are absent).
    public var foldsByDay: [LocalDay: Int]
    /// The earliest local day with any live event.
    public var firstTrackedDay: LocalDay?

    public init(foldsByDay: [LocalDay: Int], firstTrackedDay: LocalDay?) {
        self.foldsByDay = foldsByDay.filter { $0.value != 0 }
        self.firstTrackedDay = firstTrackedDay
    }

    public init(events: [FoldEvent], includeInferred: Bool = false) {
        self.init(foldsByDay: Statistics.countsByDay(events, type: .fold, includeInferred: includeInferred),
                  firstTrackedDay: Statistics.firstTrackedDay(events))
    }

    /// All counted folds since install.
    public var total: Int { foldsByDay.values.reduce(0, +) }

    public func count(on day: LocalDay) -> Int { foldsByDay[day] ?? 0 }

    public func series(_ days: [LocalDay]) -> [DayCount] {
        days.map { DayCount(day: $0, count: count(on: $0)) }
    }

    /// See `Statistics.dailyAverage`.
    public func dailyAverage(today: LocalDay, window: Int = 7) -> Double? {
        guard window > 0, let first = firstTrackedDay else { return nil }
        let days = LocalDay.range(from: max(today.adding(days: -window), first), through: today.adding(days: -1))
        guard !days.isEmpty else { return nil }
        return Double(series(days).reduce(0) { $0 + $1.count }) / Double(days.count)
    }

    /// See `Statistics.busiestDay`.
    public func busiestDay(_ days: [LocalDay]) -> DayCount? {
        guard let best = series(days).max(by: { ($0.count, $1.day) < ($1.count, $0.day) }), best.count > 0 else { return nil }
        return best
    }
}
