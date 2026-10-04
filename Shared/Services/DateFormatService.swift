import Foundation

enum DateFormatService {
    static func relativeText(from dueDate: Date, now: Date = Date()) -> String {
        let interval = dueDate.timeIntervalSince(now)

        if interval < 0 {
            let overdueDays = Int(-interval / 86400)
            if overdueDays == 0 {
                let hours = Int(-interval / 3600)
                if hours == 0 {
                    return "刚刚逾期"
                }
                return "逾期 \(hours) 小时"
            }
            return "逾期 \(overdueDays) 天"
        }

        let days = Int(interval / 86400)
        if days == 0 {
            let hours = Int(interval / 3600)
            if hours == 0 {
                let minutes = max(1, Int(interval / 60))
                return "还有 \(minutes) 分钟"
            }
            return "还有 \(hours) 小时"
        }
        if days == 1 { return "明天截止" }
        return "还有 \(days) 天"
    }

    static func absoluteText(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日 HH:mm"
        return formatter.string(from: date)
    }

    static func shortDateText(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }

    static func progressText(_ progress: Double) -> String {
        "\(Int(progress * 100))%"
    }

    static func actionItemCountText(completed: Int, total: Int) -> String {
        "\(completed)/\(total) 项"
    }

    static func weekdayText(from date: Date) -> String {
        let weekdays = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
        let index = Calendar.current.component(.weekday, from: date) - 1
        return weekdays[index]
    }

    static func fullDateText(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日"
        let weekday = weekdayText(from: date)
        return "\(formatter.string(from: date)) \(weekday)"
    }

    static func todayText() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        let weekday = weekdayText(from: Date())
        return "\(formatter.string(from: Date())) \(weekday)"
    }

    struct CountdownParts {
        let prefix: String
        let number: String
        let unit: String
        let isOverdue: Bool
    }

    static func countdownParts(from dueDate: Date, now: Date = Date()) -> CountdownParts {
        let interval = dueDate.timeIntervalSince(now)
        let days = Int(interval / 86400)

        if interval < 0 {
            let overdueDays = Int(-interval / 86400)
            if overdueDays == 0 {
                let hours = max(1, Int(-interval / 3600))
                return CountdownParts(prefix: "逾期", number: String(hours), unit: "小时", isOverdue: true)
            }
            return CountdownParts(prefix: "逾期", number: String(overdueDays), unit: "天", isOverdue: true)
        }

        if days == 0 {
            let hours = Int(interval / 3600)
            if hours == 0 {
                return CountdownParts(prefix: "", number: "今天", unit: "截止", isOverdue: false)
            }
            return CountdownParts(prefix: "还有", number: String(hours), unit: "小时", isOverdue: false)
        }

        return CountdownParts(prefix: "还有", number: String(days), unit: "天", isOverdue: false)
    }
}
