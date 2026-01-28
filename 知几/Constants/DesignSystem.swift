import SwiftUI

// MARK: - 设计系统

struct DesignSystem {
    // 主色调
    static let primaryOrange = Color(hex: "FF8A50")

    // 中性色
    static let textPrimary = Color(hex: "1A1A1A")     // 主文字
    static let textSecondary = Color(hex: "666666")   // 次要文字
    static let textTertiary = Color(hex: "999999")    // 辅助文字

    // 圆角
    static let cornerRadiusLarge: CGFloat = 40
    static let cornerRadiusMedium: CGFloat = 28
    static let cornerRadiusSmall: CGFloat = 16
}

// MARK: - 五行颜色（基于Logo配色）

struct WuXingColor {
    // Logo配色
    static let grassColor = Color(hex: "4A9F5E")   // 木 - 亮草绿（提高识别度）
    static let sunColor = Color(hex: "F5B041")     // 金 - 太阳橙黄（金色）
    static let stoneColor = Color(hex: "D35400")   // 火 - 石头橙红
    static let waveColor = Color(hex: "2980B9")    // 水 - 波浪蓝
    static let earthColor = Color(hex: "8B7355")   // 土 - 大地棕色

    static func colors(for wuxing: String) -> (primary: Color, secondary: Color) {
        switch wuxing {
        case "木": return (grassColor.opacity(0.8), grassColor)
        case "火": return (stoneColor.opacity(0.8), stoneColor)
        case "土": return (earthColor.opacity(0.8), earthColor)
        case "金": return (sunColor.opacity(0.8), sunColor)
        case "水": return (waveColor.opacity(0.8), waveColor)
        default: return (Color.gray, Color.gray)
        }
    }
}

// MARK: - Color Hex Extension

extension Color {
    /// 从十六进制字符串创建颜色
    /// - Parameter hex: 6位或8位十六进制颜色值（如 "FF8A50" 或 "FF8A50FF"）
    /// - Note: 无效的 hex 值将返回黑色，并在 DEBUG 模式下触发断言
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            assertionFailure("Invalid hex color format: \(hex). Expected 6 or 8 characters.")
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

// MARK: - View Extensions

extension View {
    func formLabel() -> some View {
        self
            .font(.system(size: 12, weight: .light))
            .foregroundColor(DesignSystem.textTertiary)
            .tracking(1)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
