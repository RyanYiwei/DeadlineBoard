import SwiftUI
import SwiftData
import WidgetKit

struct CategoryDetailView: View {
    @Bindable var category: DDCategory
    @Environment(\.modelContext) private var modelContext
    @State private var showingNewDeadline = false
    @State private var navigationPath = NavigationPath()
    @State private var expandedId: UUID?
    @State private var showCompleted = true

    @Binding var initialDeadline: DDDeadline?

    private var pal: CategoryPalette { category.palette }

    private var allDeadlines: [DDDeadline] {
        category.deadlines.sorted { a, b in
            if a.dueDate != b.dueDate { return a.dueDate < b.dueDate }
            if a.priority != b.priority { return a.priority > b.priority }
            return a.createdAt < b.createdAt
        }
    }

    private var activeDeadlines: [DDDeadline] {
        allDeadlines.filter { $0.status != .completed }
    }

    private var completedDeadlines: [DDDeadline] {
        allDeadlines.filter { $0.status == .completed }
    }

    private var nearestDeadline: DDDeadline? {
        activeDeadlines.first
    }

    private var urgentCount: Int {
        activeDeadlines.filter { deadline in
            let u = UrgencyCalculator.urgency(for: deadline.dueDate, status: deadline.status, thresholds: .fromUserDefaults)
            return u == .overdue || u == .critical || u == .urgent
        }.count
    }

