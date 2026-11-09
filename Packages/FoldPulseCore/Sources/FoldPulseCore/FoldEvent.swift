import Foundation

/// One recorded fold or unfold. The event log is the source of truth;
/// all statistics are computed from it (DECISIONS T-1).
public struct FoldEvent: Codable, Sendable, Hashable, Identifiable {
    public var id: UUID
    public var type: EventType
    public var source: DetectionSource
    /// The instant the event happened (UTC). Change it with `setTimestamp(_:)`,
    /// which keeps `localDay` consistent.
    public private(set) var timestamp: Date
    /// Time zone at capture; kept even when the time is edited.
    public var timeZoneID: String
    /// Local calendar day at capture, used for daily buckets.
    public private(set) var localDay: LocalDay
    public var note: String?
    public var createdAt: Date
    /// Last change (edit, delete, import merge). Newer wins on import.
    public var updatedAt: Date
    /// True once the user edited an automatically recorded event.
    public var isEdited: Bool
    /// Tombstone: set instead of physically deleting, so imports can't resurrect it.
    public var deletedAt: Date?
    /// Set when this event was merged into another (de-duplication); hidden from totals.
    public var duplicateOf: UUID?
    /// For `inferred` gaps: the window in which the missed event happened.
    public var inferredIntervalStart: Date?
    public var inferredIntervalEnd: Date?

    public init(
        id: UUID = UUID(),
        type: EventType,
        source: DetectionSource,
        timestamp: Date,
        timeZone: TimeZone = .current,
        note: String? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil,
        isEdited: Bool = false,
        deletedAt: Date? = nil,
        duplicateOf: UUID? = nil,
        inferredIntervalStart: Date? = nil,
        inferredIntervalEnd: Date? = nil,
        localDay: LocalDay? = nil
    ) {
        self.id = id
        self.type = type
        self.source = source
        self.timestamp = timestamp
        self.timeZoneID = timeZone.identifier
        // A stored day (from the database) skips the calendar computation.
        self.localDay = localDay ?? LocalDay(date: timestamp, timeZone: timeZone)
        self.note = note
        self.createdAt = createdAt ?? timestamp
        self.updatedAt = updatedAt ?? createdAt ?? timestamp
        self.isEdited = isEdited
        self.deletedAt = deletedAt
        self.duplicateOf = duplicateOf
        self.inferredIntervalStart = inferredIntervalStart
        self.inferredIntervalEnd = inferredIntervalEnd
    }

    /// Changes the time of the event (an edit). The local day is recomputed in the
    /// *capture* time zone, which never changes (feasibility §6).
    public mutating func setTimestamp(_ newValue: Date) {
        timestamp = newValue
        localDay = LocalDay(date: newValue, timeZone: timeZone)
    }

    /// Not deleted and not merged into another event.
    public var isLive: Bool { deletedAt == nil && duplicateOf == nil }

    /// The capture time zone (falls back to UTC if the identifier is unknown).
    public var timeZone: TimeZone { TimeZone(identifier: timeZoneID) ?? TimeZone(identifier: "UTC")! }

    /// Counts toward totals: live, and not a gap unless gaps are included.
    public func isCounted(includeInferred: Bool) -> Bool {
        isLive && (includeInferred || source != .inferred)
    }
}
