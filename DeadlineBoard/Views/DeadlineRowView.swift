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
    @State private var newItemTitle = ""

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
                .padding(8)
                .contentShape(Circle().inset(by: -8))
        }
        .buttonStyle(.plain)
        .padding(-8)
    }

    // MARK: - Expanded

    private var expandedSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            if deadline.progressMode == .manual {
                HStack(spacing: 12) {
                    Text("进度")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                    Slider(
                        value: Binding(
                            get: { deadline.manualProgress },
                            set: { deadline.manualProgress = $0 }
                        ),
                        in: 0...1,
                        step: 0.05,
                        onEditingChanged: { editing in
                            if !editing { modelContext.saveAndReloadWidgets() }
                        }
                    )
                    .frame(maxWidth: 320)
                    .tint(palette.base)
                    Spacer()
                }
                .padding(.bottom, 10)
            } else {
                checklistSection
                    .padding(.bottom, 10)
            }

            HStack(spacing: 12) {
                Spacer()

                Button(action: onNavigateToEditor) {
                    Text("编辑")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(palette.deep)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().stroke(palette.base.opacity(0.4), lineWidth: 1))
                }
                .buttonStyle(.plain)

                Button(action: { showDeleteConfirm = true }) {
                    Text("删除")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.overdueFg)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().stroke(Theme.overdueFg.opacity(0.25), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.leading, 54)
        .padding(.trailing, 18)
        .padding(.bottom, 14)
        .padding(.top, 4)
    }

    // MARK: - Checklist

    private var pendingItems: [DDActionItem] {
        deadline.actionItems.filter { !$0.isCompleted }.sorted { $0.sortOrder < $1.sortOrder }
    }

    private var doneItems: [DDActionItem] {
        deadline.actionItems.filter { $0.isCompleted }.sorted { $0.sortOrder < $1.sortOrder }
    }

    private var checklistSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text("行动项")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
                Text("\(doneItems.count)/\(deadline.actionItems.count)")
                    .font(.system(size: 12).monospacedDigit())
                    .foregroundStyle(Theme.textTertiary)
            }

            ForEach(pendingItems) { item in
                actionItemRow(item)
            }

            HStack(spacing: 10) {
                Image(systemName: "plus")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(palette.base)
                    .frame(width: 16, height: 16)

                TextField("添加行动项…", text: $newItemTitle)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                    .onSubmit { addActionItem() }
            }
            .padding(.vertical, 2)

            if !doneItems.isEmpty && !pendingItems.isEmpty {
                Divider().opacity(0.3).padding(.vertical, 4)
            }

            if !doneItems.isEmpty {
                HStack(spacing: 4) {
                    Text("已完成")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.textTertiary)
                    Text("\(doneItems.count)")
                        .font(.system(size: 11).monospacedDigit())
                        .foregroundStyle(Theme.textTertiary)
                }

                ForEach(doneItems) { item in
                    actionItemRow(item)
                }
            }
        }
    }

    private func actionItemRow(_ item: DDActionItem) -> some View {
        HStack(spacing: 10) {
            Button {
                item.isCompleted.toggle()
                modelContext.saveAndReloadWidgets()
            } label: {
                Group {
                    if item.isCompleted {
                        Circle()
                            .fill(palette.base)
                            .frame(width: 16, height: 16)
                            .overlay {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(Theme.background)
                            }
                    } else {
                        Circle()
                            .stroke(palette.base, lineWidth: 1.5)
                            .frame(width: 16, height: 16)
                    }
                }
                .padding(4)
                .contentShape(Circle().inset(by: -4))
            }
            .buttonStyle(.plain)
            .padding(-4)

            Text(item.title)
                .font(.system(size: 12, weight: item.isCompleted ? .regular : .medium))
                .foregroundStyle(item.isCompleted ? Theme.textTertiary : Theme.textDark)
                .strikethrough(item.isCompleted, color: Theme.textTertiary)
                .lineLimit(1)

            Spacer()

            Button {
                modelContext.delete(item)
                modelContext.saveAndReloadWidgets()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(Theme.textTertiary)
                    .padding(4)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 2)
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

    private func addActionItem() {
        let title = newItemTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return }
        let maxOrder = deadline.actionItems.map(\.sortOrder).max() ?? -1
        let item = DDActionItem(title: title, sortOrder: maxOrder + 1)
        item.deadline = deadline
        modelContext.insert(item)
        modelContext.saveAndReloadWidgets()
        newItemTitle = ""
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
