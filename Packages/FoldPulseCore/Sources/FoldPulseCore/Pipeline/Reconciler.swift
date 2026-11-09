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
/// the Data Analyst in Phase 3 and the Phase 4 review). Pure and idempotent:
/// running it on its own output yields an empty plan.
///
/// - **Same-source repeats:** the same source recording the same type again within
///   1 s (a double tap, a Shortcut firing twice) joins the first event's group.
/// - **Cross-source duplicates:** hinge events are the backbone (the hinge sees
///   every fold while the app is on screen). Each Shortcut event, then each manual
///   event, pairs one-to-one with the *nearest* kept event of the same type within
///   ±10 s, in either order. Opposite-type events in between don't block pairing:
///   lagging Shortcuts after a quick close-and-reopen interleave with the hinge
///   events they confirm (Phase 4 review D2). Each kept event absorbs at most one
///   event per source, and the kept event is always the higher-precedence one.
/// - **Gaps:** folds and unfolds alternate, so two consecutive kept events of the
///   same type prove one opposite event was missed. A gap records the window
///   `[earlier, later]` and is bucketed on the later event's day.
/// - **Window protection:** when reconciling a slice of the log, `protectBefore`
///   marks where the slice starts. Events whose partner might lie before it, and
///   gaps whose earlier end lies before it, are left untouched (Phase 4 review D1).
public enum Reconciler {
    public static let duplicateWindow: TimeInterval = 10
    public static let sameSourceWindow: TimeInterval = 1

    /// Plans changes for `events` (non-deleted events of a slice, any order).
    public static func plan(for events: [FoldEvent], now: Date, protectBefore: Date? = nil) -> ReconcilePlan {
        let live = events.filter { $0.deletedAt == nil }
        let recorded = live.filter { $0.source != .inferred }.sorted(by: chronological)
        let existingGaps = live.filter { $0.source == .inferred }

        // 1. Same-source groups (≤ 1 s, same type).
        var leaderOf: [UUID: UUID] = [:]
        var previous: [String: FoldEvent] = [:]
        for event in recorded {
            let key = "\(event.source.rawValue)-\(event.type.rawValue)"
            if let prior = previous[key], event.timestamp.timeIntervalSince(prior.timestamp) <= sameSourceWindow {
                leaderOf[event.id] = leaderOf[prior.id] ?? prior.id
            }
            previous[key] = event
        }
        let leaders = recorded.filter { leaderOf[$0.id] == nil }

        // 2. Cross-source pairing against the kept backbone.
        var kept = leaders.filter { $0.source == .hinge }
        var absorbed: [UUID: Set<DetectionSource>] = [:]
        var duplicateOf: [UUID: UUID] = [:]
        for source in [DetectionSource.shortcut, .manual] {
            for event in leaders where event.source == source {
                // Only a higher-precedence kept event can absorb this one: Shortcut events
                // never pair with other Shortcut events (a real quick close-open-close
                // seen only by the automation must count as two folds).
                let candidates = kept.indices.filter {
                    kept[$0].source.precedence > source.precedence
                        && kept[$0].type == event.type
                        && abs(kept[$0].timestamp.timeIntervalSince(event.timestamp)) <= duplicateWindow
                        && !(absorbed[kept[$0].id] ?? []).contains(source)
                }
                if let best = candidates.min(by: {
                    abs(kept[$0].timestamp.timeIntervalSince(event.timestamp)) < abs(kept[$1].timestamp.timeIntervalSince(event.timestamp))
                }) {
                    duplicateOf[event.id] = kept[best].id
                    absorbed[kept[best].id, default: []].insert(source)
                } else {
                    kept.append(event)
                }
            }
            kept.sort(by: chronological)
        }
        for (member, leader) in leaderOf {
            duplicateOf[member] = duplicateOf[leader] ?? leader
        }

        let protectedUntil = protectBefore.map { $0.addingTimeInterval(duplicateWindow) }
        var plan = ReconcilePlan()
        for event in recorded {
            if let protectedUntil, event.timestamp < protectedUntil { continue }
            let desired = duplicateOf[event.id]
            if desired != event.duplicateOf {
                if let desired { plan.markDuplicate[event.id] = desired } else { plan.clearDuplicate.insert(event.id) }
            }
        }

        // 3. Gaps between consecutive kept events of the same type.
        var unmatched = existingGaps
        for (earlier, later) in zip(kept, kept.dropFirst()) where earlier.type == later.type {
            if let protectBefore, earlier.timestamp < protectBefore { continue }
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
        plan.removeGaps = Set(unmatched.filter { gap in
            guard let protectBefore else { return true }
            return (gap.inferredIntervalStart ?? gap.timestamp) >= protectBefore
        }.map(\.id))
        return plan
    }

    private static func chronological(_ a: FoldEvent, _ b: FoldEvent) -> Bool {
        a.timestamp != b.timestamp ? a.timestamp < b.timestamp : a.source.precedence > b.source.precedence
    }
}
