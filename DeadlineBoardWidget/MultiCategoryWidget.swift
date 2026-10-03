import SwiftUI
import WidgetKit
import SwiftData

struct MultiCategoryWidget: Widget {
    let kind = "MultiCategoryWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MultiCategoryProvider()) { entry in
            MultiCategoryWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("分类概览")
        .description("展示多个分类的最近 DDL")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct CategorySummary: Identifiable {
    let id: String
    let name: String
    let colorHex: String
    let iconName: String
    let deadlineTitle: String?
    let dueDate: Date?
    let progress: Double
    let deadlineId: String?
}

struct MultiCategoryEntry: TimelineEntry {
    let date: Date
    let summaries: [CategorySummary]
    let isError: Bool

    static var placeholder: MultiCategoryEntry {
        MultiCategoryEntry(date: Date(), summaries: [
            CategorySummary(id: "1", name: "课程 A", colorHex: "#007AFF", iconName: "book.fill",
                          deadlineTitle: "期中报告", dueDate: Date().addingTimeInterval(8*86400), progress: 0.6, deadlineId: nil),
            CategorySummary(id: "2", name: "课程 B", colorHex: "#34C759", iconName: "pencil.and.ruler.fill",
                          deadlineTitle: "作业 3", dueDate: Date().addingTimeInterval(14*86400), progress: 0.2, deadlineId: nil),
            CategorySummary(id: "3", name: "课程 C", colorHex: "#FF9500", iconName: "graduationcap.fill",
                          deadlineTitle: "期末考试", dueDate: Date().addingTimeInterval(31*86400), progress: 0.0, deadlineId: nil),
        ], isError: false)
    }

    static var unavailable: MultiCategoryEntry {
        MultiCategoryEntry(date: Date(), summaries: [], isError: true)
    }
}

struct MultiCategoryProvider: TimelineProvider {
    func placeholder(in context: Context) -> MultiCategoryEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (MultiCategoryEntry) -> Void) {
        completion(.placeholder)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MultiCategoryEntry>) -> Void) {
        Task { @MainActor in
            guard let container = SharedModelContainer.createForWidget() else {
                completion(Timeline(entries: [.unavailable], policy: .after(nextMidnight())))
                return
            }

            let modelContext = ModelContext(container)

            let predicate = #Predicate<DDCategory> { !$0.isArchived }
            var descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\DDCategory.sortOrder)])
            let maxItems = context.family == .systemLarge ? 6 : 3
            descriptor.fetchLimit = maxItems

            let categories = (try? modelContext.fetch(descriptor)) ?? []

            let summaries: [CategorySummary] = categories.map { cat in
                let urgent = DeadlineQueryService.mostUrgentDeadline(in: cat)
                return CategorySummary(
                    id: cat.id.uuidString,
                    name: cat.name,
                    colorHex: cat.colorHex,
                    iconName: cat.iconName,
                    deadlineTitle: urgent?.title,
                    dueDate: urgent?.dueDate,
                    progress: urgent?.progress ?? 0,
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

            completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
        }
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
            VStack(alignment: .leading, spacing: 4) {
                ForEach(entry.summaries) { summary in
                    let deepLink = URL(string: "\(AppConstants.deepLinkScheme)://category/\(summary.id)")!
                    Link(destination: deepLink) {
                        HStack(spacing: 8) {
                            Image(systemName: summary.iconName)
                                .font(.caption)
                                .foregroundStyle(Color(hex: summary.colorHex) ?? .blue)
                                .frame(width: 16)

                            Text(summary.name)
                                .font(.caption)
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

                                ProgressView(value: summary.progress)
                                    .frame(width: 40)
                            } else {
                                Text("暂无")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                        }
                    }

                    if summary.id != entry.summaries.last?.id {
                        Divider()
                    }
                }
            }
        }
    }
}

private func nextMidnight() -> Date {
    Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
}
