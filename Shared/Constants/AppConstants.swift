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
        static let all: [(name: String, hex: String)] = CategoryPalette.all.map { ($0.name, $0.hex) }
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
