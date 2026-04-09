import SwiftUI

@main
struct 知几App: App {
    init() {
        UserDefaults.standard.register(defaults: ["zhiji.thinkingMode": "fast"])
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(.light)  // 强制使用浅色模式
        }
    }
}
