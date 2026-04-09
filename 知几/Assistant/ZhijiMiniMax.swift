import MiniMaxChatKit
import SwiftUI

/// 知几 App 内共享的聊天客户端与调色板：`MiniMaxChatClient` 只请求自建 BFF（与 cycle_advisor 相同），连接信息见 `Secrets`。
enum ZhijiMiniMax {
    static let client = MiniMaxChatClient(
        configuration: MiniMaxChatConfigurationValues(
            baseURLString: Secrets.baseURL,
            appToken: Secrets.appToken,
            thinkingModeUserDefaultsKey: "zhiji.thinkingMode",
            chatMaxTokens: 1600
        )
    )
}

extension MiniMaxChatPalette {
    /// 与主 App `DesignSystem` 对齐的强调色。
    static var zhiji: MiniMaxChatPalette {
        MiniMaxChatPalette(
            background: Color(hue: 0.07, saturation: 0.10, brightness: 0.96),
            cardBackgroundSolid: Color(hue: 0.07, saturation: 0.06, brightness: 0.99),
            accent: DesignSystem.primaryOrange,
            accentLight: DesignSystem.primaryOrange.opacity(0.18),
            textPrimary: DesignSystem.textPrimary,
            textSecondary: DesignSystem.textSecondary
        )
    }
}
