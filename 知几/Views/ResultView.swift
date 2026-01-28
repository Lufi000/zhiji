import SwiftUI

// MARK: - 结果视图

struct ResultView: View {
    // MARK: - ViewModel

    @State private var viewModel: ResultViewModel
    @State private var selectedTab: MainTab = .zhiJi

    let onBack: () -> Void

    // MARK: - Initialization

    init(bazi: Bazi, birth: (year: Int, month: Int, day: Int, hour: Int), gender: String, onBack: @escaping () -> Void) {
        self._viewModel = State(initialValue: ResultViewModel(bazi: bazi, birth: birth, gender: gender))
        self.onBack = onBack
    }

    var body: some View {
        ZStack {
            // 背景层（确保填满）
            Color.clear

            // 内容层（headerBar 已整合到子视图顶部）
            contentView

            // 底部导航栏（统一背景延伸到底部安全区域）
            VStack {
                Spacer()
                VStack(spacing: 0) {
                    BottomTabBar(selectedTab: $selectedTab)
                }
                .frame(maxWidth: .infinity)
                .background(
                    ZStack {
                        // 毛玻璃材质
                        Rectangle()
                            .fill(.ultraThinMaterial)
                        
                        // 渐变遮罩，让顶部透明
                        LinearGradient(
                            stops: [
                                .init(color: .white, location: 0),
                                .init(color: .clear, location: 0.3),
                                .init(color: .clear, location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .blendMode(.destinationOut)
                    }
                    .compositingGroup()
                    .padding(.top, -20)
                    .ignoresSafeArea(edges: .bottom)
                )
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .gesture(
            DragGesture(minimumDistance: 50, coordinateSpace: .local)
                .onEnded { value in
                    if value.translation.width > 80 && abs(value.translation.height) < 100 {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            onBack()
                        }
                    }
                }
        )
        .sheet(item: $viewModel.selectedExplanationType) { explanationType in
            ExplanationSheetView(explanationType: explanationType)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .overlay(alignment: .top) {
            if viewModel.showCopiedToast {
                Text("已复制到剪贴板")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.75))
                    .clipShape(Capsule())
                    .padding(.top, 60)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    // MARK: - 内容视图

    @ViewBuilder
    private var contentView: some View {
        switch selectedTab {
        case .zhiJi:
            MingPanView(viewModel: viewModel, onBack: onBack)
        case .zhiJi2:
            YunShiView(viewModel: viewModel, onBack: onBack)
        }
    }
}
