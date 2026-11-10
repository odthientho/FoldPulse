import Foundation

/// Insights periods (SCREEN_SPECIFICATIONS §6).
public enum InsightPeriod: String, CaseIterable, Sendable {
    case day, week, month, year
}

/// One chart bar.
public struct PeriodBucket: Hashable, Sendable {
    public enum Key: Hashable, Sendable {
        case hour(Int)
        case day(LocalDay)
        case month(year: Int, month: Int)
    }

    public let key: Key
    public let count: Int
    /// The bucket containing "now" (highlighted; may be partial).
    public let isCurrent: Bool
}

/// Everything the Insights screen shows for one period.
public struct PeriodSummary: Equatable, Sendable {
    public let period: InsightPeriod
    public let buckets: [PeriodBucket]
    /// Folds in the period, including today so far.
    public let total: Int
    /// Folds in the previous period of the same kind (yesterday, previous 7 days,
    /// previous month, previous year), or nil if tracking hadn't started.
    public let previousTotal: Int?
    /// Busiest day within the period (not for `.day`).
    public let busiestDay: DayCount?
    /// Average folds per *full* day in the period since tracking began; nil if none.
    public let averagePerFullDay: Double?
}

extension Statistics {
    /// Builds the Insights summary for `period` ending at `now`.
    public static func summary(_ events: [FoldEvent], period: InsightPeriod, now: Date, timeZone: TimeZone,
                               includeInferred: Bool = false) -> PeriodSummary {
        summary(tally: DayTally(events: events, includeInferred: includeInferred), recent: events, period: period,
                now: now, timeZone: timeZone, includeInferred: includeInferred)
    }

    /// Builds the Insights summary from a day tally plus today's events
    /// (`recent` may hold more; only today's are used, for the hourly chart).
    public static func summary(tally: DayTally, recent: [FoldEvent], period: InsightPeriod, now: Date, timeZone: TimeZone,
                               includeInferred: Bool = false) -> PeriodSummary {
        let today = LocalDay(date: now, timeZone: timeZone)
        let counted = recent.filter { $0.type == .fold && $0.localDay == today && $0.isCounted(includeInferred: includeInferred) }
        let first = tally.firstTrackedDay
        let byDay = tally.foldsByDay

        func sum(_ days: [LocalDay]) -> Int { days.reduce(0) { $0 + (byDay[$1] ?? 0) } }
        func fullDayAverage(_ days: [LocalDay]) -> Double? {
            guard let first else { return nil }
            let full = days.filter { $0 < today && $0 >= first }
            return full.isEmpty ? nil : Double(sum(full)) / Double(full.count)
        }
        func previous(_ days: [LocalDay]) -> Int? {
            guard let first, let start = days.first, start.adding(days: -1) >= first else { return nil }
            return sum(LocalDay.range(from: start.adding(days: -days.count), through: start.adding(days: -1)))
        }

        switch period {
        case .day:
            var hours = Array(repeating: 0, count: 24)
            var calendar = Calendar(identifier: .gregorian)
            for event in counted {
                calendar.timeZone = event.timeZone
                hours[calendar.component(.hour, from: event.timestamp)] += 1
            }
            var nowCalendar = Calendar(identifier: .gregorian)
            nowCalendar.timeZone = timeZone
            let currentHour = nowCalendar.component(.hour, from: now)
            let yesterday = today.adding(days: -1)
            return PeriodSummary(period: .day,
                                 buckets: hours.enumerated().map { PeriodBucket(key: .hour($0.offset), count: $0.element, isCurrent: $0.offset == currentHour) },
                                 total: byDay[today] ?? 0,
                                 previousTotal: first.map { yesterday >= $0 ? (byDay[yesterday] ?? 0) : nil } ?? nil,
                                 busiestDay: nil, averagePerFullDay: nil)

        case .week, .month:
            let start = period == .week ? today.adding(days: -6) : LocalDay(year: today.year, month: today.month, day: 1)
            let days = LocalDay.range(from: start, through: today)
            let previousTotal: Int?
            if period == .week {
                previousTotal = previous(days)
            } else {
                let lastOfPrevious = start.adding(days: -1)
                let prevStart = LocalDay(year: lastOfPrevious.year, month: lastOfPrevious.month, day: 1)
                previousTotal = (first.map { lastOfPrevious >= $0 } ?? false) ? sum(LocalDay.range(from: prevStart, through: lastOfPrevious)) : nil
            }
            return PeriodSummary(period: period,
                                 buckets: days.map { PeriodBucket(key: .day($0), count: byDay[$0] ?? 0, isCurrent: $0 == today) },
                                 total: sum(days), previousTotal: previousTotal,
                                 busiestDay: tally.busiestDay(days),
                                 averagePerFullDay: fullDayAverage(days))

        case .year:
            var months = Array(repeating: 0, count: today.month)
            for (day, count) in byDay where day.year == today.year && day.month <= today.month {
                months[day.month - 1] += count
            }
            let days = LocalDay.range(from: LocalDay(year: today.year, month: 1, day: 1), through: today)
            let previousYear = byDay.reduce(0) { $0 + ($1.key.year == today.year - 1 ? $1.value : 0) }
            let trackedLastYear = first.map { $0.year < today.year } ?? false
            return PeriodSummary(period: .year,
                                 buckets: months.enumerated().map { PeriodBucket(key: .month(year: today.year, month: $0.offset + 1), count: $0.element, isCurrent: $0.offset + 1 == today.month) },
                                 total: months.reduce(0, +), previousTotal: trackedLastYear ? previousYear : nil,
                                 busiestDay: tally.busiestDay(days),
                                 averagePerFullDay: fullDayAverage(days))
        }
    }
}
