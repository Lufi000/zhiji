import SwiftUI

// MARK: - 玻璃质感卡片

struct GlassCard<Content: View>: View {
    let content: Content
    let tintColor: Color?

    init(tintColor: Color? = nil, @ViewBuilder content: () -> Content) {
        self.tintColor = tintColor
        self.content = content()
    }

    var body: some View {
        content
            .background(.ultraThinMaterial.opacity(0.8))
            .background(Color.white.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cornerRadiusLarge))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.cornerRadiusLarge)
                    .stroke(strokeColor, lineWidth: 1)
            )
            .shadow(color: shadowColor, radius: 24, x: 0, y: 12)
    }
    
    private var strokeColor: Color {
        if let tint = tintColor {
            // 环境色与白色混合，产生柔和的边框色
            return tint.opacity(0.25)
        }
        return Color.white.opacity(0.6)
    }
    
    private var shadowColor: Color {
        if let tint = tintColor {
            // 环境色影响阴影
            return tint.opacity(0.1)
        }
        return .black.opacity(0.06)
    }
}
