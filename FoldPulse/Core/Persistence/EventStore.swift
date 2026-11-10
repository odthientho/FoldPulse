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

    // MARK: Day tally (Phase 5 performance)
    //
    // Long-range numbers (total, averages, Insights) need only counted folds per
    // day. Counts for rows older than `settledBefore` are kept here; newer rows are
    // read fresh on every load. Every write first calls `willChange(from:)` with the
    // earliest timestamp it can touch, which moves that boundary back (subtracting
    // the affected rows while they are still unchanged). This actor is the only
    // writer (DECISIONS T-2), so the kept counts can't go stale behind its back.

    /// Rows at least this old are folded into the kept counts.
    /// 10 days: covers the last 7 local days even after extreme travel (UTC+14 → UTC−12).
    static let settledAge: TimeInterval = 10 * 86_400
    private var settledCounts: [LocalDay: Int]?
    private var settledBefore: Date = .distantPast

    /// Counted folds per day, plus the first tracked day.
    func tally(now: Date) throws -> DayTally {
        let target = now.addingTimeInterval(-Self.settledAge)
        if settledCounts == nil {
            settledCounts = try settledFoldCounts(before: target)
            settledBefore = target
        } else if target.timeIntervalSince(settledBefore) > 7 * 86_400 {
            merge(try foldCounts(from: settledBefore, before: target), into: &settledCounts!, sign: 1)
            settledBefore = target
        }
        var counts = settledCounts!
        merge(try foldCounts(from: settledBefore, before: .distantFuture), into: &counts, sign: 1)
        return DayTally(foldsByDay: counts, firstTrackedDay: try firstTrackedDay())
    }

    /// Today, the widget and the 7-day numbers need only the last 10 days plus the
    /// total, so a first load doesn't wait for the full per-day counts.
    private func recentTally(now: Date) throws -> DayTally {
        if settledCounts != nil { return try tally(now: now) }
        let boundary = now.addingTimeInterval(-Self.settledAge)
        let recent = try foldCounts(from: boundary, before: .distantFuture)
        let older = try modelContext.fetchCount(countedFolds(from: .distantPast, before: boundary))
        return DayTally(foldsByDay: recent, firstTrackedDay: try firstTrackedDay(),
                        total: older + recent.values.reduce(0, +))
    }

    private func countedFolds(from: Date, before: Date, day: String? = nil) -> FetchDescriptor<StoredEvent> {
        let fold = EventType.fold.rawValue
        let sources = [DetectionSource.hinge, .shortcut, .manual].map(\.rawValue)
        if let day {
            return FetchDescriptor<StoredEvent>(predicate: #Predicate {
                $0.localDay == day && $0.typeRaw == fold && $0.deletedAt == nil && $0.duplicateOf == nil
                    && sources.contains($0.sourceRaw) && $0.timestamp >= from && $0.timestamp < before
            })
        }
        return FetchDescriptor<StoredEvent>(predicate: #Predicate {
            $0.typeRaw == fold && $0.deletedAt == nil && $0.duplicateOf == nil && sources.contains($0.sourceRaw)
                && $0.timestamp >= from && $0.timestamp < before
        })
    }

    /// Full per-day counts for rows before `before`, built with one indexed
    /// COUNT per day (no rows loaded). Falls back to reading rows if the counts
    /// don't add up (e.g. an unreadable stored day) or the range is implausible.
    private func settledFoldCounts(before: Date) throws -> [LocalDay: Int] {
        guard let first = try firstTrackedDay() else { return [:] }
        let last = LocalDay(date: before, timeZone: FoldEvent.fallbackTimeZone).adding(days: 2)
        let days = LocalDay.range(from: first, through: last)
        guard days.count <= 3_700 else { return try foldCounts(from: .distantPast, before: before) }
        var result: [LocalDay: Int] = [:]
        var sum = 0
        for day in days {
            let count = try modelContext.fetchCount(countedFolds(from: .distantPast, before: before, day: day.description))
            if count > 0 { result[day] = count; sum += count }
        }
        guard sum == (try modelContext.fetchCount(countedFolds(from: .distantPast, before: before))) else {
            return try foldCounts(from: .distantPast, before: before)
        }
        return result
    }

    /// Call before changing any row with a timestamp at or after `time`.
    private func willChange(from time: Date) throws {
        guard settledCounts != nil, time < settledBefore else { return }
        merge(try foldCounts(from: time, before: settledBefore), into: &settledCounts!, sign: -1)
        settledBefore = time
    }

    private func merge(_ counts: [LocalDay: Int], into target: inout [LocalDay: Int], sign: Int) {
        for (day, count) in counts { target[day, default: 0] += sign * count }
    }

    /// Counted folds per local day for rows with `from <= timestamp < before`: a
    /// narrow query that reads three columns and never builds `FoldEvent` values.
    /// Same rule as `FoldEvent.isCounted`: live, not a gap, and known source.
    private func foldCounts(from: Date, before: Date) throws -> [LocalDay: Int] {
        var descriptor = countedFolds(from: from, before: before)
        descriptor.propertiesToFetch = [\.localDay, \.timestamp, \.timeZoneID]
        var days: [String: LocalDay] = [:]
        var result: [LocalDay: Int] = [:]
        for row in try modelContext.fetch(descriptor) {
            let day: LocalDay
            if let known = days[row.localDay] {
                day = known
            } else if let parsed = LocalDay(string: row.localDay) {
                days[row.localDay] = parsed
                day = parsed
            } else { // unreadable stored day: derive it, as `domainEvent` does
                day = LocalDay(date: row.timestamp, timeZone: TimeZone(identifier: row.timeZoneID) ?? FoldEvent.fallbackTimeZone)
            }
            result[day, default: 0] += 1
        }
        return result
    }

    /// The earliest local day with any live event (`Statistics.firstTrackedDay`).
    private func firstTrackedDay() throws -> LocalDay? {
        let types = EventType.allCases.map(\.rawValue)
        let sources = DetectionSource.allCases.map(\.rawValue)
        var descriptor = FetchDescriptor<StoredEvent>(
            predicate: #Predicate { $0.deletedAt == nil && $0.duplicateOf == nil && types.contains($0.typeRaw) && sources.contains($0.sourceRaw) },
            sortBy: [SortDescriptor(\.localDay)])
        descriptor.fetchLimit = 1
        descriptor.propertiesToFetch = [\.localDay, \.timestamp, \.timeZoneID]
        guard let row = try modelContext.fetch(descriptor).first else { return nil }
        return LocalDay(string: row.localDay)
            ?? LocalDay(date: row.timestamp, timeZone: TimeZone(identifier: row.timeZoneID) ?? FoldEvent.fallbackTimeZone)
    }

    /// Non-deleted events with `timestamp >= since`, oldest first.
    private func events(since: Date) throws -> [FoldEvent] {
        let descriptor = FetchDescriptor<StoredEvent>(predicate: #Predicate { $0.deletedAt == nil && $0.timestamp >= since },
                                                      sortBy: [SortDescriptor(\.timestamp)])
        var zones: [String: TimeZone] = [:]
        return try modelContext.fetch(descriptor).compactMap { $0.domainEvent(zones: &zones) }
    }

    // MARK: Writing and reading

    /// Inserts a new event. Rejects an id that already exists.
    func add(_ event: FoldEvent) throws {
        if try row(event.id) != nil { throw StoreError.duplicateID(event.id) }
        try willChange(from: event.timestamp)
        modelContext.insert(StoredEvent(event))
        try modelContext.save()
    }

    /// Inserts many events with a single save. Rejects any existing id unless
    /// `checkingDuplicates` is false (fresh UUIDs only: test seeding, sample data).
    func add(contentsOf events: [FoldEvent], checkingDuplicates: Bool = true) throws {
        if checkingDuplicates { // check everything first, so a rejected batch inserts nothing
            for event in events {
                if try row(event.id) != nil { throw StoreError.duplicateID(event.id) }
            }
        }
        if let earliest = events.map(\.timestamp).min() { try willChange(from: earliest) }
        for event in events { modelContext.insert(StoredEvent(event)) }
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
    /// Reads the day tally, the last few days' events and the newest `recentLimit`
    /// live events, never the whole log (Phase 5 performance, PF-01).
    func loadState(now: Date, timeZone: TimeZone, recentLimit: Int = 500) throws -> LoadedState {
        let week = try events(since: now.addingTimeInterval(-Self.settledAge))
        var newest = FetchDescriptor<StoredEvent>(predicate: #Predicate { $0.deletedAt == nil && $0.duplicateOf == nil },
                                                  sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        newest.fetchLimit = recentLimit
        var zones: [String: TimeZone] = [:]
        return LoadedState(dashboard: DashboardStats.make(tally: try recentTally(now: now), recent: week, now: now, timeZone: timeZone),
                           recentEvents: try modelContext.fetch(newest).compactMap { $0.domainEvent(zones: &zones) })
    }

    func count() throws -> Int {
        try modelContext.fetchCount(FetchDescriptor<StoredEvent>())
    }

    /// Replaces an existing event's fields and bumps `updatedAt`.
    func update(_ event: FoldEvent, now: Date = .now) throws {
        let row = try find(event.id)
        try willChange(from: min(row.timestamp, event.timestamp))
        var changed = event
        changed.updatedAt = now
        row.apply(changed)
        try modelContext.save()
    }

    /// Tombstones an event (never physically removed, so imports can't resurrect it).
    func softDelete(id: UUID, now: Date = .now) throws {
        let row = try find(id)
        try willChange(from: row.timestamp)
        row.deletedAt = now
        row.updatedAt = now
        row.note = nil // a deleted event keeps no personal text (Phase 4 privacy review)
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
        try willChange(from: min(previousTime, event.timestamp))
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
    /// earliest of `times` onwards (the Reconciler is idempotent). Pairs and gaps whose
    /// context lies before the slice are protected (Phase 4 review D1).
    func reconcile(around times: [Date], now: Date) throws {
        guard let earliest = times.min() else { return }
        let from = earliest.addingTimeInterval(-7 * 86_400)
        try willChange(from: from)
        let descriptor = FetchDescriptor<StoredEvent>(
            predicate: #Predicate { $0.deletedAt == nil && $0.timestamp >= from },
            sortBy: [SortDescriptor(\.timestamp)])
        let rows = try modelContext.fetch(descriptor)
        var zones: [String: TimeZone] = [:]
        let plan = Reconciler.plan(for: rows.compactMap { $0.domainEvent(zones: &zones) }, now: now, protectBefore: from)
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
        Statistics.summary(tally: try tally(now: now), recent: try events(since: now.addingTimeInterval(-3 * 86_400)),
                           period: period, now: now, timeZone: timeZone)
    }

    /// History: live events newest first, optionally since a date and limited to sources.
    /// History shows at most this many events per query; the screen says so when reached.
    static let historyLimit = 10_000

    func history(since: Date?, sources: Set<DetectionSource>?, limit: Int = EventStore.historyLimit) throws -> [FoldEvent] {
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

    /// Events for export: everything that isn't deleted (v1; tombstones would only
    /// matter for the deferred import, and deleted events must not leave the device).
    func exportEvents() throws -> [FoldEvent] {
        try allEvents()
    }

    /// Erases everything (Settings → Reset all data).
    func deleteAll() throws {
        settledCounts = nil // first, so a failed save can't leave stale counts
        settledBefore = .distantPast
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
