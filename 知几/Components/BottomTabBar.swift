import SwiftUI

// MARK: - 底部导航栏

enum MainTab: String, CaseIterable {
    case zhiJi = "知己"    // 命盘 - 认识自己
    case zhiJi2 = "知几"   // 运势 - 把握时机

    var icon: String {
        switch self {
        case .zhiJi: return "circle.hexagongrid"
        case .zhiJi2: return "chart.line.uptrend.xyaxis"
        }
    }

    var selectedIcon: String {
        switch self {
        case .zhiJi: return "circle.hexagongrid.fill"
        case .zhiJi2: return "chart.line.uptrend.xyaxis"
        }
    }
}

struct BottomTabBar: View {
    @Binding var selectedTab: MainTab

    var body: some View {
        HStack(spacing: 6) {
            ForEach(MainTab.allCases, id: \.self) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.6), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: 4)
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    private func tabButton(for tab: MainTab) -> some View {
        let isSelected = selectedTab == tab

        return Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tab
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                    .font(.system(size: 18, weight: isSelected ? .medium : .light))
                    .foregroundColor(isSelected ? DesignSystem.textPrimary : DesignSystem.textTertiary)

                Text(tab.rawValue)
                    .font(.system(size: 11, weight: isSelected ? .medium : .light))
                    .foregroundColor(isSelected ? DesignSystem.textPrimary : DesignSystem.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(isSelected ? Color.gray.opacity(0.15) : Color.clear)
            )
        }
    }
}
