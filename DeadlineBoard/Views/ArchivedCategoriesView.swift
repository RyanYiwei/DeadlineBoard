import SwiftUI
import SwiftData
import WidgetKit
import UserNotifications

struct ArchivedCategoriesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<DDCategory> { $0.isArchived },
           sort: \DDCategory.name)
    private var archivedCategories: [DDCategory]

    @State private var categoryToDelete: DDCategory?
    @State private var showSaveError = false

    var body: some View {
        NavigationStack {
            List {
                if archivedCategories.isEmpty {
                    ContentUnavailableView(
                        "没有归档分类",
                        systemImage: "archivebox",
                        description: Text("归档的分类会显示在这里")
                    )
                } else {
                    ForEach(archivedCategories) { category in
                        HStack {
                            Image(systemName: category.iconName)
                                .foregroundStyle(category.color)
                            Text(category.name)
                            Spacer()
                            Button("恢复") {
                                category.isArchived = false
                                modelContext.saveAndReloadWidgets()
                            }
                        }
                        .contextMenu {
                            Button("恢复") {
                                category.isArchived = false
                                modelContext.saveAndReloadWidgets()
                            }
                            Divider()
                            Button("永久删除", role: .destructive) {
                                categoryToDelete = category
                            }
                        }
                    }
                    .onDelete { indexSet in
                        if let index = indexSet.first {
                            categoryToDelete = archivedCategories[index]
                        }
                    }
                }
            }
            .frame(minWidth: 350, minHeight: 300)
            .navigationTitle("归档分类")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
            .alert("确认永久删除", isPresented: Binding(
                get: { categoryToDelete != nil },
                set: { if !$0 { categoryToDelete = nil } }
            )) {
                Button("取消", role: .cancel) { categoryToDelete = nil }
                Button("删除", role: .destructive) {
                    if let cat = categoryToDelete {
                        let notificationIds = cat.deadlines.flatMap { $0.reminderRules.map(\.notificationIdentifier) }
                        modelContext.delete(cat)
                        categoryToDelete = nil
                        if modelContext.saveAndReloadWidgets() {
                            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: notificationIds)
                        } else {
                            showSaveError = true
                        }
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
    }
}
