import Testing
import Foundation

@Suite("DeadlineQueryService Tests")
struct DeadlineQueryServiceTests {

    private func makeCategory(name: String = "Test") -> DDCategory {
        DDCategory(name: name)
    }

    private func makeDeadline(
        title: String,
        dueDate: Date,
        status: DeadlineStatus = .notStarted,
        priority: DeadlinePriority = .normal
    ) -> DDDeadline {
        DDDeadline(title: title, dueDate: dueDate, priority: priority)
    }

    @Test("Completed deadlines are filtered out")
    func completedFiltered() {
        let cat = makeCategory()
        let d1 = makeDeadline(title: "Done", dueDate: Date().addingTimeInterval(86400))
        d1.status = .completed
        d1.category = cat
        cat.deadlines = [d1]

        let result = DeadlineQueryService.mostUrgentDeadline(in: cat)
        #expect(result == nil)
    }

    @Test("Overdue deadline prioritized over upcoming")
    func overduePrioritized() {
        let cat = makeCategory()
        let now = Date()
        let overdue = makeDeadline(title: "Overdue", dueDate: now.addingTimeInterval(-86400))
        overdue.category = cat
        let upcoming = makeDeadline(title: "Upcoming", dueDate: now.addingTimeInterval(86400))
        upcoming.category = cat
        cat.deadlines = [overdue, upcoming]

        let result = DeadlineQueryService.mostUrgentDeadline(in: cat, now: now)
        #expect(result?.title == "Overdue")
    }

    @Test("Earliest overdue returned when multiple exist")
    func earliestOverdue() {
        let cat = makeCategory()
        let now = Date()
        let old = makeDeadline(title: "OldOverdue", dueDate: now.addingTimeInterval(-3 * 86400))
        old.category = cat
        let recent = makeDeadline(title: "RecentOverdue", dueDate: now.addingTimeInterval(-86400))
        recent.category = cat
        cat.deadlines = [recent, old]

        let result = DeadlineQueryService.mostUrgentDeadline(in: cat, now: now)
        #expect(result?.title == "OldOverdue")
    }

    @Test("Nearest upcoming returned when no overdue")
    func nearestUpcoming() {
        let cat = makeCategory()
        let now = Date()
        let far = makeDeadline(title: "Far", dueDate: now.addingTimeInterval(30 * 86400))
        far.category = cat
        let near = makeDeadline(title: "Near", dueDate: now.addingTimeInterval(2 * 86400))
        near.category = cat
        cat.deadlines = [far, near]

        let result = DeadlineQueryService.mostUrgentDeadline(in: cat, now: now)
        #expect(result?.title == "Near")
    }

    @Test("Higher priority wins when due dates are equal")
    func priorityTieBreak() {
        let cat = makeCategory()
        let now = Date()
        let dueDate = now.addingTimeInterval(5 * 86400)
        let low = makeDeadline(title: "Low", dueDate: dueDate, priority: .low)
        low.category = cat
        let high = makeDeadline(title: "High", dueDate: dueDate, priority: .high)
        high.category = cat
        cat.deadlines = [low, high]

        let result = DeadlineQueryService.mostUrgentDeadline(in: cat, now: now)
        #expect(result?.title == "High")
    }

    @Test("Empty category returns nil")
    func emptyCategory() {
        let cat = makeCategory()
        cat.deadlines = []
        let result = DeadlineQueryService.mostUrgentDeadline(in: cat)
        #expect(result == nil)
    }
}

@Suite("ProgressCalculator Tests")
struct ProgressCalculatorTests {

    @Test("Manual progress returned")
    func manualProgress() {
        let d = DDDeadline(title: "Test", dueDate: Date(), progressMode: .manual, manualProgress: 0.65)
        let result = ProgressCalculator.progress(for: d)
        #expect(abs(result - 0.65) < 0.001)
    }

