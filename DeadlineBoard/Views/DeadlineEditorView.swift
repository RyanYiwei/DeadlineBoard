import SwiftUI
import SwiftData
import WidgetKit
import UserNotifications

struct DeadlineEditorView: View {
    @Bindable var deadline: DDDeadline
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<DDCategory> { !$0.isArchived },
           sort: \DDCategory.sortOrder) private var activeCategories: [DDCategory]

    @State private var newActionItemTitle = ""
    @State private var showDeleteConfirm = false
    @State private var showCustomReminderPicker = false
    @State private var customReminderDate = Date().addingTimeInterval(86400)
    @State private var isDeleted = false
    @State private var showSaveError = false

    var body: some View {
        Form {
            Section("基本信息") {
                TextField("标题", text: $deadline.title)

                Picker("分类", selection: $deadline.category) {
                    ForEach(activeCategories) { cat in
                        Label(cat.name, systemImage: cat.iconName)
                            .tag(cat as DDCategory?)
                    }
                }
                .onChange(of: deadline.category) {
                    if modelContext.saveAndReloadWidgets() {
                        NotificationService.shared.rescheduleAllReminders(for: deadline)
                    }
                }

                DatePicker("截止时间", selection: $deadline.dueDate)
                    .onChange(of: deadline.dueDate) {
                        if modelContext.saveAndReloadWidgets() {
                            NotificationService.shared.rescheduleAllReminders(for: deadline)
                        }
                    }

                Picker("优先级", selection: Binding(
                    get: { deadline.priority },
                    set: { deadline.priority = $0 }
                )) {
                    ForEach(DeadlinePriority.allCases, id: \.self) { p in
                        Text(p.label).tag(p)
                    }
                }
                .onChange(of: deadline.priority) {
                    modelContext.saveAndReloadWidgets()
                }

                Picker("状态", selection: Binding(
                    get: { deadline.status },
                    set: { newStatus in
                        if newStatus == .completed {
                            deadline.markCompleted()
                            if modelContext.saveAndReloadWidgets() {
                                NotificationService.shared.cancelReminders(for: deadline)
                            }
                        } else if deadline.status == .completed && newStatus != .completed {
                            deadline.markIncomplete()
                            if newStatus != .inProgress {
                                deadline.status = newStatus
                            }
                            if modelContext.saveAndReloadWidgets() {
                                NotificationService.shared.rescheduleAllReminders(for: deadline)
                            }
                        } else {
                            deadline.status = newStatus
                            modelContext.saveAndReloadWidgets()
                        }
                    }
                )) {
                    Text("未开始").tag(DeadlineStatus.notStarted)
                    Text("进行中").tag(DeadlineStatus.inProgress)
                    Text("已完成").tag(DeadlineStatus.completed)
                }
            }

            Section("进度") {
                Picker("进度模式", selection: Binding(
                    get: { deadline.progressMode },
                    set: { newMode in
                        deadline.progressMode = newMode
                        recheckCompletionState()
                        modelContext.saveAndReloadWidgets()
                    }
                )) {
                    Text("手动").tag(ProgressMode.manual)
                    Text("行动项").tag(ProgressMode.checklist)
                }

                if deadline.progressMode == .manual && deadline.status != .completed {
                    HStack {
                        Slider(value: $deadline.manualProgress, in: 0...1, step: 0.05,
                               onEditingChanged: { editing in
                            if !editing {
                                modelContext.saveAndReloadWidgets()
                            }
                        })
                        Text(DateFormatService.progressText(deadline.manualProgress))
                            .frame(width: 40, alignment: .trailing)
                            .monospacedDigit()
                    }
                } else {
                    HStack {
                        Text("当前进度")
                        Spacer()
                        Text(DateFormatService.progressText(deadline.progress))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if deadline.progressMode == .checklist {
                Section("行动项") {
                    actionItemsList
                    addActionItemRow
                }
            }

            Section("提醒") {
                remindersList
                addReminderButton
            }

            Section("备注") {
                TextEditor(text: $deadline.notes)
                    .frame(minHeight: 80)
            }

            Section {
                Button("删除此 DDL", role: .destructive) {
                    showDeleteConfirm = true
                }
            }
        }
        .padding()
        .frame(minWidth: 450)
        .navigationTitle(deadline.title)
        .alert("确认删除", isPresented: $showDeleteConfirm) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                let ruleIds = deadline.reminderRules.map(\.notificationIdentifier)
                modelContext.delete(deadline)
                if modelContext.saveAndReloadWidgets() {
                    isDeleted = true
                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ruleIds)
                    dismiss()
                } else {
                    showSaveError = true
                }
            }
        } message: {
            Text("将永久删除「\(deadline.title)」，此操作无法撤销。")
        }
        .alert("保存失败", isPresented: $showSaveError) {
            Button("确定") {}
        } message: {
            Text("数据保存失败，请重试。")
        }
        .sheet(isPresented: $showCustomReminderPicker) {
            customReminderSheet
        }
        .onDisappear {
            guard !isDeleted else { return }
            if modelContext.saveAndReloadWidgets() {
                NotificationService.shared.rescheduleAllReminders(for: deadline)
            }
        }
    }

    private var actionItemsList: some View {
        ForEach(deadline.actionItems.sorted(by: { $0.sortOrder < $1.sortOrder })) { item in
            HStack {
                Button(action: {
                    item.isCompleted.toggle()
                    recheckCompletionState()
                    modelContext.saveAndReloadWidgets()
                }) {
                    Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(item.isCompleted ? .green : .secondary)
                }
                .buttonStyle(.plain)

                TextField("行动项", text: Binding(
                    get: { item.title },
                    set: { item.title = $0 }
                ))
                .strikethrough(item.isCompleted)

                Spacer()

                Button(action: {
                    modelContext.delete(item)
                    recheckCompletionState()
                    modelContext.saveAndReloadWidgets()
                }) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .onMove { source, destination in
            var items = deadline.actionItems.sorted(by: { $0.sortOrder < $1.sortOrder })
            items.move(fromOffsets: source, toOffset: destination)
            for (i, item) in items.enumerated() {
                item.sortOrder = i
            }
            modelContext.saveAndReloadWidgets()
        }
    }

    private var addActionItemRow: some View {
        HStack {
            Image(systemName: "plus.circle")
                .foregroundStyle(.secondary)
            TextField("添加行动项", text: $newActionItemTitle)
                .onSubmit {
                    addActionItem()
                }
            if !newActionItemTitle.isEmpty {
                Button("添加") { addActionItem() }
            }
        }
    }

    private func addActionItem() {
        let trimmed = newActionItemTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let maxOrder = deadline.actionItems.map(\.sortOrder).max() ?? -1
        let item = DDActionItem(title: trimmed, sortOrder: maxOrder + 1)
        item.deadline = deadline
        modelContext.insert(item)
        newActionItemTitle = ""
        recheckCompletionState()
        modelContext.saveAndReloadWidgets()
    }

    private func recheckCompletionState() {
        if deadline.progressMode == .checklist {
            if ProgressCalculator.allActionItemsCompleted(deadline) && deadline.status != .completed {
                deadline.markCompleted()
                NotificationService.shared.cancelReminders(for: deadline)
            } else if deadline.status == .completed && !ProgressCalculator.allActionItemsCompleted(deadline) {
                deadline.markIncomplete()
                NotificationService.shared.rescheduleAllReminders(for: deadline)
            }
        }
    }

    private var remindersList: some View {
        ForEach(deadline.reminderRules) { rule in
            HStack {
                Toggle(isOn: Binding(
                    get: { rule.isEnabled },
                    set: { newValue in
                        rule.isEnabled = newValue
                        do {
                            try modelContext.save()
                            if newValue {
                                NotificationService.shared.scheduleReminders(for: deadline)
                            } else {
                                NotificationService.shared.cancelReminder(rule)
                            }
                        } catch {
                            rule.isEnabled = !newValue
                            showSaveError = true
                        }
                    }
                )) {
                    if let offset = rule.relativeOffset {
                        Text(labelForOffset(offset))
                    } else {
                        Text(DateFormatService.absoluteText(from: rule.triggerDate))
                    }
                }

                Spacer()

                Button(action: {
                    let identifier = rule.notificationIdentifier
                    modelContext.delete(rule)
                    do {
                        try modelContext.save()
                        UNUserNotificationCenter.current()
                            .removePendingNotificationRequests(withIdentifiers: [identifier])
                    } catch {
                        showSaveError = true
                    }
                }) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var addReminderButton: some View {
        Menu("添加提醒") {
            ForEach(AppConstants.DefaultReminderOffsets.all, id: \.offset) { preset in
                Button(preset.label) {
                    let triggerDate = deadline.dueDate.addingTimeInterval(preset.offset)
                    guard triggerDate > Date() else { return }
                    let rule = DDReminderRule(
                        triggerDate: triggerDate,
                        relativeOffset: preset.offset
                    )
                    rule.deadline = deadline
                    modelContext.insert(rule)
                    do {
                        try modelContext.save()
                        NotificationService.shared.scheduleReminders(for: deadline)
                    } catch {
                        showSaveError = true
                    }
                }
                .disabled(deadline.dueDate.addingTimeInterval(preset.offset) <= Date())
            }
            Divider()
            Button("自定义时间…") {
                customReminderDate = Date().addingTimeInterval(86400)
                showCustomReminderPicker = true
            }
        }
    }

    private var customReminderSheet: some View {
        NavigationStack {
            Form {
                DatePicker("提醒时间", selection: $customReminderDate)
            }
            .padding()
            .frame(minWidth: 350, minHeight: 200)
            .navigationTitle("自定义提醒")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { showCustomReminderPicker = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
                        guard customReminderDate > Date() else { return }
                        let rule = DDReminderRule(triggerDate: customReminderDate)
                        rule.deadline = deadline
                        modelContext.insert(rule)
                        do {
                            try modelContext.save()
                            NotificationService.shared.scheduleReminders(for: deadline)
                        } catch {
                            showSaveError = true
                        }
                        showCustomReminderPicker = false
                    }
                    .disabled(customReminderDate <= Date())
                }
            }
        }
    }

    private func labelForOffset(_ offset: TimeInterval) -> String {
        let days = Int(-offset / 86400)
        let hours = Int(-offset / 3600)
        if days > 0 { return "提前 \(days) 天" }
        if hours > 0 { return "提前 \(hours) 小时" }
        return "自定义"
    }
}
