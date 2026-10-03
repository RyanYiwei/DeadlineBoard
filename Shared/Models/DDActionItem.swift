import Foundation
import SwiftData

@Model
final class DDActionItem {
    @Attribute(.unique) var id: UUID
    var deadline: DDDeadline?
    var title: String
    var isCompleted: Bool
    var optionalReminderDate: Date?
    var sortOrder: Int
    var createdAt: Date

    init(
        title: String,
        isCompleted: Bool = false,
        optionalReminderDate: Date? = nil,
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.title = title
        self.isCompleted = isCompleted
        self.optionalReminderDate = optionalReminderDate
        self.sortOrder = sortOrder
        self.createdAt = Date()
    }
}
