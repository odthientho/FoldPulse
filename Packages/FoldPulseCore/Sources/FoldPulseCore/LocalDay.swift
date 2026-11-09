import Foundation

/// A calendar date (year-month-day) in a specific time zone, without a time.
///
/// Events store the `LocalDay` at capture time, so a fold made at 23:30 in
/// New York stays on that New York day even after travelling (DATA rules in
/// TECHNICAL_FEASIBILITY §6).
public struct LocalDay: Hashable, Comparable, Sendable, CustomStringConvertible {
    public let year: Int
    public let month: Int
    public let day: Int

    public init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    /// The local calendar day of `date` in `timeZone` (Gregorian calendar).
    public init(date: Date, timeZone: TimeZone) {
        let parts = LocalDay.calendar(timeZone).dateComponents([.year, .month, .day], from: date)
        self.init(year: parts.year ?? 1970, month: parts.month ?? 1, day: parts.day ?? 1)
    }

    /// Parses `YYYY-MM-DD`.
    public init?(string: String) {
        let parts = string.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3, (1...12).contains(parts[1]), (1...31).contains(parts[2]) else { return nil }
        self.init(year: parts[0], month: parts[1], day: parts[2])
    }

    public var description: String {
        let y = String(year).leftPadded(to: 4)
        let m = String(month).leftPadded(to: 2)
        let d = String(day).leftPadded(to: 2)
        return "\(y)-\(m)-\(d)"
    }

    public static func < (lhs: LocalDay, rhs: LocalDay) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }

    /// The day `days` later (negative = earlier). Calendar arithmetic is done in
    /// UTC at noon, so daylight-saving transitions can never shift the result.
    public func adding(days: Int) -> LocalDay {
        let utc = TimeZone(identifier: "UTC")!
        let cal = LocalDay.calendar(utc)
        let noon = cal.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
        let shifted = cal.date(byAdding: .day, value: days, to: noon)!
        return LocalDay(date: shifted, timeZone: utc)
    }

    /// Number of days from `self` to `other` (positive when `other` is later).
    public func days(until other: LocalDay) -> Int {
        let utc = TimeZone(identifier: "UTC")!
        let cal = LocalDay.calendar(utc)
        let a = cal.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
        let b = cal.date(from: DateComponents(year: other.year, month: other.month, day: other.day, hour: 12))!
        return cal.dateComponents([.day], from: a, to: b).day ?? 0
    }

    /// All days from `start` through `end` inclusive (empty if `end < start`).
    public static func range(from start: LocalDay, through end: LocalDay) -> [LocalDay] {
        guard start <= end else { return [] }
        return (0...start.days(until: end)).map { start.adding(days: $0) }
    }

    /// The instant this day starts in `timeZone` (handles 23- and 25-hour days).
    public func start(in timeZone: TimeZone) -> Date {
        LocalDay.calendar(timeZone).date(from: DateComponents(year: year, month: month, day: day))!
    }

    static func calendar(_ timeZone: TimeZone) -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        return cal
    }
}

extension LocalDay: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        guard let value = LocalDay(string: raw) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid LocalDay: \(raw)")
        }
        self = value
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}

private extension String {
    func leftPadded(to length: Int) -> String {
        count >= length ? self : String(repeating: "0", count: length - count) + self
    }
}
