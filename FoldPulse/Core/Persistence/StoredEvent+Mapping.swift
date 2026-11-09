import Foundation
import FoldPulseCore

extension StoredEvent {
    /// Creates a stored row from a domain event.
    convenience init(_ event: FoldEvent) {
        self.init(id: event.id, typeRaw: event.type.rawValue, sourceRaw: event.source.rawValue,
                  timestamp: event.timestamp, timeZoneID: event.timeZoneID, localDay: event.localDay.description,
                  note: event.note, createdAt: event.createdAt, updatedAt: event.updatedAt, isEdited: event.isEdited,
                  deletedAt: event.deletedAt, duplicateOf: event.duplicateOf,
                  inferredIntervalStart: event.inferredIntervalStart, inferredIntervalEnd: event.inferredIntervalEnd)
    }

    /// Copies every mutable field from `event` (the id never changes).
    func apply(_ event: FoldEvent) {
        typeRaw = event.type.rawValue
        sourceRaw = event.source.rawValue
        timestamp = event.timestamp
        timeZoneID = event.timeZoneID
        localDay = event.localDay.description
        note = event.note
        createdAt = event.createdAt
        updatedAt = event.updatedAt
        isEdited = event.isEdited
        deletedAt = event.deletedAt
        duplicateOf = event.duplicateOf
        inferredIntervalStart = event.inferredIntervalStart
        inferredIntervalEnd = event.inferredIntervalEnd
    }

    /// The domain value, or nil if the row holds unknown enum values
    /// (written by a newer app version) — such rows are skipped, never guessed.
    /// `zones` caches `TimeZone` lookups across rows; the stored local day is
    /// reused, so loading does no per-row calendar work (Phase 3 performance review).
    func domainEvent(zones: inout [String: TimeZone]) -> FoldEvent? {
        guard let type = EventType(rawValue: typeRaw), let source = DetectionSource(rawValue: sourceRaw) else { return nil }
        let zone: TimeZone
        if let cached = zones[timeZoneID] {
            zone = cached
        } else {
            zone = TimeZone(identifier: timeZoneID) ?? FoldEvent.fallbackTimeZone
            zones[timeZoneID] = zone
        }
        var event = FoldEvent(id: id, type: type, source: source, timestamp: timestamp, timeZone: zone, note: note,
                              createdAt: createdAt, updatedAt: updatedAt, isEdited: isEdited, deletedAt: deletedAt,
                              duplicateOf: duplicateOf, inferredIntervalStart: inferredIntervalStart,
                              inferredIntervalEnd: inferredIntervalEnd, localDay: LocalDay(string: localDay))
        event.timeZoneID = timeZoneID
        return event
    }
}
