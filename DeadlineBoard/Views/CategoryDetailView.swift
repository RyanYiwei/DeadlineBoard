import SwiftUI
import SwiftData
import WidgetKit

struct CategoryDetailView: View {
    @Bindable var category: DDCategory
    @Environment(\.modelContext) private var modelContext
    @State private var showingNewDeadline = false
    @State private var navigationPath = NavigationPath()
    @AppStorage("showCompleted") private var showCompleted = true

    @Binding var initialDeadline: DDDeadline?

    private var groups: DeadlineGroups {
        DeadlineQueryService.groupedDeadlines(for: category)
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            List {
                if !groups.overdue.isEmpty {
                    Section("逾期") {
                        ForEach(groups.overdue) { deadline in
                            NavigationLink(value: deadline) {
                                DeadlineRowView(deadline: deadline)
                            }
                        }
                    }
                }

                if !groups.inProgress.isEmpty {
                    Section("进行中") {
                        ForEach(groups.inProgress) { deadline in
                            NavigationLink(value: deadline) {
                                DeadlineRowView(deadline: deadline)
                            }
                        }
                    }
                }

                if !groups.upcoming.isEmpty {
                    Section("即将开始") {
                        ForEach(groups.upcoming) { deadline in
                            NavigationLink(value: deadline) {
                                DeadlineRowView(deadline: deadline)
                            }
                        }
                    }
                }

                if showCompleted && !groups.completed.isEmpty {
                    Section("已完成") {
                        ForEach(groups.completed) { deadline in
                            NavigationLink(value: deadline) {
                                DeadlineRowView(deadline: deadline)
                            }
                        }
                    }
                }

                if groups.overdue.isEmpty && groups.inProgress.isEmpty &&
                   groups.upcoming.isEmpty && (!showCompleted || groups.completed.isEmpty) {
                    ContentUnavailableView(
                        "暂无 DDL",
                        systemImage: "checkmark.circle",
                        description: Text("点击 + 创建新的 DDL")
                    )
                }
            }
            .navigationTitle(category.name)
            .navigationDestination(for: DDDeadline.self) { deadline in
                DeadlineEditorView(deadline: deadline)
            }
            .toolbar {
                ToolbarItem {
                    Button(action: { showingNewDeadline = true }) {
                        Label("新建 DDL", systemImage: "plus")
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
}

struct NewDeadlineSheet: View {
    let category: DDCategory
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var dueDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var priority: DeadlinePriority = .normal
    @State private var progressMode: ProgressMode = .manual
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("标题", text: $title)

                DatePicker("截止时间", selection: $dueDate)

                Picker("优先级", selection: $priority) {
                    ForEach(DeadlinePriority.allCases, id: \.self) { p in
                        Text(p.label).tag(p)
                    }
                }

                Picker("进度模式", selection: $progressMode) {
                    Text("手动").tag(ProgressMode.manual)
                    Text("行动项").tag(ProgressMode.checklist)
                }

                TextField("备注", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
            }
            .padding()
            .frame(minWidth: 400, minHeight: 300)
            .navigationTitle("新建 DDL")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("创建") {
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
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
