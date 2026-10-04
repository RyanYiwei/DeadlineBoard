import SwiftUI
import SwiftData

struct HomePageView: View {
    @Query(filter: #Predicate<DDDeadline> { $0.statusRaw != "completed" },
           sort: \DDDeadline.dueDate)
    private var activeDeadlines: [DDDeadline]

    var body: some View {
        ScrollView {
            if activeDeadlines.isEmpty {
                emptyState
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("时间轴")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Theme.textDark)
                        Text("· \(activeDeadlines.count) 个待办")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textSecondary)
                        Spacer()
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 24)
                    .padding(.bottom, 20)

                    let groups = groupedDeadlines
                    ForEach(Array(groups.enumerated()), id: \.offset) { index, group in
                        timelineSection(
                            date: group.date,
                            deadlines: group.deadlines,
                            isLast: index == groups.count - 1
                        )
                    }

                    Spacer(minLength: 40)
                }
            }
        }
        .background(Theme.background)
    }

    // MARK: - Timeline Section

    private func timelineSection(date: Date, deadlines: [DDDeadline], isLast: Bool) -> some View {
        let calendar = Calendar.current
        let isOverdue = date < calendar.startOfDay(for: Date())
        let isToday = calendar.isDateInToday(date)

        return HStack(alignment: .top, spacing: 0) {
            VStack(spacing: 1) {
                Text(monthText(date))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(isOverdue ? Theme.overdueFg : Theme.textSecondary)
                Text(dayText(date))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(isOverdue ? Theme.overdueFg : Theme.textDark)
                Text(DateFormatService.weekdayText(from: date))
                    .font(.system(size: 9))
                    .foregroundStyle(isToday ? Theme.urgentFg : Theme.textTertiary)
            }
            .frame(width: 48)

            ZStack(alignment: .top) {
                if !isLast {
                    Theme.textTertiary.opacity(0.2)
                        .frame(width: 1.5)
                        .padding(.top, 6)
                }
                Circle()
                    .fill(isOverdue ? Theme.overdueFg : (isToday ? Theme.urgentFg : Theme.textTertiary.opacity(0.4)))
                    .frame(width: 7, height: 7)
                    .padding(.top, 6)
            }
            .frame(width: 20)

            VStack(alignment: .leading, spacing: 4) {
                ForEach(deadlines) { deadline in
                    timelineRow(deadline)
                }
            }
            .padding(.leading, 8)
            .padding(.trailing, 28)
            .padding(.bottom, isLast ? 0 : 32)
        }
        .padding(.leading, 28)
    }

    private func timelineRow(_ deadline: DDDeadline) -> some View {
        let urgency = UrgencyCalculator.urgency(for: deadline.dueDate, status: deadline.status)

        return HStack(spacing: 6) {
            if let category = deadline.category {
                Image(systemName: category.iconName)
                    .font(.system(size: 9))
                    .foregroundStyle(category.palette.base)
            }

            Text(deadline.title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.textDark)
                .lineLimit(1)

            if let category = deadline.category {
                Text(category.name)
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.textTertiary)
                    .lineLimit(1)
            }

            Spacer()

            Text(DateFormatService.relativeText(from: deadline.dueDate))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(urgency.color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(urgency == .overdue || urgency == .critical
                      ? Theme.overdueRowBg.opacity(0.4)
                      : Theme.cardBg)
        )
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 32))
                .foregroundStyle(Theme.calmFg)
            Text("没有待处理的截止日")
                .font(.system(size: 14))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private var groupedDeadlines: [(date: Date, deadlines: [DDDeadline])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: activeDeadlines) {
            calendar.startOfDay(for: $0.dueDate)
        }
        return grouped.sorted { $0.key < $1.key }
            .map { (date: $0.key, deadlines: $0.value) }
    }

    private func monthText(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M月"
        return f.string(from: date)
    }

    private func dayText(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f.string(from: date)
    }
}
