import Foundation

enum ProgressCalculator {
    static func progress(for deadline: DDDeadline) -> Double {
        if deadline.status == .completed { return 1.0 }

        switch deadline.progressMode {
        case .manual:
            return deadline.manualProgress
        case .checklist:
            return checklistProgress(for: deadline)
        }
    }

    static func checklistProgress(for deadline: DDDeadline) -> Double {
        let items = deadline.actionItems
        guard !items.isEmpty else { return 0.0 }
        let completed = items.filter(\.isCompleted).count
        return Double(completed) / Double(items.count)
    }

    static func allActionItemsCompleted(_ deadline: DDDeadline) -> Bool {
        let items = deadline.actionItems
        return !items.isEmpty && items.allSatisfy(\.isCompleted)
    }
}
