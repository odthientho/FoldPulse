import Foundation
import UserNotifications

/// Optional local milestone notifications (off by default; the permission is
/// requested only when the user turns them on). Local only — no push entitlement.
enum MilestoneNotifier {
    static func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
    }

    static func notify(milestone: Int) async {
        let content = UNMutableNotificationContent()
        content.title = "\(milestone.formatted()) folds"
        content.body = "A FoldPulse milestone, counted since install."
        let request = UNNotificationRequest(identifier: "milestone-\(milestone)", content: content, trigger: nil)
        try? await UNUserNotificationCenter.current().add(request)
    }
}
