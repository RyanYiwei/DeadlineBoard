import SwiftUI
import SwiftData
import UserNotifications

@main
struct DeadlineBoardApp: App {
    let container: ModelContainer

    init() {
        container = SharedModelContainer.create()
    }

    var body: some Scene {
        WindowGroup {
            DashboardView()
                .preferredColorScheme(.light)
                .task {
                    await reconcileNotifications()
                }
        }
        .modelContainer(container)

        #if os(macOS)
        Settings {
            SettingsView()
                .preferredColorScheme(.light)
        }
        .modelContainer(container)
        #endif
    }

    @MainActor
    private func reconcileNotifications() async {
        let modelContext = container.mainContext
        let descriptor = FetchDescriptor<DDDeadline>()
        guard let deadlines = try? modelContext.fetch(descriptor) else { return }

        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let pendingIds = Set(pending.map(\.identifier))

        var idsToRemove = Set<String>()

        for deadline in deadlines {
            var needsReschedule = false

            for rule in deadline.reminderRules {
                if deadline.status == .completed || !rule.isEnabled || rule.triggerDate <= Date() {
                    if pendingIds.contains(rule.notificationIdentifier) {
                        idsToRemove.insert(rule.notificationIdentifier)
                    }
                } else {
                    if !pendingIds.contains(rule.notificationIdentifier) {
                        needsReschedule = true
                    }
                }
            }

            if needsReschedule && deadline.status != .completed {
                NotificationService.shared.scheduleReminders(for: deadline)
            }
        }

        if !idsToRemove.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: Array(idsToRemove))
        }
    }
}
