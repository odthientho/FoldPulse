import Foundation

/// The small JSON document the app writes to the App Group for widgets
/// (WIDGET_DESIGN §2). Widgets never open the database.
public struct WidgetSnapshot: Codable, Sendable, Equatable {
    public static let currentSchemaVersion = 1
    /// After this long, widgets show "as of HH:mm".
    public static let staleAfter: TimeInterval = 15 * 60
    public static let fileName = "WidgetSnapshot.json"

    public var schemaVersion: Int
    public var generatedAt: Date
    /// The local day the "today" values refer to.
    public var localDay: LocalDay
    public var todayFolds: Int
    public var todayUnfolds: Int
    public var totalSinceInstall: Int
    /// Rounded average over the last 7 full days; nil before the first full day.
    public var dailyAverage7d: Int?
    public var nextMilestone: Int?

    public init(schemaVersion: Int = WidgetSnapshot.currentSchemaVersion, generatedAt: Date, localDay: LocalDay,
                todayFolds: Int, todayUnfolds: Int, totalSinceInstall: Int, dailyAverage7d: Int?, nextMilestone: Int?) {
        self.schemaVersion = schemaVersion
        self.generatedAt = generatedAt
        self.localDay = localDay
        self.todayFolds = todayFolds
        self.todayUnfolds = todayUnfolds
        self.totalSinceInstall = totalSinceInstall
        self.dailyAverage7d = dailyAverage7d
        self.nextMilestone = nextMilestone
    }

    /// Placeholder before any data exists.
    public static func empty(now: Date, timeZone: TimeZone) -> WidgetSnapshot {
        WidgetSnapshot(generatedAt: now, localDay: LocalDay(date: now, timeZone: timeZone), todayFolds: 0,
                       todayUnfolds: 0, totalSinceInstall: 0, dailyAverage7d: nil, nextMilestone: Milestones.next(after: 0))
    }

    /// Builds a snapshot from the event log.
    public static func make(from events: [FoldEvent], now: Date, timeZone: TimeZone, includeInferred: Bool = false) -> WidgetSnapshot {
        let today = LocalDay(date: now, timeZone: timeZone)
        let todays = events.filter { $0.localDay == today }
        let total = Statistics.total(events, type: .fold, includeInferred: includeInferred)
        let average = Statistics.dailyAverage(events, today: today, includeInferred: includeInferred)
        return WidgetSnapshot(
            generatedAt: now,
            localDay: today,
            todayFolds: Statistics.total(todays, type: .fold, includeInferred: includeInferred),
            todayUnfolds: Statistics.total(todays, type: .unfold, includeInferred: includeInferred),
            totalSinceInstall: total,
            dailyAverage7d: average.map { Int($0.rounded()) },
            nextMilestone: Milestones.next(after: total)
        )
    }

    /// What a widget should show at `date`.
    public struct Display: Equatable, Sendable {
        /// Today's folds, or nil after midnight until the app refreshes ("—").
        public let todayFolds: Int?
        public let totalSinceInstall: Int
        /// True when the data is older than `staleAfter` (show "as of").
        public let isStale: Bool
        public let generatedAt: Date
    }

    /// Applies the midnight and freshness rules (WIDGET_DESIGN §2).
    public func display(at date: Date, timeZone: TimeZone) -> Display {
        let sameDay = LocalDay(date: date, timeZone: timeZone) == localDay
        return Display(todayFolds: sameDay ? todayFolds : nil,
                       totalSinceInstall: totalSinceInstall,
                       isStale: date.timeIntervalSince(generatedAt) > WidgetSnapshot.staleAfter,
                       generatedAt: generatedAt)
    }

    /// The next local midnight after `date` — widgets add a timeline entry there.
    public static func nextMidnight(after date: Date, timeZone: TimeZone) -> Date {
        LocalDay(date: date, timeZone: timeZone).adding(days: 1).start(in: timeZone)
    }

    // MARK: Coding

    public static func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }

    public static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }

    public func encoded() throws -> Data { try WidgetSnapshot.encoder().encode(self) }

    /// Decodes a snapshot; returns nil for unreadable data or a newer schema.
    public static func decode(_ data: Data) -> WidgetSnapshot? {
        guard let snapshot = try? decoder().decode(WidgetSnapshot.self, from: data),
              snapshot.schemaVersion <= currentSchemaVersion else { return nil }
        return snapshot
    }
}
