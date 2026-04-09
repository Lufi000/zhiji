import Foundation

// MARK: - OpenAI-compatible API

public struct MiniMaxMessage: Codable, Sendable {
    public let role: String
    public let content: String

    public init(role: String, content: String) {
        self.role = role
        self.content = content
    }
}

struct MiniMaxRequest: Encodable {
    let model: String
    let messages: [MiniMaxMessage]
    let stream: Bool
    let temperature: Double
    let maxTokens: Int
    let responseFormat: ResponseFormat?

    struct ResponseFormat: Encodable {
        let type: String
    }

    enum CodingKeys: String, CodingKey {
        case model, messages, stream, temperature
        case maxTokens = "max_tokens"
        case responseFormat = "response_format"
    }
}

struct MiniMaxResponse: Decodable {
    let choices: [MiniMaxChoice]
}

struct MiniMaxChoice: Decodable {
    let message: MiniMaxMessage?
    let delta: MiniMaxDelta?
    let finishReason: String?

    enum CodingKeys: String, CodingKey {
        case message, delta
        case finishReason = "finish_reason"
    }
}

struct MiniMaxDelta: Decodable {
    let content: String?
}

public enum MiniMaxChatAPIError: LocalizedError, Sendable {
    case emptyResponse
    case invalidResponse
    case invalidConfiguration
    case httpError(statusCode: Int)

    public var errorDescription: String? {
        switch self {
        case .emptyResponse: return "响应为空"
        case .invalidResponse: return "无效响应"
        case .invalidConfiguration: return "请配置有效的 HTTPS 对话接口 URL 与鉴权信息。"
        case .httpError(let code): return "请求失败（\(code)）"
        }
    }
}
