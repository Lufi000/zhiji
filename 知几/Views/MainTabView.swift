import SwiftUI

/// 应用主导航：排盘与 AI 助手两个 Tab（助手与 cycle_advisor 同源：经服务端 BFF 转发模型、流式 UI）
struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var mingPanStore: MingPanStore
    @State private var assistantViewModel: BaziAssistantViewModel

    init() {
        let store = MingPanStore()
        _mingPanStore = State(initialValue: store)
        _assistantViewModel = State(initialValue: BaziAssistantViewModel(mingPanStore: store))
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            BaziCalculatorView(mingPanStore: mingPanStore)
                .tabItem {
                    Label("排盘", systemImage: "circle.hexagongrid")
                }
                .tag(0)

            BaziAssistantView(viewModel: assistantViewModel, mingPanStore: mingPanStore, selectedTab: $selectedTab)
                .tabItem {
                    Label("AI 助手", systemImage: "bubble.left.and.bubble.right")
                }
                .tag(1)
        }
        .tint(DesignSystem.primaryOrange)
    }
}
