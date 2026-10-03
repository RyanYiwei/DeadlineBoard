import SwiftUI

struct CategoryCardView: View {
    let category: DDCategory

    private var mostUrgent: DDDeadline? {
        DeadlineQueryService.mostUrgentDeadline(in: category)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: category.iconName)
                    .foregroundStyle(category.color)
                Text(category.name)
                    .font(.headline)
                Spacer()
            }

            if let deadline = mostUrgent {
                deadlineInfo(deadline)
            } else {
                Text("暂无待办 DDL")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func deadlineInfo(_ deadline: DDDeadline) -> some View {
        let urgency = UrgencyCalculator.urgency(for: deadline.dueDate, status: deadline.status, thresholds: .fromUserDefaults)

        VStack(alignment: .leading, spacing: 4) {
            Text(deadline.title)
                .font(.subheadline)
                .lineLimit(1)

            HStack(spacing: 8) {
                Text(DateFormatService.relativeText(from: deadline.dueDate))
                    .font(.caption)
                    .foregroundStyle(urgency.color)

                Text(DateFormatService.shortDateText(from: deadline.dueDate))
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Spacer()

                ProgressView(value: deadline.progress)
                    .frame(width: 60)

                Text(DateFormatService.progressText(deadline.progress))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if deadline.progressMode == .checklist {
                let completed = deadline.actionItems.filter(\.isCompleted).count
                let total = deadline.actionItems.count
                if total > 0 {
                    Text(DateFormatService.actionItemCountText(completed: completed, total: total))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
