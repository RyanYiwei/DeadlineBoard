import SwiftUI

enum Theme {
    static let background = Color(hex: "#F8F4EC")!
    static let sidebarBg = Color(hex: "#EEE7DB")!

    static let textPrimary = Color(hex: "#2E2B25")!
    static let textSecondary = Color(hex: "#82796A")!
    static let textTertiary = Color(hex: "#A19786")!
    static let textDark = Color(hex: "#474238")!

    static let divider = Color(hex: "#463C2D")!.opacity(0.1)

    static let cardBg = Color(hex: "#FFFDF6")!.opacity(0.38)
    static let cardBgHover = Color(hex: "#FFFDF6")!.opacity(0.62)
    static let cardBgActive = Color(hex: "#FFFDF6")!.opacity(0.70)
    static let cardBorder = Color.white.opacity(0.45)
    static let cardBorderActive = Color.white.opacity(0.8)

    static let heroBg = Color(hex: "#FFFDF6")!.opacity(0.42)
    static let heroBorder = Color.white.opacity(0.55)

    static let overdueFg = Color(hex: "#9A4F4F")!
    static let overdueBg = Color(hex: "#F1DCD8")!
    static let urgentFg = Color(hex: "#A0623F")!
    static let urgentBg = Color(hex: "#F2E2D3")!
    static let soonFg = Color(hex: "#7F6C3F")!
    static let soonBg = Color(hex: "#EDE4CD")!
    static let calmFg = Color(hex: "#56633F")!
    static let calmBg = Color(hex: "#E2E6D8")!

    static let overdueRowBg = Color(hex: "#F1DCD8")!.opacity(0.6)
    static let overdueRowBorder = Color(hex: "#DCB4AC")!.opacity(0.5)
}

struct CategoryPalette {
    let name: String
    let hex: String
    let base: Color
    let tint: Color
    let deep: Color

    static let all: [CategoryPalette] = [
        .init(name: "雾蓝", hex: "#7B9CB8",
              base: Color(hex: "#7B9CB8")!, tint: Color(hex: "#DBE5EC")!, deep: Color(hex: "#3F5A73")!),
        .init(name: "鼠尾草", hex: "#93A86E",
              base: Color(hex: "#93A86E")!, tint: Color(hex: "#DFE8CF")!, deep: Color(hex: "#4B5C33")!),
        .init(name: "灰粉", hex: "#C88F86",
              base: Color(hex: "#C88F86")!, tint: Color(hex: "#F2DCD6")!, deep: Color(hex: "#84504A")!),
        .init(name: "暖灰", hex: "#A3978A",
              base: Color(hex: "#A3978A")!, tint: Color(hex: "#E9E2D7")!, deep: Color(hex: "#5F574D")!),
        .init(name: "薰衣草", hex: "#9B8BB4",
              base: Color(hex: "#9B8BB4")!, tint: Color(hex: "#E4DFF0")!, deep: Color(hex: "#5B4A78")!),
        .init(name: "陶土", hex: "#C07B5F",
              base: Color(hex: "#C07B5F")!, tint: Color(hex: "#F0DDD2")!, deep: Color(hex: "#7A4A35")!),
        .init(name: "松石", hex: "#6F9E9A",
              base: Color(hex: "#6F9E9A")!, tint: Color(hex: "#D6E8E5")!, deep: Color(hex: "#3A5F5B")!),
        .init(name: "琥珀", hex: "#B8A04E",
              base: Color(hex: "#B8A04E")!, tint: Color(hex: "#EDE5C5")!, deep: Color(hex: "#6B5A2A")!),
    ]

    static func forHex(_ hex: String) -> CategoryPalette {
        let normalized = hex.uppercased()
        if let p = all.first(where: { $0.hex.uppercased() == normalized }) {
            return p
        }
        let base = Color(hex: hex) ?? .blue
        return CategoryPalette(name: "", hex: hex, base: base, tint: base.opacity(0.18), deep: base)
    }
}

extension DDCategory {
    var palette: CategoryPalette {
        CategoryPalette.forHex(colorHex)
    }
}

struct ProgressRing: View {
    let progress: Double
    let color: Color
    var size: CGFloat = 84
    var lineWidth: CGFloat = 8

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(hex: "#465032")!.opacity(0.1), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: CGFloat(min(max(progress, 0), 1)))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.4), value: progress)
        }
        .frame(width: size, height: size)
    }
}

struct ThemeProgressBar: View {
    let value: Double
    var tint: Color = Theme.textSecondary
    var height: CGFloat = 6
    var trackColor: Color = Color(hex: "#463C2D")!.opacity(0.09)

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(trackColor)
                Capsule()
                    .fill(tint)
                    .frame(width: geo.size.width * CGFloat(min(max(value, 0), 1)))
            }
        }
        .frame(height: height)
    }
}
