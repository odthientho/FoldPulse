import Foundation

/// Changes needed to make the event log consistent (de-duplication + gaps).
public struct ReconcilePlan: Equatable, Sendable {
    /// Event id → the id it duplicates.
    public var markDuplicate: [UUID: UUID] = [:]
    /// Events that are no longer duplicates (e.g. their partner was deleted).
    public var clearDuplicate: Set<UUID> = []
    /// New `inferred` gap events.
    public var addGaps: [FoldEvent] = []
    /// `inferred` gaps that no longer apply (to be tombstoned).
    public var removeGaps: Set<UUID> = []

    public init() {}

    public var isEmpty: Bool {
        markDuplicate.isEmpty && clearDuplicate.isEmpty && addGaps.isEmpty && removeGaps.isEmpty
    }
}

/// De-duplication and gap reconciliation (TECHNICAL_FEASIBILITY §6, revised by
/// the Data Analyst). Pure and idempotent: running it on its own output yields
/// an empty plan.
///
/// - **Duplicates:** two events of the same type, from *different* sources, with no
///   kept event of the opposite type between them and |Δt| ≤ 10 s, in either order,
///   are one physical event. The higher-precedence source is kept
///   (hinge > shortcut > manual). Pairing is one-to-one per source.
///   The same source repeating the same type within 1 s is also a duplicate.
/// - **Gaps:** folds and unfolds alternate, so two consecutive kept events of the
///   same type prove one opposite event was missed. A gap event records the window
///   `[earlier, later]` and is bucketed on the later event's day.
public enum Reconciler {
    public static let duplicateWindow: TimeInterval = 10
    public static let sameSourceWindow: TimeInterval = 1

    /// Plans changes for `events` (non-deleted events in the window to reconcile,
    /// any order). Gap events in the input are compared with the gaps that should
    /// exist and kept, added or removed accordingly.
    public static func plan(for events: [FoldEvent], now: Date) -> ReconcilePlan {
        let live = events.filter { $0.deletedAt == nil }
        let recorded = live.filter { $0.source != .inferred }.sorted(by: chronological)
        let existingGaps = live.filter { $0.source == .inferred }

        // 1. De-duplication.
        var kept: [FoldEvent] = []
        var duplicateOf: [UUID: UUID] = [:]
        var absorbed: [UUID: Set<DetectionSource>] = [:]

        for event in recorded {
            if let index = partnerIndex(for: event, in: kept, absorbed: absorbed) {
                let partner = kept[index]
                if event.source.precedence > partner.source.precedence {
                    // The new event wins: it replaces the partner as the kept event.
                    kept[index] = event
                    duplicateOf[partner.id] = event.id
                    for (id, of) in duplicateOf where of == partner.id { duplicateOf[id] = event.id }
                    absorbed[event.id] = (absorbed[partner.id] ?? []).union([partner.source])
                    absorbed[partner.id] = nil
                } else {
                    duplicateOf[event.id] = partner.id
                    absorbed[partner.id, default: []].insert(event.source)
                }
            } else {
                kept.append(event)
            }
        }

        var plan = ReconcilePlan()
        for event in recorded {
            let desired = duplicateOf[event.id]
            if desired != event.duplicateOf {
                if let desired { plan.markDuplicate[event.id] = desired } else { plan.clearDuplicate.insert(event.id) }
            }
        }

        // 2. Gaps between consecutive kept events of the same type.
        var unmatched = existingGaps
        for (earlier, later) in zip(kept, kept.dropFirst()) where earlier.type == later.type {
            let type = earlier.type.opposite
            if let match = unmatched.firstIndex(where: {
                $0.type == type && $0.inferredIntervalStart == earlier.timestamp && $0.inferredIntervalEnd == later.timestamp
            }) {
                unmatched.remove(at: match)
            } else {
                plan.addGaps.append(FoldEvent(
                    type: type, source: .inferred,
                    timestamp: later.timestamp.addingTimeInterval(-0.001),
                    timeZone: later.timeZone, createdAt: now, updatedAt: now,
                    inferredIntervalStart: earlier.timestamp, inferredIntervalEnd: later.timestamp,
                    localDay: later.localDay))
            }
        }
        plan.removeGaps = Set(unmatched.map(\.id))
        return plan
    }

    /// The nearest kept event this one could duplicate, or nil.
    private static func partnerIndex(for event: FoldEvent, in kept: [FoldEvent], absorbed: [UUID: Set<DetectionSource>]) -> Int? {
        guard let index = kept.indices.last else { return nil }
        let candidate = kept[index]
        // An opposite-type kept event in between (or as the latest) means a real transition happened.
        guard candidate.type == event.type else { return nil }
        let delta = abs(event.timestamp.timeIntervalSince(candidate.timestamp))
        if candidate.source == event.source {
            return delta <= sameSourceWindow ? index : nil
        }
        guard delta <= duplicateWindow, !(absorbed[candidate.id] ?? []).contains(event.source) else { return nil }
        return index
    }

    private static func chronological(_ a: FoldEvent, _ b: FoldEvent) -> Bool {
        a.timestamp != b.timestamp ? a.timestamp < b.timestamp : a.source.precedence > b.source.precedence
    }
}
