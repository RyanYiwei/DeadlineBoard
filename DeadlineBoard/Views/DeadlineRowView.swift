import SwiftUI
import SwiftData
import WidgetKit

struct DeadlineRowView: View {
    let deadline: DDDeadline
    @Environment(\.modelContext) private var modelContext

    private var urgency: UrgencyLevel {
        UrgencyCalculator.urgency(for: deadline.dueDate, status: deadline.status, thresholds: .fromUserDefaults)
    }

    var body: some View {
        HStack(spacing: 12) {
            completionButton

            VStack(alignment: .leading, spacing: 2) {
                Text(deadline.title)
                    .font(.body)
                    .strikethrough(deadline.status == .completed)
                    .foregroundStyle(deadline.status == .completed ? .secondary : .primary)

                HStack(spacing: 8) {
                    Text(DateFormatService.relativeText(from: deadline.dueDate))
                        .font(.caption)
                        .foregroundStyle(urgency.color)

                    Text(DateFormatService.shortDateText(from: deadline.dueDate))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if deadline.priority == .high {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                ProgressView(value: deadline.progress)
                    .frame(width: 60)
                Text(DateFormatService.progressText(deadline.progress))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private var completionButton: some View {
        Button(action: toggleCompletion) {
            Image(systemName: deadline.status == .completed ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(deadline.status == .completed ? .green : .secondary)
        }
        .buttonStyle(.plain)
    }

    private func toggleCompletion() {
        if deadline.status == .completed {
            deadline.markIncomplete()
            NotificationService.shared.rescheduleAllReminders(for: deadline)
        } else {
            deadline.markCompleted()
            NotificationService.shared.cancelReminders(for: deadline)
        }
        modelContext.saveAndReloadWidgets()
    }
}
