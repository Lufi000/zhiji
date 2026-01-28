import SwiftUI

// MARK: - 玻璃质感卡片

struct GlassCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .background(.ultraThinMaterial.opacity(0.8))
            .background(Color.white.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cornerRadiusLarge))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.cornerRadiusLarge)
                    .stroke(Color.white.opacity(0.6), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 24, x: 0, y: 12)
    }
}
