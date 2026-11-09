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
    var domainEvent: FoldEvent? {
        guard let type = EventType(rawValue: typeRaw), let source = DetectionSource(rawValue: sourceRaw) else { return nil }
        let zone = TimeZone(identifier: timeZoneID) ?? TimeZone(identifier: "UTC")!
        var event = FoldEvent(id: id, type: type, source: source, timestamp: timestamp, timeZone: zone, note: note,
                              createdAt: createdAt, updatedAt: updatedAt, isEdited: isEdited, deletedAt: deletedAt,
                              duplicateOf: duplicateOf, inferredIntervalStart: inferredIntervalStart,
                              inferredIntervalEnd: inferredIntervalEnd)
        event.timeZoneID = timeZoneID
        if let day = LocalDay(string: localDay) { event.localDay = day }
        return event
    }
}
