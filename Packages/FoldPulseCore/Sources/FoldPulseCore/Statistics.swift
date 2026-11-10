import Foundation

/// A day and its count, for charts and "busiest day".
public struct DayCount: Hashable, Sendable {
    public let day: LocalDay
    public let count: Int

    public init(day: LocalDay, count: Int) {
        self.day = day
        self.count = count
    }
}

/// How folds were captured over a period ("Counted for you").
public struct Coverage: Hashable, Sendable {
    public var hinge = 0
    public var shortcut = 0
    public var manual = 0
    /// Inferred fold gaps in the period (never part of `recordedFolds`).
    public var gaps = 0

    public init(hinge: Int = 0, shortcut: Int = 0, manual: Int = 0, gaps: Int = 0) {
        self.hinge = hinge
        self.shortcut = shortcut
        self.manual = manual
        self.gaps = gaps
    }

    /// Folds that were actually recorded (excludes gaps).
    public var recordedFolds: Int { hinge + shortcut + manual }

    /// Share of recorded folds captured without tapping. Nil when nothing was recorded.
    /// Folds missed entirely cannot appear in the denominator — the UI must say
    /// "of recorded folds" (Phase 2 review I-19).
    public var countedForYouShare: Double? {
        recordedFolds == 0 ? nil : Double(hinge + shortcut) / Double(recordedFolds)
    }
}

/// Pure statistics over the event log. All functions are deterministic given
/// their inputs (no clock or time-zone globals), which keeps them testable.
public enum Statistics {
    /// Events that count toward totals.
    public static func counted(_ events: [FoldEvent], includeInferred: Bool = false) -> [FoldEvent] {
        events.filter { $0.isCounted(includeInferred: includeInferred) }
    }

    /// Number of counted events of `type`.
    public static func total(_ events: [FoldEvent], type: EventType = .fold, includeInferred: Bool = false) -> Int {
        events.reduce(0) { $0 + ($1.type == type && $1.isCounted(includeInferred: includeInferred) ? 1 : 0) }
    }

    /// Counted events of `type` per local day (days without events are absent).
    public static func countsByDay(_ events: [FoldEvent], type: EventType = .fold, includeInferred: Bool = false) -> [LocalDay: Int] {
        var result: [LocalDay: Int] = [:]
        for event in events where event.type == type && event.isCounted(includeInferred: includeInferred) {
            result[event.localDay, default: 0] += 1
        }
        return result
    }

    /// Counts for every day in `days`, including zeros, in the given order.
    public static func series(_ events: [FoldEvent], days: [LocalDay], type: EventType = .fold, includeInferred: Bool = false) -> [DayCount] {
        let byDay = countsByDay(events, type: type, includeInferred: includeInferred)
        return days.map { DayCount(day: $0, count: byDay[$0] ?? 0) }
    }

    /// The earliest local day with any live event (the start of tracking).
    public static func firstTrackedDay(_ events: [FoldEvent]) -> LocalDay? {
        events.lazy.filter(\.isLive).map(\.localDay).min()
    }

    /// Average folds per day over the `window` full days before `today`,
    /// counting zero days, and never before the first tracked day.
    /// Returns nil when no full day is available yet.
    public static func dailyAverage(_ events: [FoldEvent], today: LocalDay, window: Int = 7, includeInferred: Bool = false) -> Double? {
        DayTally(events: events, includeInferred: includeInferred).dailyAverage(today: today, window: window)
    }

    /// The day with the most folds among `days` (earliest wins a tie). Nil if all are zero.
    public static func busiestDay(_ events: [FoldEvent], days: [LocalDay], includeInferred: Bool = false) -> DayCount? {
        DayTally(events: events, includeInferred: includeInferred).busiestDay(days)
    }

    /// Fold coverage by source over `days`.
    public static func coverage(_ events: [FoldEvent], days: Set<LocalDay>) -> Coverage {
        var result = Coverage()
        for event in events where event.isLive && event.type == .fold && days.contains(event.localDay) {
            switch event.source {
            case .hinge: result.hinge += 1
            case .shortcut: result.shortcut += 1
            case .manual: result.manual += 1
            case .inferred: result.gaps += 1
            }
        }
        return result
    }
}
