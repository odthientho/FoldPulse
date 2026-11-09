import Foundation
import SwiftData
import FoldPulseCore

/// What the UI shows after a reload. Computed inside `EventStore`.
struct LoadedState: Sendable {
    let dashboard: DashboardStats
    /// Newest first, live events only (no tombstones or merged duplicates).
    let recentEvents: [FoldEvent]
}

/// The single writer for the event log (DECISIONS T-2). All database access
/// goes through this actor; callers exchange plain `FoldEvent` values.
@ModelActor
actor EventStore {
    enum StoreError: Error, Equatable {
        case notFound(UUID)
        /// SwiftData's `.unique` would silently overwrite; we reject instead (Phase 3 review).
        case duplicateID(UUID)
    }

    /// Inserts a new event. Rejects an id that already exists.
    func add(_ event: FoldEvent) throws {
        if try row(event.id) != nil { throw StoreError.duplicateID(event.id) }
        modelContext.insert(StoredEvent(event))
        try modelContext.save()
    }

    /// Inserts many events with a single save (rejects any existing id).
    func add(contentsOf events: [FoldEvent]) throws {
        for event in events {
            if try row(event.id) != nil { throw StoreError.duplicateID(event.id) }
            modelContext.insert(StoredEvent(event))
        }
        try modelContext.save()
    }

    /// All events in chronological order. Tombstones are filtered in the query
    /// unless requested.
    func allEvents(includeDeleted: Bool = false) throws -> [FoldEvent] {
        var descriptor = FetchDescriptor<StoredEvent>(sortBy: [SortDescriptor(\.timestamp)])
        if !includeDeleted {
            descriptor.predicate = #Predicate { $0.deletedAt == nil }
        }
        var zones: [String: TimeZone] = [:]
        return try modelContext.fetch(descriptor).compactMap { $0.domainEvent(zones: &zones) }
    }

    /// Everything the UI needs, computed here — off the main thread — in one pass.
    func loadState(now: Date, timeZone: TimeZone, recentLimit: Int = 500) throws -> LoadedState {
        let events = try allEvents()
        return LoadedState(dashboard: DashboardStats.make(from: events, now: now, timeZone: timeZone),
                           recentEvents: Array(events.filter(\.isLive).suffix(recentLimit).reversed()))
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
        guard let row = try row(id) else { throw StoreError.notFound(id) }
        return row
    }

    private func row(_ id: UUID) throws -> StoredEvent? {
        var descriptor = FetchDescriptor<StoredEvent>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }
}
