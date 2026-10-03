import SwiftUI
import WidgetKit
import SwiftData

struct ProgressWidget: Widget {
    let kind = "ProgressWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ProgressWidgetProvider()) { entry in
            ProgressWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("进度概览")
        .description("展示各分类最近 DDL 的完成进度")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct ProgressEntry: TimelineEntry {
    let date: Date
    let items: [ProgressItem]
    let isError: Bool

    static var placeholder: ProgressEntry {
        ProgressEntry(date: Date(), items: [
            ProgressItem(id: "1", categoryName: "课程 A", deadlineTitle: "期中报告", progress: 0.6, colorHex: "#007AFF"),
            ProgressItem(id: "2", categoryName: "课程 B", deadlineTitle: "作业 3", progress: 0.2, colorHex: "#34C759"),
            ProgressItem(id: "3", categoryName: "课程 C", deadlineTitle: "期末考试", progress: 0.0, colorHex: "#FF9500"),
        ], isError: false)
    }

    static var unavailable: ProgressEntry {
        ProgressEntry(date: Date(), items: [], isError: true)
    }
}

struct ProgressItem: Identifiable {
    let id: String
    let categoryName: String
    let deadlineTitle: String
    let progress: Double
    let colorHex: String
}

struct ProgressWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> ProgressEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (ProgressEntry) -> Void) {
        completion(.placeholder)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ProgressEntry>) -> Void) {
        Task { @MainActor in
            guard let container = SharedModelContainer.createForWidget() else {
                completion(Timeline(entries: [.unavailable], policy: .after(Calendar.current.startOfDay(for: Date().addingTimeInterval(86400)))))
                return
            }
            let modelContext = ModelContext(container)

            let predicate = #Predicate<DDCategory> { !$0.isArchived }
            var descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\DDCategory.sortOrder)])
            let maxItems = context.family == .systemLarge ? 6 : 3
            descriptor.fetchLimit = maxItems

            let categories = (try? modelContext.fetch(descriptor)) ?? []

            let items: [ProgressItem] = categories.compactMap { cat in
                guard let urgent = DeadlineQueryService.mostUrgentDeadline(in: cat) else { return nil }
                return ProgressItem(
                    id: cat.id.uuidString,
                    categoryName: cat.name,
                    deadlineTitle: urgent.title,
                    progress: urgent.progress,
                    colorHex: cat.colorHex
                )
            }

            let entry = ProgressEntry(date: Date(), items: items, isError: false)
            let midnight = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
            completion(Timeline(entries: [entry], policy: .after(midnight)))
        }
    }
}

struct ProgressWidgetView: View {
    let entry: ProgressEntry

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
        } else if entry.items.isEmpty {
            VStack {
                Image(systemName: "chart.bar")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("没有进行中的 DDL")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } else {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(entry.items) { item in
                    let deepLink = URL(string: "\(AppConstants.deepLinkScheme)://category/\(item.id)")!
                    Link(destination: deepLink) {
                        HStack(spacing: 8) {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(item.categoryName)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(item.deadlineTitle)
                                    .font(.caption)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            ProgressView(value: item.progress)
                                .tint(Color(hex: item.colorHex) ?? .blue)
                                .frame(width: 80)

                            Text(DateFormatService.progressText(item.progress))
                                .font(.caption)
                                .monospacedDigit()
                                .frame(width: 35, alignment: .trailing)
                        }
                    }
                }
            }
        }
    }
}