    @Test("Checklist progress calculated correctly")
    func checklistProgress() {
        let d = DDDeadline(title: "Test", dueDate: Date(), progressMode: .checklist)
        let item1 = DDActionItem(title: "A", isCompleted: true)
        item1.deadline = d
        let item2 = DDActionItem(title: "B", isCompleted: false)
        item2.deadline = d
        let item3 = DDActionItem(title: "C", isCompleted: true)
        item3.deadline = d
        let item4 = DDActionItem(title: "D", isCompleted: false)
        item4.deadline = d
        d.actionItems = [item1, item2, item3, item4]

        let result = ProgressCalculator.progress(for: d)
        #expect(abs(result - 0.5) < 0.001)
    }

    @Test("Empty checklist returns 0")
    func emptyChecklist() {
        let d = DDDeadline(title: "Test", dueDate: Date(), progressMode: .checklist)
        d.actionItems = []
        let result = ProgressCalculator.progress(for: d)
        #expect(result == 0.0)
    }

    @Test("Completed deadline always returns 1.0")
    func completedReturnsOne() {
        let d = DDDeadline(title: "Test", dueDate: Date(), progressMode: .manual, manualProgress: 0.3)
        d.status = .completed
        let result = ProgressCalculator.progress(for: d)
        #expect(result == 1.0)
    }

    @Test("All items completed detection")
    func allItemsCompleted() {
        let d = DDDeadline(title: "Test", dueDate: Date(), progressMode: .checklist)
        let item1 = DDActionItem(title: "A", isCompleted: true)
        let item2 = DDActionItem(title: "B", isCompleted: true)
        d.actionItems = [item1, item2]

        #expect(ProgressCalculator.allActionItemsCompleted(d) == true)
    }
}

@Suite("UrgencyCalculator Tests")
struct UrgencyCalculatorTests {
    private let now = Date()

    @Test("Overdue returns overdue level")
    func overdue() {
        let result = UrgencyCalculator.urgency(for: now.addingTimeInterval(-86400), status: .inProgress, now: now)
        #expect(result == .overdue)
    }

    @Test("Less than 24h returns critical")
    func critical() {
        let result = UrgencyCalculator.urgency(for: now.addingTimeInterval(12 * 3600), status: .inProgress, now: now)
        #expect(result == .critical)
    }

    @Test("1-7 days returns urgent")
    func urgent() {
        let result = UrgencyCalculator.urgency(for: now.addingTimeInterval(3 * 86400), status: .inProgress, now: now)
        #expect(result == .urgent)
    }

    @Test("8-30 days returns warning")
    func warning() {
        let result = UrgencyCalculator.urgency(for: now.addingTimeInterval(15 * 86400), status: .inProgress, now: now)
        #expect(result == .warning)
    }

    @Test("Over 30 days returns normal")
    func normal() {
        let result = UrgencyCalculator.urgency(for: now.addingTimeInterval(60 * 86400), status: .inProgress, now: now)
        #expect(result == .normal)
    }

    @Test("Completed returns none")
    func completed() {
        let result = UrgencyCalculator.urgency(for: now.addingTimeInterval(-86400), status: .completed, now: now)
        #expect(result == .none)
    }
}

@Suite("DateFormatService Tests")
struct DateFormatServiceTests {
    private let now = Date()

    @Test("Overdue shows days")
    func overdueText() {
        let result = DateFormatService.relativeText(from: now.addingTimeInterval(-3 * 86400), now: now)
        #expect(result == "逾期 3 天")
    }

    @Test("Tomorrow shows correct text")
    func tomorrowText() {
        let result = DateFormatService.relativeText(from: now.addingTimeInterval(1.5 * 86400), now: now)
        #expect(result == "明天截止")
    }

    @Test("Multiple days shows count")
    func multipleDays() {
        let result = DateFormatService.relativeText(from: now.addingTimeInterval(12 * 86400), now: now)
        #expect(result == "还有 12 天")
    }

    @Test("Progress text formats correctly")
    func progressText() {
        #expect(DateFormatService.progressText(0.6) == "60%")
        #expect(DateFormatService.progressText(0.0) == "0%")
        #expect(DateFormatService.progressText(1.0) == "100%")
    }

    @Test("Action item count text")
    func actionItemText() {
        #expect(DateFormatService.actionItemCountText(completed: 2, total: 5) == "2/5 项")
    }
}
