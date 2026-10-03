import SwiftUI
import SwiftData
import WidgetKit
import UserNotifications

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<DDCategory> { !$0.isArchived },
           sort: \DDCategory.sortOrder)
    private var categories: [DDCategory]

    @State private var showingNewCategory = false
    @State private var showingArchived = false
    @State private var editingCategory: DDCategory?
    @State private var selectedCategory: DDCategory?
    @State private var selectedDeadline: DDDeadline?
    @State private var categoryToDelete: DDCategory?
    @State private var showSaveError = false

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            if let category = selectedCategory {
                CategoryDetailView(
                    category: category,
                    initialDeadline: $selectedDeadline
                )
                .id(category.id)
            } else {
                ContentUnavailableView(
                    "选择一个分类",
                    systemImage: "sidebar.left",
                    description: Text("从左侧选择分类查看详情")
                )
            }
        }
        .navigationTitle("Deadline Board")
        .safeAreaInset(edge: .bottom) {
            if !SharedModelContainer.isUsingSharedStore {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                    Text("App Group 不可用，Widget 数据无法同步")
                        .font(.caption)
                }
                .padding(8)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)
            }
        }
        .sheet(isPresented: $showingNewCategory) {
            CategoryEditorView(mode: .create) { name, colorHex, iconName in
                let maxOrder = categories.map(\.sortOrder).max() ?? -1
                let category = DDCategory(
                    name: name,
                    colorHex: colorHex,
                    iconName: iconName,
                    sortOrder: maxOrder + 1
                )
                modelContext.insert(category)
                modelContext.saveAndReloadWidgets()
            }
        }
        .sheet(item: $editingCategory) { category in
            CategoryEditorView(mode: .edit(category)) { name, colorHex, iconName in
                category.name = name
                category.colorHex = colorHex
                category.iconName = iconName
                modelContext.saveAndReloadWidgets()
            }
        }
        .sheet(isPresented: $showingArchived) {
            ArchivedCategoriesView()
        }
        .handleDeepLinks(
            selectedCategory: $selectedCategory,
            selectedDeadline: $selectedDeadline
        )
        .alert("确认删除", isPresented: Binding(
            get: { categoryToDelete != nil },
            set: { if !$0 { categoryToDelete = nil } }
        )) {
            Button("取消", role: .cancel) { categoryToDelete = nil }
            Button("删除", role: .destructive) {
                if let cat = categoryToDelete {
                    deleteCategory(cat)
                }
            }
        } message: {
            if let cat = categoryToDelete {
                let count = cat.deadlines.count
                Text("将永久删除分类「\(cat.name)」及其 \(count) 个 DDL，此操作无法撤销。")
            }
        }
        .alert("保存失败", isPresented: $showSaveError) {
            Button("确定") {}
        } message: {
            Text("数据保存失败，请重试。")
        }
    }

    private var sidebar: some View {
        List(selection: $selectedCategory) {
            if categories.isEmpty {
                emptyState
            } else {
                ForEach(categories) { category in
                    CategoryCardView(category: category)
                        .tag(category)
                        .contextMenu {
                            categoryContextMenu(for: category)
                        }
                }
                .onMove(perform: moveCategories)
            }
        }
        .listStyle(.sidebar)
        .toolbar {
            ToolbarItemGroup {
                Button(action: { showingArchived = true }) {
                    Label("归档", systemImage: "archivebox")
                }
                Button(action: { showingNewCategory = true }) {
                    Label("新建分类", systemImage: "plus")
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("还没有分类")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("点击右上角 + 创建第一个分类")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    @ViewBuilder
    private func categoryContextMenu(for category: DDCategory) -> some View {
        Button("编辑") { editingCategory = category }
        Button("归档") {
            category.isArchived = true
            modelContext.saveAndReloadWidgets()
        }
        Divider()
        Button("删除", role: .destructive) {
            categoryToDelete = category
        }
    }

    private func deleteCategory(_ category: DDCategory) {
        let notificationIds = category.deadlines.flatMap { $0.reminderRules.map(\.notificationIdentifier) }
        if selectedCategory == category {
            selectedCategory = nil
        }
        modelContext.delete(category)
        categoryToDelete = nil
        if modelContext.saveAndReloadWidgets() {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: notificationIds)
        } else {
            showSaveError = true
        }
    }

    private func moveCategories(from source: IndexSet, to destination: Int) {
        var ordered = categories.sorted(by: { $0.sortOrder < $1.sortOrder })
        ordered.move(fromOffsets: source, toOffset: destination)
        for (index, cat) in ordered.enumerated() {
            cat.sortOrder = index
        }
        modelContext.saveAndReloadWidgets()
    }
}
