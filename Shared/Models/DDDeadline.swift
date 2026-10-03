import Foundation
import SwiftData

enum DeadlineStatus: String, Codable, CaseIterable {
    case notStarted
    case inProgress
    case completed
}

enum DeadlinePriority: Int, Codable, CaseIterable, Comparable {
    case low = 0
    case normal = 1
    case high = 2

    var label: String {
        switch self {
        case .low: "低"
        case .normal: "普通"
        case .high: "高"
        }
    }

    static func < (lhs: DeadlinePriority, rhs: DeadlinePriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

enum ProgressMode: String, Codable, CaseIterable {
    case manual
    case checklist
}

@Model
final class DDDeadline {
    @Attribute(.unique) var id: UUID
    var category: DDCategory?
    var title: String
    var dueDate: Date
    var notes: String
    var statusRaw: String
    var priorityRaw: Int
    var progressModeRaw: String
    var manualProgress: Double
    var createdAt: Date
    var completedAt: Date?
    var savedProgressBeforeCompletion: Double?

    @Relationship(deleteRule: .cascade, inverse: \DDActionItem.deadline)
    var actionItems: [DDActionItem]

    @Relationship(deleteRule: .cascade, inverse: \DDReminderRule.deadline)
    var reminderRules: [DDReminderRule]

    init(
        title: String,
        dueDate: Date,
        notes: String = "",
        status: DeadlineStatus = .notStarted,
        priority: DeadlinePriority = .normal,
        progressMode: ProgressMode = .manual,
        manualProgress: Double = 0
    ) {
        self.id = UUID()
        self.title = title
        self.dueDate = dueDate
        self.notes = notes
        self.statusRaw = status.rawValue
        self.priorityRaw = priority.rawValue
        self.progressModeRaw = progressMode.rawValue
        self.manualProgress = manualProgress
        self.createdAt = Date()
        self.actionItems = []
        self.reminderRules = []
    }

    var status: DeadlineStatus {
        get { DeadlineStatus(rawValue: statusRaw) ?? .notStarted }
        set { statusRaw = newValue.rawValue }
    }

    var priority: DeadlinePriority {
        get { DeadlinePriority(rawValue: priorityRaw) ?? .normal }
        set { priorityRaw = newValue.rawValue }
    }

    var progressMode: ProgressMode {
        get { ProgressMode(rawValue: progressModeRaw) ?? .manual }
        set { progressModeRaw = newValue.rawValue }
    }

    var progress: Double {
        ProgressCalculator.progress(for: self)
    }

    var isOverdue: Bool {
        status != .completed && dueDate < Date()
    }

    func markCompleted() {
        savedProgressBeforeCompletion = progress
        status = .completed
        completedAt = Date()
        manualProgress = 1.0
    }

    func markIncomplete() {
        status = .inProgress
        completedAt = nil
        if let saved = savedProgressBeforeCompletion {
            manualProgress = saved
        }
        savedProgressBeforeCompletion = nil
    }
}
