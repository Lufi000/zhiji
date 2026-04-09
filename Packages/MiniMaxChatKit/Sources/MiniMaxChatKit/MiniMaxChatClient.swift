import Foundation

/// 连接自建 BFF 的 MiniMax 流式客户端（OpenAI 兼容）。各 App 注入 `MiniMaxChatConfiguration`。
public actor MiniMaxChatClient {
    private let chatCompletionsURL: URL?
    private let appToken: String
    private let thinkingModeStorageKey: String
    private let chatMaxTokens: Int

    private let decoder = JSONDecoder()
    private let session: URLSession

    public init(configuration: any MiniMaxChatConfiguration) {
        self.chatCompletionsURL = configuration.chatCompletionsURL
        self.appToken = configuration.appToken
        self.thinkingModeStorageKey = configuration.thinkingModeUserDefaultsKey
        self.chatMaxTokens = max(256, configuration.chatMaxTokens)
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 180
        session = URLSession(configuration: config)
    }

    public var thinkingMode: ThinkingMode {
        get {
            let raw = UserDefaults.standard.string(forKey: thinkingModeStorageKey) ?? "fast"
            return ThinkingMode(rawValue: raw) ?? .fast
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: thinkingModeStorageKey)
        }
    }

    private static let suggestionModelName = ThinkingMode.fast.modelName
    private static let questionsMaxTokens = 300

    // MARK: - 流式对话

    public func streamChat(
        history: [MiniMaxMessage],
        systemPrompt: String,
        temperature: Double = 0.70,
        onToken: @escaping (String) -> Void,
        onThinking: @escaping (String) -> Void
    ) async throws -> String {
        let request = MiniMaxRequest(
            model: thinkingMode.modelName,
            messages: [MiniMaxMessage(role: "system", content: systemPrompt)] + history,
            stream: true,
            temperature: temperature,
            maxTokens: chatMaxTokens,
            responseFormat: nil
        )

        let urlRequest = try buildURLRequest(for: request)
        let (asyncBytes, httpResponse) = try await session.bytes(for: urlRequest)

        guard let http = httpResponse as? HTTPURLResponse, http.statusCode == 200 else {
            let code = (httpResponse as? HTTPURLResponse)?.statusCode ?? -1
            throw MiniMaxChatAPIError.httpError(statusCode: code)
        }

        var fullContent = ""
        var inThink = false
        var thinkResolved = false
        var emittedLength = 0

        for try await line in asyncBytes.lines {
            guard let data = Self.sseData(from: line),
                  let parsed = try? decoder.decode(MiniMaxResponse.self, from: data)
            else { continue }

            let choice = parsed.choices.first
            let chunk = choice?.delta?.content ?? choice?.message?.content ?? ""
            if !chunk.isEmpty {
                fullContent += chunk

                if !thinkResolved {
                    if !inThink && fullContent.contains("<think>") { inThink = true }
                    if inThink {
                        if let range = fullContent.range(of: "</think>") {
                            let thinkContent = String(
                                fullContent[fullContent.range(of: "<think>")!.upperBound..<range.lowerBound]
                            ).trimmingCharacters(in: .whitespacesAndNewlines)
                            onThinking(thinkContent)
                            thinkResolved = true
                        } else if let start = fullContent.range(of: "<think>") {
                            let partial = String(fullContent[start.upperBound...])
                                .trimmingCharacters(in: .whitespacesAndNewlines)
                            if !partial.isEmpty { onThinking(partial) }
                        }
                    } else if fullContent.count > 10 {
                        thinkResolved = true
                    }
                }

                if thinkResolved {
                    let cleaned = Self.cleanContent(fullContent)
                    if cleaned.count > emittedLength {
                        let newPart = String(cleaned.dropFirst(emittedLength))
                        onToken(newPart)
                        emittedLength = cleaned.count
                    }
                }
            }

            if choice?.finishReason == "stop" { break }
        }

        return Self.cleanContent(fullContent)
    }

    // MARK: - JSON 问题列表（首屏推荐 / 追问芯片）

    /// 非流式，返回 `{"questions":[...]}` 解析后的字符串数组。
    public func fetchQuestionsJSON(
        systemPrompt: String,
        userPrompt: String,
        temperature: Double = 0.64,
        maxTokens: Int = 300
    ) async throws -> [String] {
        let request = MiniMaxRequest(
            model: Self.suggestionModelName,
            messages: [
                MiniMaxMessage(role: "system", content: systemPrompt),
                MiniMaxMessage(role: "user", content: userPrompt)
            ],
            stream: false,
            temperature: temperature,
            maxTokens: maxTokens,
            responseFormat: .init(type: "json_object")
        )

        let response: MiniMaxResponse = try await sendRequest(request)
        guard let content = response.choices.first?.message?.content else {
            throw MiniMaxChatAPIError.emptyResponse
        }
        return (try? Self.parseQuestions(from: content)) ?? []
    }

    // MARK: - Networking

    private func sendRequest<T: Decodable>(_ body: MiniMaxRequest) async throws -> T {
        let urlRequest = try buildURLRequest(for: body)
        let (data, response) = try await session.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse else {
            throw MiniMaxChatAPIError.invalidResponse
        }
        guard http.statusCode == 200 else {
            throw MiniMaxChatAPIError.httpError(statusCode: http.statusCode)
        }
        return try decoder.decode(T.self, from: data)
    }

    private func buildURLRequest(for body: MiniMaxRequest) throws -> URLRequest {
        guard let url = chatCompletionsURL else {
            throw MiniMaxChatAPIError.invalidConfiguration
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(appToken, forHTTPHeaderField: "X-App-Token")
        req.httpBody = try JSONEncoder().encode(body)
        return req
    }

    private nonisolated static func sseData(from line: String) -> Data? {
        guard line.hasPrefix("data:") else { return nil }
        let payload = line.dropFirst(5).trimmingCharacters(in: .whitespaces)
        guard payload != "[DONE]", !payload.isEmpty else { return nil }
        return payload.data(using: .utf8)
    }

    private nonisolated static func cleanContent(_ raw: String) -> String {
        var s = raw
        if let thinkEnd = s.range(of: "</think>") {
            s = String(s[thinkEnd.upperBound...])
        }
        s = s.replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return s
    }

    private nonisolated static func parseQuestions(from content: String) throws -> [String] {
        let cleaned = cleanContent(content)
        guard let data = cleaned.data(using: .utf8) else { return [] }
        if let arr = (try? JSONSerialization.jsonObject(with: data)) as? [String] {
            return arr.filter { !$0.isEmpty }
        }
        if let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] {
            let arr = (obj["questions"] as? [String]) ?? (obj["问题"] as? [String]) ?? []
            return arr.filter { !$0.isEmpty }
        }
        return []
    }
}
