import Foundation
import UserNotifications

final class NotificationService {
    static let shared = NotificationService()
    private init() {}

    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func checkPermissionStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }

    func scheduleReminders(for deadline: DDDeadline) {
        guard deadline.status != .completed else {
            cancelReminders(for: deadline)
            return
        }

        for rule in deadline.reminderRules where rule.isEnabled {
            scheduleNotification(for: rule, deadline: deadline)
        }
    }

    func cancelReminders(for deadline: DDDeadline) {
        let identifiers = deadline.reminderRules.map(\.notificationIdentifier)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    func cancelReminder(_ rule: DDReminderRule) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [rule.notificationIdentifier])
    }

    private func scheduleNotification(for rule: DDReminderRule, deadline: DDDeadline) {
        guard rule.triggerDate > Date() else { return }

        let content = UNMutableNotificationContent()
        let categoryName = deadline.category?.name ?? ""
        let relativeText = DateFormatService.relativeText(from: deadline.dueDate)
        let progressText = DateFormatService.progressText(deadline.progress)

        content.title = "\(categoryName) · \(deadline.title)"
        content.body = "\(deadline.title)\(relativeText)，目前完成 \(progressText)。"
        content.sound = .default

        if let categoryId = deadline.category?.id.uuidString,
           let deadlineId = deadline.id.uuidString as String? {
            content.userInfo = [
                "categoryId": categoryId,
                "deadlineId": deadlineId
            ]
        }

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: rule.triggerDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: rule.notificationIdentifier,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func rescheduleAllReminders(for deadline: DDDeadline) {
        cancelReminders(for: deadline)

        for rule in deadline.reminderRules {
            rule.recalculateTriggerDate(from: deadline.dueDate)
        }

        scheduleReminders(for: deadline)
    }
}
