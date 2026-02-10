import SwiftUI

// MARK: - 结果视图

struct ResultView: View {
    // MARK: - ViewModel

    @State private var viewModel: ResultViewModel

    let onBack: () -> Void

    // MARK: - Initialization

    init(bazi: Bazi, birth: (year: Int, month: Int, day: Int, hour: Int, minute: Int), gender: String, onBack: @escaping () -> Void) {
        self._viewModel = State(initialValue: ResultViewModel(bazi: bazi, birth: birth, gender: gender))
        self.onBack = onBack
    }

    var body: some View {
        ZStack {
            // 背景层（确保填满）
            Color.clear

            // 内容层（headerBar 已整合到子视图顶部）
            contentView
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
        .overlay(alignment: .top) {
            if let message = viewModel.copiedToastMessage {
                Text(message)
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

    private var contentView: some View {
        MingPanView(viewModel: viewModel, onBack: onBack)
    }
}