    private var overallProgress: Int {
        guard !allDeadlines.isEmpty else { return 0 }
        let sum = allDeadlines.reduce(0.0) { $0 + ($1.status == .completed ? 1.0 : $1.progress) }
        return Int((sum / Double(allDeadlines.count)) * 100)
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    headerSection
                    heroSection
                    activeSection
                    completedSection
                    emptySection
                }
                .padding(.horizontal, 40)
                .padding(.top, 10)
                .padding(.bottom, 40)
                .frame(maxWidth: 820, alignment: .leading)
            }
            .frame(maxWidth: .infinity)
            .background(Theme.background)
            .navigationTitle(category.name)
            .navigationDestination(for: DDDeadline.self) { deadline in
                DeadlineEditorView(deadline: deadline)
            }
            .toolbar {
                ToolbarItem {
                    Button(action: { showingNewDeadline = true }) {
                        Label("新建截止", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewDeadline) {
                NewDeadlineSheet(category: category)
            }
            .onAppear {
                if let dl = initialDeadline {
                    navigationPath.append(dl)
                    initialDeadline = nil
                }
            }
            .onChange(of: initialDeadline?.id) { _, newId in
                if let dl = initialDeadline, newId != nil {
                    navigationPath.append(dl)
                    initialDeadline = nil
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(category.name)
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .tracking(-0.4)
                .foregroundStyle(pal.deep)

            if allDeadlines.isEmpty {
                Text("还没有截止事项")
                    .font(.system(size: 20, weight: .medium))
                    .tracking(-0.1)
                    .foregroundStyle(Theme.textTertiary)
            } else {
                let parts = [
                    "\(activeDeadlines.count) 项进行中",
                    urgentCount > 0 ? "\(urgentCount) 项需要关注" : nil,
                    "整体进度 \(overallProgress)%"
                ].compactMap { $0 }

                Text(parts.joined(separator: " · "))
                    .font(.system(size: 20, weight: .medium))
                    .tracking(-0.1)
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .padding(.top, 6)
    }

    // MARK: - Hero

    @ViewBuilder
    private var heroSection: some View {
        if let deadline = nearestDeadline {
            let urgency = UrgencyCalculator.urgency(for: deadline.dueDate, status: deadline.status, thresholds: .fromUserDefaults)
            let parts = DateFormatService.countdownParts(from: deadline.dueDate)

            HStack(spacing: 28) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text("最近截止")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(0.8)
                            .foregroundStyle(pal.deep)

                        if urgency == .overdue || urgency == .critical || urgency == .urgent {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 9))
                                Text(urgency.label)
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(urgency.badgeBg))
                            .foregroundStyle(urgency.color)
                        }
                    }

                    Text(deadline.title)
                        .font(.system(size: 24, weight: .bold))
                        .tracking(-0.15)
                        .lineLimit(2)
                        .foregroundStyle(Theme.textPrimary)

                    Text(DateFormatService.fullDateText(from: deadline.dueDate))
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                countdownDisplay(parts: parts, urgency: urgency)

                Rectangle()
                    .fill(Theme.divider)
                    .frame(width: 1)
                    .padding(.vertical, 4)

                ZStack {
                    ProgressRing(progress: deadline.progress, color: pal.base)

                    VStack(spacing: 1) {
                        Text(DateFormatService.progressText(deadline.progress))
                            .font(.system(size: 18, weight: .bold).monospacedDigit())
                            .foregroundStyle(pal.deep)
                        Text("完成")
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 26)
                    .fill(Theme.heroBg)
                    .overlay(RoundedRectangle(cornerRadius: 26).stroke(Theme.heroBorder, lineWidth: 1))
                    .shadow(color: Color(hex: "#3C4632")!.opacity(0.05), radius: 2, y: 1)
            )
        }
    }

    private func countdownDisplay(parts: DateFormatService.CountdownParts, urgency: UrgencyLevel) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            if !parts.prefix.isEmpty {
                Text(parts.prefix)
                    .font(.system(size: 13, weight: .semibold))
            }
            Text(parts.number)
                .font(.system(size: 64, weight: .bold).monospacedDigit())
                .tracking(-2.5)
                .lineHeightMultiple(0.9)
            Text(parts.unit)
                .font(.system(size: 15, weight: .semibold))
        }
        .foregroundStyle(urgency.color)
    }

    // MARK: - Active

    @ViewBuilder
    private var activeSection: some View {
        if !activeDeadlines.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Text("进行中")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.textDark)
                    Text("\(activeDeadlines.count)")
                        .font(.system(size: 12).monospacedDigit())
                        .foregroundStyle(Theme.textTertiary)
                }
                .padding(.leading, 4)

                VStack(spacing: 6) {
                    ForEach(activeDeadlines) { deadline in
                        DeadlineRowView(
                            deadline: deadline,
                            palette: pal,
                            isExpanded: expandedId == deadline.id,
                            onToggleExpand: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    expandedId = expandedId == deadline.id ? nil : deadline.id
                                }
                            },
                            onNavigateToEditor: {
                                navigationPath.append(deadline)
                            }
                        )
                    }
                }
            }
        }
    }

    // MARK: - Completed

    @ViewBuilder
    private var completedSection: some View {
        if !completedDeadlines.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Button(action: { withAnimation { showCompleted.toggle() } }) {
                    HStack(spacing: 8) {
                        Text("已完成")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Theme.textDark)
                        Text("\(completedDeadlines.count)")
                            .font(.system(size: 12).monospacedDigit())
                            .foregroundStyle(Theme.textTertiary)
                        Text(showCompleted ? "收起" : "展开")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                .buttonStyle(.plain)
                .padding(.leading, 4)

                if showCompleted {
                    VStack(spacing: 4) {
                        ForEach(completedDeadlines) { deadline in
                            completedRow(deadline)
                        }
                    }
                }
            }
        }
    }

    private func completedRow(_ deadline: DDDeadline) -> some View {
        HStack(spacing: 14) {
            Button(action: { restoreDeadline(deadline) }) {
                Circle()
                    .fill(pal.base)
                    .frame(width: 22, height: 22)
                    .overlay {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Theme.background)
                    }
            }
            .buttonStyle(.plain)

            Text(deadline.title)
                .font(.system(size: 14))
                .foregroundStyle(Theme.textSecondary)
                .strikethrough(true, color: Theme.textTertiary)
                .lineLimit(1)

            Spacer()

            Text(DateFormatService.shortDateText(from: deadline.dueDate))
                .font(.system(size: 12).monospacedDigit())
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.clear)
        )
        .contentShape(Rectangle())
    }

    private func restoreDeadline(_ deadline: DDDeadline) {
        deadline.markIncomplete()
        if modelContext.saveAndReloadWidgets() {
            NotificationService.shared.rescheduleAllReminders(for: deadline)
        }
    }

    // MARK: - Empty

    @ViewBuilder
    private var emptySection: some View {
        if allDeadlines.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Circle()
                    .fill(pal.tint)
                    .frame(width: 64, height: 64)
                    .overlay {
                        Image(systemName: "calendar")
                            .font(.system(size: 22))
                            .foregroundStyle(pal.deep)
                    }

                Text("这里还很安静")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Theme.textDark)

                Text("点击右上角「新建截止」添加第一项。")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(.vertical, 40)
            .padding(.leading, 4)
        }
    }
}

