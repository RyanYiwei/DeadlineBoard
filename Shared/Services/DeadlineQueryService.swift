import Foundation

enum DeadlineQueryService {
    /// Returns the most urgent incomplete deadline for a category, per the product rules:
    /// 1. Ignore completed deadlines
    /// 2. If overdue deadlines exist, return the one with the earliest due date
    /// 3. Otherwise return the upcoming deadline with the nearest due date
    /// 4. Tie-break by priority (higher first), then creation date (earlier first)
    static func mostUrgentDeadline(
        in category: DDCategory,
        now: Date = Date()
    ) -> DDDeadline? {
        let active = category.deadlines.filter { $0.status != .completed }
        guard !active.isEmpty else { return nil }

        let overdue = active.filter { $0.dueDate < now }
        if !overdue.isEmpty {
            return overdue.sorted(by: deadlineSortComparator).first
        }

        let upcoming = active.filter { $0.dueDate >= now }
        return upcoming.sorted(by: deadlineSortComparator).first
    }

    /// Sort: earliest due date first, then higher priority first, then earlier creation first
    private static func deadlineSortComparator(_ a: DDDeadline, _ b: DDDeadline) -> Bool {
        if a.dueDate != b.dueDate { return a.dueDate < b.dueDate }
        if a.priority != b.priority { return a.priority > b.priority }
        return a.createdAt < b.createdAt
    }

    /// Groups deadlines for category detail view
    static func groupedDeadlines(
        for category: DDCategory,
        now: Date = Date()
    ) -> DeadlineGroups {
        var overdue: [DDDeadline] = []
        var inProgress: [DDDeadline] = []
        var upcoming: [DDDeadline] = []
        var completed: [DDDeadline] = []

        for dl in category.deadlines {
            switch dl.status {
            case .completed:
                completed.append(dl)
            case .inProgress where dl.dueDate < now:
                overdue.append(dl)
            case .notStarted where dl.dueDate < now:
                overdue.append(dl)
            case .inProgress:
                inProgress.append(dl)
            case .notStarted:
                upcoming.append(dl)
            }
        }

        overdue.sort(by: deadlineSortComparator)
        inProgress.sort(by: deadlineSortComparator)
        upcoming.sort(by: deadlineSortComparator)
        completed.sort { ($0.completedAt ?? $0.createdAt) > ($1.completedAt ?? $1.createdAt) }

        return DeadlineGroups(
            overdue: overdue,
            inProgress: inProgress,
            upcoming: upcoming,
            completed: completed
        )
    }
}

struct DeadlineGroups {
    let overdue: [DDDeadline]
    let inProgress: [DDDeadline]
    let upcoming: [DDDeadline]
    let completed: [DDDeadline]
}
