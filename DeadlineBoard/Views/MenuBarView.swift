import SwiftUI
import SwiftData

struct MenuBarView: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings

    @Query(filter: #Predicate<DDCategory> { !$0.isArchived },
           sort: \DDCategory.sortOrder)
    private var categories: [DDCategory]

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().opacity(0.4)

            if categories.isEmpty {
                emptyState
            } else {
                categoryList
            }

            Divider().opacity(0.4)
            footer
        }
        .frame(width: 300)
        .background(Theme.background)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textDark)
            Text("Deadline Board")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textDark)
            Spacer()
            Text(DateFormatService.todayText())
                .font(.system(size: 11))
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Category List

    private var categoryList: some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                ForEach(categories) { category in
                    MenuBarCategoryRow(category: category)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .frame(maxHeight: 320)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.system(size: 24))
                .foregroundStyle(Theme.textTertiary)
            Text("还没有分类")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 12) {
            Button {
                openWindow(id: "main")
                NSApp.activate()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "macwindow")
                        .font(.system(size: 11))
                    Text("打开面板")
                        .font(.system(size: 12))
                }
                .foregroundStyle(Theme.textDark)
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                openSettings()
                NSApp.activate()
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
            }
            .buttonStyle(.plain)

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Text("退出")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - Category Row

struct MenuBarCategoryRow: View {
    let category: DDCategory

    private var nearestDeadline: DDDeadline? {
        category.activeDeadlines
            .sorted { $0.dueDate < $1.dueDate }
            .first
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: category.iconName)
                .font(.system(size: 11))
                .foregroundStyle(category.palette.base)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 3) {
                Text(category.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.textDark)

                if let deadline = nearestDeadline {
                    let urgency = UrgencyCalculator.urgency(for: deadline.dueDate, status: deadline.status)
                    HStack(spacing: 0) {
                        Text(deadline.title)
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textSecondary)
                            .lineLimit(1)

                        Spacer(minLength: 8)

                        Text(DateFormatService.relativeText(from: deadline.dueDate))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(urgency.color)
                    }
                } else {
                    Text("全部完成")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.calmFg)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 6).fill(Theme.cardBg))
    }
}
