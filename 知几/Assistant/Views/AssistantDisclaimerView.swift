import MiniMaxChatKit
import SwiftUI

struct AssistantDisclaimerView: View {
    private var palette: MiniMaxChatPalette { .zhiji }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 10))
                .foregroundStyle(palette.textSecondary.opacity(0.6))
            Text("本功能仅供文化参考与交流，不构成医疗、法律或投资建议。")
                .font(.system(size: palette.captionSize))
                .foregroundStyle(palette.textSecondary.opacity(0.6))
        }
        .padding(.vertical, 8)
    }
}
