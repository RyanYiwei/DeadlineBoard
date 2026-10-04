import SwiftUI

struct CategoryCardView: View {
    let category: DDCategory
    let isSelected: Bool

    private var pal: CategoryPalette { category.palette }

    private var mostUrgent: DDDeadline? {
        DeadlineQueryService.mostUrgentDeadline(in: category)
    }

    private var doneCount: Int {
        category.deadlines.filter { $0.status == .completed }.count
    }

    private var totalCount: Int {
        category.deadlines.count
    }

    private var avgProgress: Int {
        guard totalCount > 0 else { return 0 }
        let sum = category.deadlines.reduce(0.0) { $0 + ($1.status == .completed ? 1.0 : $1.progress) }
        return Int((sum / Double(totalCount)) * 100)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Circle()
                    .fill(pal.tint)
                    .frame(width: 30, height: 30)
                    .overlay {
                        Image(systemName: category.iconName)
                            .font(.system(size: 13))
                            .foregroundStyle(pal.deep)
                    }

                Text(category.name)
                    .font(.system(size: 16, weight: .bold))
                    .tracking(-0.1)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)

                Spacer(minLength: 4)

                Text("\(doneCount)/\(totalCount)")
                    .font(.system(size: 12, weight: .semibold).monospacedDigit())
                    .foregroundStyle(Theme.textSecondary)
            }

            if let deadline = mostUrgent {
                nextDeadlineInfo(deadline)
            } else {
                Text("没有进行中的截止")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.leading, 40)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isSelected ? Color(hex: "#FFFDF6")!.opacity(0.7) : Color.clear)
                .shadow(color: isSelected ? pal.base.opacity(0.33) : .clear, radius: isSelected ? 4 : 0)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isSelected ? pal.base.opacity(0.53) : .clear, lineWidth: 1.5)
                )
        )
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func nextDeadlineInfo(_ deadline: DDDeadline) -> some View {
        let urgency = UrgencyCalculator.urgency(for: deadline.dueDate, status: deadline.status, thresholds: .fromUserDefaults)

        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 8) {
                Text(deadline.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.textDark)
                    .lineLimit(1)

                Spacer(minLength: 4)

                Text(DateFormatService.shortDateText(from: deadline.dueDate))
                    .font(.system(size: 11).monospacedDigit())
                    .foregroundStyle(Theme.textSecondary)
            }

            HStack(spacing: 8) {
                Text(DateFormatService.relativeText(from: deadline.dueDate))
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(urgency.badgeBg))
                    .foregroundStyle(urgency.color)

                ThemeProgressBar(value: deadline.progress, tint: pal.base, height: 4)

                Text("\(avgProgress)%")
                    .font(.system(size: 11, weight: .semibold).monospacedDigit())
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize()
                    .frame(minWidth: 28, alignment: .trailing)
            }
        }
        .padding(.leading, 40)
    }
}
