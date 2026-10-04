import SwiftUI
import WidgetKit
import SwiftData
import AppIntents

struct MultiCategoryWidget: Widget {
    let kind = "MultiCategoryWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SelectCategoriesIntent.self,
            provider: MultiCategoryProvider()
        ) { entry in
            MultiCategoryWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("分类概览")
        .description("展示多个分类的最近 DDL")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct SelectCategoriesIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "选择分类"
    static var description = IntentDescription("选择要显示的分类（最多5个），不选则显示全部")

    @Parameter(title: "分类")
    var categories: [CategoryEntity]?
}

struct CategorySummary: Identifiable {
    let id: String
    let name: String
    let colorHex: String
    let iconName: String
    let deadlineTitle: String?
    let dueDate: Date?
    let deadlineId: String?
}

struct MultiCategoryEntry: TimelineEntry {
    let date: Date
    let summaries: [CategorySummary]
    let isError: Bool

    static var placeholder: MultiCategoryEntry {
        MultiCategoryEntry(date: Date(), summaries: [
            CategorySummary(id: "1", name: "课程 A", colorHex: "#007AFF", iconName: "book.fill",
                          deadlineTitle: "期中报告", dueDate: Date().addingTimeInterval(8*86400), deadlineId: nil),
            CategorySummary(id: "2", name: "课程 B", colorHex: "#34C759", iconName: "pencil.and.ruler.fill",
                          deadlineTitle: "作业 3", dueDate: Date().addingTimeInterval(14*86400), deadlineId: nil),
            CategorySummary(id: "3", name: "课程 C", colorHex: "#FF9500", iconName: "graduationcap.fill",
                          deadlineTitle: "期末考试", dueDate: Date().addingTimeInterval(31*86400), deadlineId: nil),
        ], isError: false)
    }

    static var unavailable: MultiCategoryEntry {
        MultiCategoryEntry(date: Date(), summaries: [], isError: true)
    }
}

struct MultiCategoryProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> MultiCategoryEntry {
        .placeholder
    }

    func snapshot(for configuration: SelectCategoriesIntent, in context: Context) async -> MultiCategoryEntry {
        .placeholder
    }

    @MainActor
    func timeline(for configuration: SelectCategoriesIntent, in context: Context) async -> Timeline<MultiCategoryEntry> {
        guard let container = SharedModelContainer.createForWidget() else {
            return Timeline(entries: [.unavailable], policy: .after(nextMidnight()))
        }

        let modelContext = ModelContext(container)
        let maxItems = 5

        let predicate = #Predicate<DDCategory> { !$0.isArchived }
        let descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\DDCategory.sortOrder)])
        let allCategories = (try? modelContext.fetch(descriptor)) ?? []

        let selectedIds = configuration.categories?.map(\.id) ?? []

        let filtered: [DDCategory]
        if selectedIds.isEmpty {
            filtered = Array(allCategories.prefix(maxItems))
        } else {
            filtered = Array(
                allCategories
                    .filter { selectedIds.contains($0.id.uuidString) }
                    .prefix(maxItems)
            )
        }

        let summaries: [CategorySummary] = filtered.map { cat in
            let urgent = DeadlineQueryService.mostUrgentDeadline(in: cat)
            return CategorySummary(
                id: cat.id.uuidString,
                name: cat.name,
                colorHex: cat.colorHex,
                iconName: cat.iconName,
                deadlineTitle: urgent?.title,
                dueDate: urgent?.dueDate,
                deadlineId: urgent?.id.uuidString
            )
        }

        let entry = MultiCategoryEntry(date: Date(), summaries: summaries, isError: false)

        var nextRefresh = nextMidnight()
        for summary in summaries {
            if let dueDate = summary.dueDate, dueDate < nextRefresh, dueDate > Date() {
                nextRefresh = dueDate
            }
        }

        return Timeline(entries: [entry], policy: .after(nextRefresh))
    }
}

struct MultiCategoryWidgetView: View {
    let entry: MultiCategoryEntry

    var body: some View {
        if entry.isError {
            VStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("需要配置 App Group")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } else if entry.summaries.isEmpty {
            VStack {
                Image(systemName: "tray")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("还没有分类")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } else {
            VStack(spacing: 0) {
                ForEach(Array(entry.summaries.enumerated()), id: \.element.id) { index, summary in
                    if index > 0 {
                        Divider().padding(.horizontal, 4)
                    }

                    let deepLink = URL(string: "\(AppConstants.deepLinkScheme)://category/\(summary.id)")!
                    Link(destination: deepLink) {
                        HStack(spacing: 8) {
                            Image(systemName: summary.iconName)
                                .font(.caption)
                                .foregroundStyle(Color(hex: summary.colorHex) ?? .blue)
                                .frame(width: 16)

                            Text(summary.name)
                                .font(.caption.weight(.medium))
                                .lineLimit(1)
                                .frame(width: 60, alignment: .leading)

                            if let title = summary.deadlineTitle {
                                Text(title)
                                    .font(.caption)
                                    .lineLimit(1)

                                Spacer()

                                if let dueDate = summary.dueDate {
                                    Text(DateFormatService.relativeText(from: dueDate))
                                        .font(.caption2)
                                        .foregroundStyle(
                                            UrgencyCalculator.urgency(for: dueDate, status: .notStarted, thresholds: .fromUserDefaults).color
                                        )
                                }
                            } else {
                                Text("暂无")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: .infinity)
                }
            }
        }
    }
}

private func nextMidnight() -> Date {
    Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
}