// MARK: - New Deadline Sheet

struct NewDeadlineSheet: View {
    let category: DDCategory
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var dueDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var priority: DeadlinePriority = .normal
    @State private var progressMode: ProgressMode = .manual
    @State private var notes = ""
    @FocusState private var titleFocused: Bool

    private var pal: CategoryPalette { category.palette }

    private var canCreate: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var daysUntilDue: Int {
        max(0, Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()), to: Calendar.current.startOfDay(for: dueDate)).day ?? 0)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Title
            HStack {
                Text("新建截止")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)

                Text("· \(category.name)")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(pal.base)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 20)

            // Title field
            VStack(alignment: .leading, spacing: 6) {
                Text("名称")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
                TextField("例如 期中报告", text: $title)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: "#F1EBE0")!)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(titleFocused ? pal.base.opacity(0.6) : Theme.divider, lineWidth: 1)
                            )
                    )
                    .focused($titleFocused)
            }
            .padding(.bottom, 16)

            // Due date
            VStack(alignment: .leading, spacing: 6) {
                Text("截止日期")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
                HStack {
                    DatePicker("", selection: $dueDate, displayedComponents: [.date])
                        .labelsHidden()
                        .datePickerStyle(.field)

                    Spacer()

                    Text(daysUntilDue == 0 ? "今天" : "还有 \(daysUntilDue) 天")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(daysUntilDue <= 3 ? Theme.urgentFg : Theme.calmFg)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule().fill(daysUntilDue <= 3 ? Theme.urgentBg : Theme.calmBg)
                        )
                }
            }
            .padding(.bottom, 16)

            // Priority + Progress mode row
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("优先级")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                    Picker("", selection: $priority) {
                        ForEach(DeadlinePriority.allCases, id: \.self) { p in
                            Text(p.label).tag(p)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .tint(Color(hex: "#D8D2A7"))
                    .frame(width: 160)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("进度模式")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                    Picker("", selection: $progressMode) {
                        Text("手动").tag(ProgressMode.manual)
                        Text("行动项").tag(ProgressMode.checklist)
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .tint(Color(hex: "#D8D2A7"))
                    .frame(width: 140)
                }

                Spacer()
            }
            .padding(.bottom, 16)

            // Notes
            VStack(alignment: .leading, spacing: 6) {
                Text("备注")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
                TextEditor(text: $notes)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textPrimary)
                    .scrollContentBackground(.hidden)
                    .padding(10)
                    .frame(minHeight: 60, maxHeight: 80)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: "#F1EBE0")!)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Theme.divider, lineWidth: 1)
                            )
                    )
            }

            Spacer(minLength: 16)

            // Actions
            HStack(spacing: 8) {
                Spacer()
                Button(action: { dismiss() }) {
                    Text("取消")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.textDark)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().stroke(Theme.divider, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.cancelAction)

                Button(action: createDeadline) {
                    Text("添加")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.background)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(pal.deep))
                        .opacity(canCreate ? 1 : 0.45)
                }
                .buttonStyle(.plain)
                .disabled(!canCreate)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(22)
        .frame(width: 420)
        .background(Theme.background)
        .onAppear { titleFocused = true }
    }

    private func createDeadline() {
        let deadline = DDDeadline(
            title: title,
            dueDate: dueDate,
            notes: notes,
            priority: priority,
            progressMode: progressMode
        )
        deadline.category = category
        modelContext.insert(deadline)
        modelContext.saveAndReloadWidgets()
        dismiss()
    }
}

extension View {
    func lineHeightMultiple(_ multiple: CGFloat) -> some View {
        self
    }
}
