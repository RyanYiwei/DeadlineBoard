import Foundation
import SwiftData

@Model
final class DDReminderRule {
    @Attribute(.unique) var id: UUID
    var deadline: DDDeadline?
    var triggerDate: Date
    var isEnabled: Bool
    var relativeOffset: TimeInterval?
    var notificationIdentifier: String

    init(
        triggerDate: Date,
        isEnabled: Bool = true,
        relativeOffset: TimeInterval? = nil
    ) {
        self.id = UUID()
        self.triggerDate = triggerDate
        self.isEnabled = isEnabled
        self.relativeOffset = relativeOffset
        self.notificationIdentifier = UUID().uuidString
    }

    func recalculateTriggerDate(from dueDate: Date) {
        if let offset = relativeOffset {
            triggerDate = dueDate.addingTimeInterval(offset)
        }
    }
}
