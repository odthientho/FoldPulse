import Foundation
import FoldPulseCore

/// User settings and small bits of app state, stored in the App Group defaults
/// (privacy manifest reason 1C8F.1) so the app and its background intents agree.
@MainActor
final class AppSettings {
    enum Key {
        static let onboarding = "onboarding.completed"
        static let hasSeenHinge = "hinge.seen"
        static let theme = "appearance.theme"
        static let milestoneNotifications = "milestones.notifications"
        static let celebrated = "milestones.celebrated"
        static let pendingMilestone = "milestones.pending"
        static let lastShortcutFold = "shortcut.lastFold"
        static let lastShortcutUnfold = "shortcut.lastUnfold"
        static let selfTestStarted = "selftest.started"
        static let selfTestPassed = "selftest.passed"
    }

    let defaults: UserDefaults

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    var hasSeenHinge: Bool {
        get { defaults.bool(forKey: Key.hasSeenHinge) }
        set { defaults.set(newValue, forKey: Key.hasSeenHinge) }
    }

    var milestoneNotificationsEnabled: Bool {
        get { defaults.bool(forKey: Key.milestoneNotifications) }
        set { defaults.set(newValue, forKey: Key.milestoneNotifications) }
    }

    var celebratedMilestones: Set<Int> {
        get { Set(defaults.array(forKey: Key.celebrated) as? [Int] ?? []) }
        set { defaults.set(newValue.sorted(), forKey: Key.celebrated) }
    }

    /// A milestone reached but not yet celebrated in the app (shown once).
    var pendingMilestone: Int? {
        get { defaults.object(forKey: Key.pendingMilestone) as? Int }
        set { defaults.set(newValue, forKey: Key.pendingMilestone) }
    }

    var lastShortcutFold: Date? {
        get { defaults.object(forKey: Key.lastShortcutFold) as? Date }
        set { defaults.set(newValue, forKey: Key.lastShortcutFold) }
    }

    var lastShortcutUnfold: Date? {
        get { defaults.object(forKey: Key.lastShortcutUnfold) as? Date }
        set { defaults.set(newValue, forKey: Key.lastShortcutUnfold) }
    }

    var selfTestStartedAt: Date? {
        get { defaults.object(forKey: Key.selfTestStarted) as? Date }
        set { defaults.set(newValue, forKey: Key.selfTestStarted) }
    }

    var selfTestPassedAt: Date? {
        get { defaults.object(forKey: Key.selfTestPassed) as? Date }
        set { defaults.set(newValue, forKey: Key.selfTestPassed) }
    }

    /// Records newly reached milestones. Each is claimed once, ever (deletions never
    /// re-trigger it). Returns the new ones; the highest becomes `pendingMilestone`.
    func claimMilestones(total: Int) -> [Int] {
        let new = Milestones.toCelebrate(total: total, alreadyCelebrated: celebratedMilestones)
        guard let highest = new.max() else { return [] }
        celebratedMilestones.formUnion(new)
        pendingMilestone = max(pendingMilestone ?? 0, highest)
        return new
    }

    /// Settings → Reset all data. Clears everything except onboarding and appearance.
    func resetData() {
        for key in [Key.celebrated, Key.pendingMilestone, Key.lastShortcutFold, Key.lastShortcutUnfold,
                    Key.selfTestStarted, Key.selfTestPassed] {
            defaults.removeObject(forKey: key)
        }
    }
}
