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

    // MARK: Recording and reconciliation (Phase 4)

    /// Inserts `event`, reconciles duplicates and gaps around it, and returns fresh state.
    func record(_ event: FoldEvent, now: Date, timeZone: TimeZone) throws -> LoadedState {
        try add(event)
        try reconcile(around: [event.timestamp], now: now)
        return try loadState(now: now, timeZone: timeZone)
    }

    /// Applies an edit (type, time, note), marks it edited, and reconciles both the old and new times.
    func edit(_ event: FoldEvent, now: Date) throws {
        let row = try find(event.id)
        let previousTime = row.timestamp
        var changed = event
        changed.isEdited = true
        changed.updatedAt = now
        row.apply(changed)
        try modelContext.save()
        try reconcile(around: [previousTime, event.timestamp], now: now)
    }

    /// Tombstones an event (also used for Undo) and reconciles around it.
    func delete(id: UUID, now: Date) throws {
        let row = try find(id)
        let time = row.timestamp
        try softDelete(id: id, now: now)
        try reconcile(around: [time], now: now)
    }

    /// Re-runs de-duplication and gap detection for events from 7 days before the
    /// earliest of `times` onwards (the Reconciler is idempotent).
    func reconcile(around times: [Date], now: Date) throws {
        guard let earliest = times.min() else { return }
        let from = earliest.addingTimeInterval(-7 * 86_400)
        let descriptor = FetchDescriptor<StoredEvent>(
            predicate: #Predicate { $0.deletedAt == nil && $0.timestamp >= from },
            sortBy: [SortDescriptor(\.timestamp)])
        let rows = try modelContext.fetch(descriptor)
        var zones: [String: TimeZone] = [:]
        let plan = Reconciler.plan(for: rows.compactMap { $0.domainEvent(zones: &zones) }, now: now)
        guard !plan.isEmpty else { return }
        let byID = Dictionary(rows.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        for (id, original) in plan.markDuplicate {
            byID[id]?.duplicateOf = original
            byID[id]?.updatedAt = now
        }
        for id in plan.clearDuplicate {
            byID[id]?.duplicateOf = nil
            byID[id]?.updatedAt = now
        }
        for id in plan.removeGaps {
            byID[id]?.deletedAt = now
            byID[id]?.updatedAt = now
        }
        for gap in plan.addGaps {
            modelContext.insert(StoredEvent(gap))
        }
        try modelContext.save()
    }

    /// Insights summary for a period, computed off the main thread.
    func summary(_ period: InsightPeriod, now: Date, timeZone: TimeZone) throws -> PeriodSummary {
        Statistics.summary(try allEvents(), period: period, now: now, timeZone: timeZone)
    }

    /// History: live events newest first, optionally since a date and limited to sources.
    func history(since: Date?, sources: Set<DetectionSource>?, limit: Int = 2_000) throws -> [FoldEvent] {
        var descriptor = FetchDescriptor<StoredEvent>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        if let since {
            descriptor.predicate = #Predicate { $0.deletedAt == nil && $0.duplicateOf == nil && $0.timestamp >= since }
        } else {
            descriptor.predicate = #Predicate { $0.deletedAt == nil && $0.duplicateOf == nil }
        }
        let wanted = sources?.map(\.rawValue)
        var zones: [String: TimeZone] = [:]
        var result: [FoldEvent] = []
        for row in try modelContext.fetch(descriptor) {
            if let wanted, !wanted.contains(row.sourceRaw) { continue }
            if let event = row.domainEvent(zones: &zones) { result.append(event) }
            if result.count >= limit { break }
        }
        return result
    }

    /// The event another one was merged into (History detail: "Matched with …").
    func event(id: UUID) throws -> FoldEvent? {
        var zones: [String: TimeZone] = [:]
        return try row(id)?.domainEvent(zones: &zones)
    }

    /// Every event including tombstones (full-fidelity JSON export).
    func exportEvents() throws -> [FoldEvent] {
        try allEvents(includeDeleted: true)
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
