import SwiftUI

/// 聊天界面用色与字号；各 App 可 `extension` 出品牌色（如知几橙色）。
public struct MiniMaxChatPalette {
    public var background: Color
    public var cardBackgroundSolid: Color
    public var accent: Color
    public var accentLight: Color
    public var textPrimary: Color
    public var textSecondary: Color
    public var titleSize: CGFloat
    public var bodySize: CGFloat
    public var captionSize: CGFloat

    public init(
        background: Color,
        cardBackgroundSolid: Color,
        accent: Color,
        accentLight: Color,
        textPrimary: Color,
        textSecondary: Color,
        titleSize: CGFloat = 22,
        bodySize: CGFloat = 13,
        captionSize: CGFloat = 11
    ) {
        self.background = background
        self.cardBackgroundSolid = cardBackgroundSolid
        self.accent = accent
        self.accentLight = accentLight
        self.textPrimary = textPrimary
        self.textSecondary = textSecondary
        self.titleSize = titleSize
        self.bodySize = bodySize
        self.captionSize = captionSize
    }

    /// 与 cycle_advisor 暖羊皮纸风格接近的默认调色。
    public static let warmParchment = MiniMaxChatPalette(
        background: Color(hue: 0.07, saturation: 0.10, brightness: 0.96),
        cardBackgroundSolid: Color(hue: 0.07, saturation: 0.06, brightness: 0.99),
        accent: Color(red: 233 / 255, green: 138 / 255, blue: 184 / 255),
        accentLight: Color(red: 233 / 255, green: 138 / 255, blue: 184 / 255).opacity(0.18),
        textPrimary: Color(hue: 0.07, saturation: 0.08, brightness: 0.14),
        textSecondary: Color(hue: 0.07, saturation: 0.06, brightness: 0.50)
    )
}
