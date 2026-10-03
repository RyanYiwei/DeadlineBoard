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
}
