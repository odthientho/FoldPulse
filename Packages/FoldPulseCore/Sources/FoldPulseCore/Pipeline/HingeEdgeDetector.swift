import Foundation

/// Coarse hinge state: FoldPulse only counts transitions into and out of `closed`.
/// `partiallyOpen` and `fullyOpen` are both `open` (rotation can flip between them;
/// see R-22), so they never produce events.
public enum CoarseHingeState: String, Sendable, Equatable {
    case closed
    case open
}

/// A committed fold or unfold detected from hinge readings.
public struct HingeEdge: Equatable, Sendable {
    public let type: EventType
    /// When the new state was *first entered* (not when it was committed).
    public let at: Date

    public init(type: EventType, at: Date) {
        self.type = type
        self.at = at
    }
}

/// Turns raw hinge readings into fold/unfold edges (TECHNICAL_FEASIBILITY §6).
///
/// Rules:
/// - **Debounce:** a new state is committed once it has been stable for `debounce`
///   (default 250 ms). A bounce back to the committed state cancels it.
/// - **Timestamp** = the moment the state was first entered.
/// - **Baseline:** the first reading (after launch, activation or a `nil` period)
///   only sets the baseline; it never creates an edge.
/// - **Flush:** on a lifecycle change, a pending state is committed immediately,
///   so closing the phone (which may background the app) doesn't lose the fold.
/// - `nil` readings (unknown / no hinge in this hierarchy) clear the baseline.
///
/// The type is a value with no clock of its own: callers pass times in, which
/// makes it fully deterministic in tests.
public struct HingeEdgeDetector: Sendable {
    public static let defaultDebounce: TimeInterval = 0.25

    private struct Candidate: Sendable, Equatable {
        let state: CoarseHingeState
        let since: Date
    }

    public let debounce: TimeInterval
    public private(set) var committed: CoarseHingeState?
    private var candidate: Candidate?

    public init(debounce: TimeInterval = HingeEdgeDetector.defaultDebounce) {
        self.debounce = debounce
    }

    /// When the pending state (if any) becomes eligible for commit — the caller
    /// schedules a `tick(at:)` for this time.
    public var pendingDeadline: Date? { candidate.map { $0.since.addingTimeInterval(debounce) } }

    /// Feeds one reading. Returns any edge committed as a result.
    public mutating func observe(_ state: CoarseHingeState?, at time: Date) -> [HingeEdge] {
        guard let state else {
            resetBaseline()
            return []
        }
        // A previous candidate that stayed stable long enough before this reading commits first.
        let edges = commitIfStable(at: time)
        if state == committed {
            candidate = nil // bounced back: cancel the pending change
        } else if candidate?.state != state {
            candidate = Candidate(state: state, since: time)
        }
        return edges
    }

    /// Commits a pending state that has been stable for at least `debounce`.
    public mutating func tick(at time: Date) -> [HingeEdge] {
        commitIfStable(at: time)
    }

    /// Commits any pending state immediately (scene phase change).
    public mutating func flush() -> [HingeEdge] {
        guard let candidate else { return [] }
        return commit(candidate)
    }

    /// Forgets the baseline: the next stable reading is a new baseline.
    public mutating func resetBaseline() {
        committed = nil
        candidate = nil
    }

    private mutating func commitIfStable(at time: Date) -> [HingeEdge] {
        guard let candidate, time.timeIntervalSince(candidate.since) >= debounce else { return [] }
        return commit(candidate)
    }

    private mutating func commit(_ candidate: Candidate) -> [HingeEdge] {
        self.candidate = nil
        defer { committed = candidate.state }
        guard let previous = committed, previous != candidate.state else { return [] }
        return [HingeEdge(type: candidate.state == .closed ? .fold : .unfold, at: candidate.since)]
    }
}
