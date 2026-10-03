import Foundation

enum AppConstants {
    static let appGroupIdentifier = "group.com.deadlineboard.shared"
    static let deepLinkScheme = "deadlineboard"
    static let appGroupDefaults = UserDefaults(suiteName: appGroupIdentifier) ?? .standard

    enum DefaultReminderOffsets {
        static let thirtyDays: TimeInterval = -30 * 86400
        static let fourteenDays: TimeInterval = -14 * 86400
        static let sevenDays: TimeInterval = -7 * 86400
        static let threeDays: TimeInterval = -3 * 86400
        static let oneDay: TimeInterval = -86400
        static let threeHours: TimeInterval = -3 * 3600

        static let all: [(label: String, offset: TimeInterval)] = [
            ("提前 30 天", thirtyDays),
            ("提前 14 天", fourteenDays),
            ("提前 7 天", sevenDays),
            ("提前 3 天", threeDays),
            ("提前 1 天", oneDay),
            ("提前 3 小时", threeHours),
        ]
    }

    enum CategoryColors {
        static let all: [(name: String, hex: String)] = [
            ("蓝色", "#007AFF"),
            ("紫色", "#AF52DE"),
            ("粉色", "#FF2D55"),
            ("红色", "#FF3B30"),
            ("橙色", "#FF9500"),
            ("黄色", "#FFCC00"),
            ("绿色", "#34C759"),
            ("青色", "#5AC8FA"),
            ("靛蓝", "#5856D6"),
            ("棕色", "#A2845E"),
        ]
    }

    enum CategoryIcons {
        static let all: [String] = [
            "folder.fill",
            "book.fill",
            "graduationcap.fill",
            "pencil.and.ruler.fill",
            "laptopcomputer",
            "briefcase.fill",
            "star.fill",
            "flag.fill",
            "heart.fill",
            "bolt.fill",
            "leaf.fill",
            "globe",
            "music.note",
            "paintbrush.fill",
            "hammer.fill",
            "wrench.and.screwdriver.fill",
        ]
    }
}
