import SwiftUI
import WidgetKit
import SwiftData
import AppIntents

struct CategoryEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "分类")
    static var defaultQuery = CategoryEntityQuery()

    var id: String
    var displayName: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(displayName)")
    }
}

struct CategoryEntityQuery: EntityQuery {
    @MainActor
    func entities(for identifiers: [String]) async throws -> [CategoryEntity] {
        guard let container = SharedModelContainer.createForWidget() else { return [] }
        let modelContext = ModelContext(container)
        let predicate = #Predicate<DDCategory> { !$0.isArchived }
        let descriptor = FetchDescriptor(predicate: predicate)
        let categories = (try? modelContext.fetch(descriptor)) ?? []
        return categories
            .filter { identifiers.contains($0.id.uuidString) }
            .map { CategoryEntity(id: $0.id.uuidString, displayName: $0.name) }
    }

    @MainActor
    func suggestedEntities() async throws -> [CategoryEntity] {
        guard let container = SharedModelContainer.createForWidget() else { return [] }
        let modelContext = ModelContext(container)
        let predicate = #Predicate<DDCategory> { !$0.isArchived }
        let descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\DDCategory.sortOrder)])
        let categories = (try? modelContext.fetch(descriptor)) ?? []
        return categories.map { CategoryEntity(id: $0.id.uuidString, displayName: $0.name) }
    }
}

struct SingleCategoryWidget: Widget {
    let kind = "SingleCategoryWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SelectCategoryIntent.self,
            provider: SingleCategoryProvider()
        ) { entry in
            SingleCategoryWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("单分类")
        .description("展示选定分类的最近 DDL")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct SelectCategoryIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "选择分类"
    static var description = IntentDescription("选择要在 Widget 中显示的分类")

    @Parameter(title: "分类")
    var category: CategoryEntity?
}

struct SingleCategoryEntry: TimelineEntry {
    let date: Date
    let categoryName: String
    let categoryColorHex: String
    let categoryIcon: String
    let deadlineTitle: String?
    let dueDate: Date?
    let progress: Double
    let categoryId: String?
    let deadlineId: String?
    let isError: Bool

    static var placeholder: SingleCategoryEntry {
        SingleCategoryEntry(
            date: Date(),
            categoryName: "课程 A",
            categoryColorHex: "#007AFF",
            categoryIcon: "book.fill",
            deadlineTitle: "期中报告",
            dueDate: Date().addingTimeInterval(8 * 86400),
            progress: 0.6,
            categoryId: nil,
            deadlineId: nil,
            isError: false
        )
    }

    static var empty: SingleCategoryEntry {
        SingleCategoryEntry(
            date: Date(),
            categoryName: "未选择",
            categoryColorHex: "#8E8E93",
            categoryIcon: "questionmark.circle",
            deadlineTitle: nil,
            dueDate: nil,
            progress: 0,
            categoryId: nil,
            deadlineId: nil,
            isError: false
        )
    }

    static var unavailable: SingleCategoryEntry {
        SingleCategoryEntry(
            date: Date(),
            categoryName: "数据不可用",
            categoryColorHex: "#8E8E93",
            categoryIcon: "exclamationmark.triangle",
            deadlineTitle: nil,
            dueDate: nil,
            progress: 0,
            categoryId: nil,
            deadlineId: nil,
            isError: true
        )
    }
}

struct SingleCategoryProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SingleCategoryEntry {
        .placeholder
    }

    func snapshot(for configuration: SelectCategoryIntent, in context: Context) async -> SingleCategoryEntry {
        .placeholder
    }

    @MainActor
    func timeline(for configuration: SelectCategoryIntent, in context: Context) async -> Timeline<SingleCategoryEntry> {
        guard let container = SharedModelContainer.createForWidget() else {
            return Timeline(entries: [.unavailable], policy: .after(nextMidnight()))
        }

        let modelContext = ModelContext(container)

        guard let targetId = configuration.category?.id,
              let uuid = UUID(uuidString: targetId) else {
            return Timeline(entries: [.empty], policy: .after(nextMidnight()))
        }

        let predicate = #Predicate<DDCategory> { cat in
            cat.id == uuid && !cat.isArchived
        }
        let descriptor = FetchDescriptor(predicate: predicate)

        guard let category = try? modelContext.fetch(descriptor).first else {
            return Timeline(entries: [.empty], policy: .after(nextMidnight()))
        }

        let mostUrgent = DeadlineQueryService.mostUrgentDeadline(in: category)

        let entry = SingleCategoryEntry(
            date: Date(),
            categoryName: category.name,
            categoryColorHex: category.colorHex,
            categoryIcon: category.iconName,
            deadlineTitle: mostUrgent?.title,
            dueDate: mostUrgent?.dueDate,
            progress: mostUrgent?.progress ?? 0,
            categoryId: category.id.uuidString,
            deadlineId: mostUrgent?.id.uuidString,
            isError: false
        )

        if let dueDate = mostUrgent?.dueDate {
            let refreshDate = min(nextMidnight(), dueDate)
            return Timeline(entries: [entry], policy: .after(refreshDate))
        }

        return Timeline(entries: [entry], policy: .after(nextMidnight()))
    }
}

struct SingleCategoryWidgetView: View {
    let entry: SingleCategoryEntry

    var body: some View {
        if entry.isError {
            VStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("需要配置 App Group")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        } else {
            let deepLink = widgetDeepLink(categoryId: entry.categoryId, deadlineId: entry.deadlineId)

            Link(destination: deepLink) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: entry.categoryIcon)
                            .foregroundStyle(Color(hex: entry.categoryColorHex) ?? .blue)
                        Text(entry.categoryName)
                            .font(.headline)
                            .lineLimit(1)
                    }

                    if let title = entry.deadlineTitle {
                        Text(title)
                            .font(.subheadline)
                            .lineLimit(2)

                        if let dueDate = entry.dueDate {
                            Text(DateFormatService.relativeText(from: dueDate))
                                .font(.caption)
                                .foregroundStyle(
                                    UrgencyCalculator.urgency(for: dueDate, status: .notStarted, thresholds: .fromUserDefaults).color
                                )

                            Text(DateFormatService.shortDateText(from: dueDate))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        ProgressView(value: entry.progress)
                        Text(DateFormatService.progressText(entry.progress))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("暂无待办 DDL")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 0)
                }
            }
        }
    }
}

private func nextMidnight() -> Date {
    Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
}

private func widgetDeepLink(categoryId: String?, deadlineId: String?) -> URL {
    if let deadlineId {
        return URL(string: "\(AppConstants.deepLinkScheme)://deadline/\(deadlineId)")!
    } else if let categoryId {
        return URL(string: "\(AppConstants.deepLinkScheme)://category/\(categoryId)")!
    }
    return URL(string: "\(AppConstants.deepLinkScheme)://")!
}
