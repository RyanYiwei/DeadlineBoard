import SwiftUI
import SwiftData
import WidgetKit
import UserNotifications

struct DeadlineRowView: View {
    let deadline: DDDeadline
    let palette: CategoryPalette
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    let onNavigateToEditor: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var showDeleteConfirm = false
    @State private var showSaveError = false

    private var urgency: UrgencyLevel {
        UrgencyCalculator.urgency(for: deadline.dueDate, status: deadline.status, thresholds: .fromUserDefaults)
    }

    private var isOverdue: Bool {
        urgency == .overdue || urgency == .critical
    }

    var body: some View {
        VStack(spacing: 0) {
            mainRow
            if isExpanded {
                expandedSection
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(rowBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(rowBorder, lineWidth: 1)
                )
        )
        .alert("确认删除", isPresented: $showDeleteConfirm) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) { deleteDeadline() }
        } message: {
            Text("将永久删除「\(deadline.title)」，此操作无法撤销。")
        }
        .alert("保存失败", isPresented: $showSaveError) {
            Button("确定") {}
        } message: {
            Text("数据保存失败，请重试。")
        }
    }

    private var rowBackground: Color {
        if isExpanded { return Theme.cardBgActive }
        if isOverdue { return Theme.overdueRowBg }
        return Theme.cardBg
    }

    private var rowBorder: Color {
        if isExpanded { return Theme.cardBorderActive }
        if isOverdue { return Theme.overdueRowBorder }
        return Theme.cardBorder
    }

    // MARK: - Main Row

    private var mainRow: some View {
        HStack(spacing: 14) {
            completionButton

            Button(action: onToggleExpand) {
                HStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(deadline.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                            .lineLimit(1)

                        HStack(spacing: 10) {
                            HStack(spacing: 4) {
                                if isOverdue || urgency == .urgent {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 10))
                                }
                                Text(DateFormatService.relativeText(from: deadline.dueDate))
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .foregroundStyle(urgency.color)

                            Text("·")
                                .foregroundStyle(Theme.textTertiary)

                            HStack(spacing: 4) {
                                Text(DateFormatService.shortDateText(from: deadline.dueDate))
                                Text(DateFormatService.weekdayText(from: deadline.dueDate))
                            }
                            .font(.system(size: 12).monospacedDigit())
                            .foregroundStyle(Theme.textSecondary)
                        }
                    }

                    Spacer(minLength: 4)

                    HStack(spacing: 10) {
                        ThemeProgressBar(
                            value: deadline.progress,
                            tint: isOverdue ? Color(hex: "#C09590")! : palette.base,
                            height: 6
                        )
                        .frame(width: 120)

                        Text(DateFormatService.progressText(deadline.progress))
                            .font(.system(size: 13, weight: .bold).monospacedDigit())
                            .foregroundStyle(Theme.textDark)
                            .frame(width: 36, alignment: .trailing)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 15)
    }

    private var completionButton: some View {
        Button(action: toggleCompletion) {
            Circle()
                .stroke(palette.base, lineWidth: 1.75)
                .frame(width: 22, height: 22)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Expanded

    private var expandedSection: some View {
        HStack(spacing: 12) {
            Text("进度")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)

            if deadline.progressMode == .manual {
                Slider(
                    value: Binding(
                        get: { deadline.manualProgress },
                        set: { newVal in
                            deadline.manualProgress = newVal
                        }
                    ),
                    in: 0...1,
                    step: 0.05,
                    onEditingChanged: { editing in
                        if !editing {
                            modelContext.saveAndReloadWidgets()
                        }
                    }
                )
                .frame(maxWidth: 320)
                .tint(palette.base)
            } else {
                let completed = deadline.actionItems.filter(\.isCompleted).count
                let total = deadline.actionItems.count
                Text("\(completed)/\(total) 项")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer()

            Button(action: onNavigateToEditor) {
                Text("编辑")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(palette.deep)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .stroke(palette.base.opacity(0.4), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)

            Button(action: { showDeleteConfirm = true }) {
                Text("删除")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.overdueFg)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .stroke(Theme.overdueFg.opacity(0.25), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, 54)
        .padding(.trailing, 18)
        .padding(.bottom, 14)
        .padding(.top, 4)
    }

    // MARK: - Actions

    private func toggleCompletion() {
        if deadline.status == .completed {
            deadline.markIncomplete()
            if modelContext.saveAndReloadWidgets() {
                NotificationService.shared.rescheduleAllReminders(for: deadline)
            }
        } else {
            deadline.markCompleted()
            if modelContext.saveAndReloadWidgets() {
                NotificationService.shared.cancelReminders(for: deadline)
            }
        }
    }

    private func deleteDeadline() {
        let ruleIds = deadline.reminderRules.map(\.notificationIdentifier)
        modelContext.delete(deadline)
        if modelContext.saveAndReloadWidgets() {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ruleIds)
        } else {
            showSaveError = true
        }
    }
}
