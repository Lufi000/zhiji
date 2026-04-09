import Foundation

/// 宿主 App 提供的 BFF 连接信息（与 cycle_advisor 一致：`X-App-Token` + OpenAI 兼容 body）。
public protocol MiniMaxChatConfiguration: Sendable {
    /// `POST` 的目标，一般为 `…/v1/chat/completions`
    var chatCompletionsURL: URL? { get }
    var appToken: String { get }
    /// `UserDefaults` 中持久化「快 / 深」思考模式所用 key
    var thinkingModeUserDefaultsKey: String { get }
}

public extension MiniMaxChatConfiguration {
    /// 单轮聊天回复的输出 token 上限；默认保持 800 以兼容旧行为。
    var chatMaxTokens: Int { 800 }
}

/// 常用值类型实现，便于在各工程中直接 `init(baseURLString:appToken:…)`。
public struct MiniMaxChatConfigurationValues: MiniMaxChatConfiguration, Sendable {
    public let chatCompletionsURL: URL?
    public let appToken: String
    public let thinkingModeUserDefaultsKey: String
    public let chatMaxTokens: Int

    public init(
        baseURLString: String,
        appToken: String,
        thinkingModeUserDefaultsKey: String,
        chatMaxTokens: Int = 800
    ) {
        let t = baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        self.chatCompletionsURL = t.hasPrefix("http") ? URL(string: t) : nil
        self.appToken = appToken
        self.thinkingModeUserDefaultsKey = thinkingModeUserDefaultsKey
        self.chatMaxTokens = max(256, chatMaxTokens)
    }
}
