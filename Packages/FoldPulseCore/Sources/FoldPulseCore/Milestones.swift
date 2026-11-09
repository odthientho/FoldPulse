import Foundation

/// Fold-count milestones. Each one is celebrated once, ever (feasibility §6).
public enum Milestones {
    public static let thresholds: [Int] = [100, 500, 1_000, 5_000, 10_000, 25_000, 50_000, 100_000]

    /// The next milestone strictly above `total`, or nil after the last one.
    public static func next(after total: Int) -> Int? {
        thresholds.first { $0 > total }
    }

    /// Fraction of the way to the next milestone, measured from zero (0...1).
    public static func progress(total: Int) -> Double? {
        guard let next = next(after: total) else { return nil }
        return min(1, max(0, Double(total) / Double(next)))
    }

    /// All milestones reached at `total`.
    public static func reached(total: Int) -> [Int] {
        thresholds.filter { $0 <= total }
    }

    /// Milestones to celebrate now: reached, and not celebrated before.
    /// Deleting events never "un-celebrates" a milestone.
    public static func toCelebrate(total: Int, alreadyCelebrated: Set<Int>) -> [Int] {
        reached(total: total).filter { !alreadyCelebrated.contains($0) }
    }
}
