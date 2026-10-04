import Foundation
import SwiftUI

enum UrgencyLevel: Int, Comparable {
    case overdue = 0
    case critical = 1     // < 24h
    case urgent = 2       // 1-7 days
    case warning = 3      // 8-30 days
    case normal = 4       // > 30 days
    case none = 5         // completed or no deadline

    static func < (lhs: UrgencyLevel, rhs: UrgencyLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var color: Color {
        switch self {
        case .overdue, .critical: Theme.overdueFg
        case .urgent: Theme.urgentFg
        case .warning: Theme.soonFg
        case .normal: Theme.calmFg
        case .none: Theme.textTertiary
        }
    }

    var badgeBg: Color {
        switch self {
        case .overdue, .critical: Theme.overdueBg
        case .urgent: Theme.urgentBg
        case .warning: Theme.soonBg
        case .normal: Theme.calmBg
        case .none: Theme.calmBg
        }
    }

    var label: String {
        switch self {
        case .overdue: "已逾期"
        case .critical: "紧急"
        case .urgent: "即将到期"
        case .warning: "注意"
        case .normal: "正常"
        case .none: "无"
        }
    }
}

struct UrgencyThresholds {
    var warningDays: Int = 30
    var urgentDays: Int = 7
    var criticalHours: Int = 24

    static let `default` = UrgencyThresholds()

    static var fromUserDefaults: UrgencyThresholds {
        let defaults = AppConstants.appGroupDefaults
        return UrgencyThresholds(
            warningDays: defaults.object(forKey: "urgencyWarningDays") as? Int ?? 30,
            urgentDays: defaults.object(forKey: "urgencyUrgentDays") as? Int ?? 7,
            criticalHours: defaults.object(forKey: "urgencyCriticalHours") as? Int ?? 24
        )
    }
}

enum UrgencyCalculator {
    static func urgency(
        for dueDate: Date,
        status: DeadlineStatus,
        now: Date = Date(),
        thresholds: UrgencyThresholds = .default
    ) -> UrgencyLevel {
        if status == .completed { return .none }

        let remaining = dueDate.timeIntervalSince(now)
        if remaining < 0 { return .overdue }

        let hours = remaining / 3600
        if hours < Double(thresholds.criticalHours) { return .critical }

        let days = remaining / 86400
        if days <= Double(thresholds.urgentDays) { return .urgent }
        if days <= Double(thresholds.warningDays) { return .warning }

        return .normal
    }
}
