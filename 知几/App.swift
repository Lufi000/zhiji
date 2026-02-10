import SwiftUI

@main
struct 知几App: App {
    var body: some Scene {
        WindowGroup {
            BaziCalculatorView()
                .preferredColorScheme(.light)  // 强制使用浅色模式
        }
    }
}
