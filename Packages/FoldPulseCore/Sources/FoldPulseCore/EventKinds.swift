import Foundation

/// A fold (open → closed) or an unfold (closed → open).
public enum EventType: String, Codable, Sendable, CaseIterable {
    case fold
    case unfold

    public var opposite: EventType { self == .fold ? .unfold : .fold }
}

/// Where an event came from. Every event shows its source in the UI.
public enum DetectionSource: String, Codable, Sendable, CaseIterable {
    /// Observed by the hinge API while FoldPulse was on screen.
    case hinge
    /// Recorded by the user's Shortcuts "Opened or Closed" automation.
    case shortcut
    /// Recorded by hand (Record sheet or widget button).
    case manual
    /// A gap: alternation proves an event was missed. Never counted by default.
    case inferred

    /// Higher wins when two events are merged as duplicates.
    public var precedence: Int {
        switch self {
        case .hinge: return 3
        case .shortcut: return 2
        case .manual: return 1
        case .inferred: return 0
        }
    }

    /// Captured without the user tapping anything ("Counted for you").
    public var isCountedForYou: Bool { self == .hinge || self == .shortcut }
}
