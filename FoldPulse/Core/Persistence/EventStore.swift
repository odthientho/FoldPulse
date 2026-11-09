import Foundation
import SwiftData
import FoldPulseCore

/// The single writer for the event log (DECISIONS T-2). All database access
/// goes through this actor; callers exchange plain `FoldEvent` values.
@ModelActor
actor EventStore {
    enum StoreError: Error, Equatable {
        case notFound(UUID)
    }

    /// Inserts a new event.
    func add(_ event: FoldEvent) throws {
        modelContext.insert(StoredEvent(event))
        try modelContext.save()
    }

    /// All events in chronological order. Tombstoned events are excluded unless requested.
    func allEvents(includeDeleted: Bool = false) throws -> [FoldEvent] {
        let descriptor = FetchDescriptor<StoredEvent>(sortBy: [SortDescriptor(\.timestamp)])
        return try modelContext.fetch(descriptor)
            .compactMap(\.domainEvent)
            .filter { includeDeleted || $0.deletedAt == nil }
    }

    func count() throws -> Int {
        try modelContext.fetchCount(FetchDescriptor<StoredEvent>())
    }

    /// Replaces an existing event's fields and bumps `updatedAt`.
    func update(_ event: FoldEvent, now: Date = .now) throws {
        let row = try find(event.id)
        var changed = event
        changed.updatedAt = now
        row.apply(changed)
        try modelContext.save()
    }

    /// Tombstones an event (never physically removed, so imports can't resurrect it).
    func softDelete(id: UUID, now: Date = .now) throws {
        let row = try find(id)
        row.deletedAt = now
        row.updatedAt = now
        try modelContext.save()
    }

    /// Erases everything (Settings → Reset all data).
    func deleteAll() throws {
        try modelContext.delete(model: StoredEvent.self)
        try modelContext.save()
    }

    private func find(_ id: UUID) throws -> StoredEvent {
        var descriptor = FetchDescriptor<StoredEvent>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        guard let row = try modelContext.fetch(descriptor).first else { throw StoreError.notFound(id) }
        return row
    }
}
