import Foundation
import MiniMaxChatKit
import Observation

/// 与 cycle_advisor `AssistantViewModel` 同结构的八字助手状态机（经 BFF 流式对话 + 本地持久化）。
@Observable
@MainActor
final class BaziAssistantViewModel {
    private let mingPanStore: MingPanStore

    var messages: [ChatMessage] = []
    var inputText: String = ""
    var isStreaming: Bool = false
    var suggestedQuestions: [String] = []
    /// 首屏「你可能想问」加载中（便于空列表时显示加载态）。
    var isLoadingSuggestedQuestions: Bool = false

    private(set) var followUpChipsRevision: Int = 0

    private static let maxHistoryMessages = 20

    private let historyURL: URL = {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("zhiji_chat_history.json")
    }()

    private var toastClearTask: Task<Void, Never>?
    var apiErrorToast: String?

    init(mingPanStore: MingPanStore) {
        self.mingPanStore = mingPanStore
        loadHistory()
    }

    /// 排盘完成后刷新空对话下的「你可能想问」（`force` 为 true 时会重新拉取，即使已有占位问题）。
    func loadSuggestedQuestionsIfNeeded(force: Bool = false) async {
        guard messages.isEmpty else { return }
        if !force && !suggestedQuestions.isEmpty { return }
        isLoadingSuggestedQuestions = true
        defer { isLoadingSuggestedQuestions = false }
        let ctx = mingPanStore.currentAssistantPanSummary()
        let clock = BaziPrompts.dialogueClockContext(riGan: mingPanStore.currentRiGanForAssistant())
        do {
            let qs = try await ZhijiMiniMax.client.fetchQuestionsJSON(
                systemPrompt: BaziPrompts.suggestedQuestionsSystem(),
                userPrompt: BaziPrompts.suggestedQuestionsUser(panSummary: ctx, dialogueClock: clock),
                temperature: 0.52,
                maxTokens: 400
            )
            let normalized = Self.normalizeToThreeQuestions(qs)
            if !normalized.isEmpty {
                suggestedQuestions = normalized
                return
            }
        } catch {
            // 网络或配置失败时使用本地默认
        }
        suggestedQuestions = Self.defaultSuggestedQuestions
    }

    /// 命盘摘要已更新且当前无对话时，清空并重新生成建议问题。
    func reloadSuggestedQuestionsAfterPanSync() async {
        guard messages.isEmpty else { return }
        suggestedQuestions = []
        await loadSuggestedQuestionsIfNeeded(force: true)
    }

    private static let defaultSuggestedQuestions = [
        "八字里的「日主」通常怎么理解？",
        "大运和流年，看运势时哪个更优先？",
        "五行「平衡」在命盘里是什么意思？"
    ]

    func sendMessage(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isStreaming else { return }

        let now = Date()
        let today = gregorianLocalCalendar().startOfDay(for: now)
        messages.append(ChatMessage(role: .user, content: trimmed, sessionDate: today))

        let apiHistory: [MiniMaxMessage] = messages
            .suffix(Self.maxHistoryMessages)
            .compactMap { msg in
                guard !msg.content.isEmpty else { return nil }
                return MiniMaxMessage(role: msg.role.rawValue, content: msg.content)
            }

        let pack = mingPanStore.currentAssistantKnowledgePack()
        let capturedPan = pack?.summary ?? mingPanStore.currentAssistantPanSummary()
        let dialogueClock = BaziPrompts.dialogueClockContext(riGan: mingPanStore.currentRiGanForAssistant(), now: now)
        let evidencePacket = buildEvidencePacket(question: trimmed, pack: pack)
        let principles = AssistantPrinciplesProvider.load()

        let assistantId = UUID()
        messages.append(ChatMessage(
            id: assistantId,
            role: .assistant,
            content: "",
            isStreaming: true,
            sessionDate: today
        ))

        isStreaming = true
        let systemPrompt = BaziPrompts.chatSystemPrompt(
            panSummary: capturedPan,
            dialogueClock: dialogueClock,
            evidencePacket: evidencePacket,
            principles: principles
        )
        var streamSucceeded = false
        do {
            _ = try await ZhijiMiniMax.client.streamChat(
                history: apiHistory,
                systemPrompt: systemPrompt,
                temperature: 0.42,
                onToken: { [weak self] token in
                    Task { @MainActor [weak self] in
                        guard let self,
                              let idx = self.messages.firstIndex(where: { $0.id == assistantId })
                        else { return }
                        self.messages[idx].content += token
                    }
                },
                onThinking: { [weak self] thinking in
                    Task { @MainActor [weak self] in
                        guard let self,
                              let idx = self.messages.firstIndex(where: { $0.id == assistantId })
                        else { return }
                        self.messages[idx].thinkingText = thinking
                    }
                }
            )
            streamSucceeded = true
        } catch {
            if let idx = messages.firstIndex(where: { $0.id == assistantId }) {
                messages[idx].content = "抱歉，出了点小问题，请再试一次 🙏"
            }
            showApiToast(error.localizedDescription)
        }

        if let idx = messages.firstIndex(where: { $0.id == assistantId }) {
            messages[idx].isStreaming = false
        }
        isStreaming = false
        saveHistory()

        if streamSucceeded,
           let i = messages.firstIndex(where: { $0.id == assistantId }) {
            let reply = messages[i].content.trimmingCharacters(in: .whitespacesAndNewlines)
            if !reply.isEmpty {
                let followUps = await fetchContextualFollowUpQuestions(
                    userQuestion: trimmed,
                    assistantReply: messages[i].content
                )
                if !followUps.isEmpty {
                    var updated = messages[i]
                    updated.followUpQuestions = followUps
                    messages[i] = updated
                    followUpChipsRevision += 1
                    saveHistory()
                }
            }
        }
    }

    /// 在助手回复**完成后**拉取追问：带完整上一答 + 近期对话摘录，保证与当前语境一致。
    private func fetchContextualFollowUpQuestions(userQuestion: String, assistantReply: String) async -> [String] {
        let ctx = mingPanStore.currentAssistantPanSummary()
        let clock = BaziPrompts.dialogueClockContext(riGan: mingPanStore.currentRiGanForAssistant())
        let excerpt = buildRecentDialogueExcerpt()
        do {
            let raw = try await ZhijiMiniMax.client.fetchQuestionsJSON(
                systemPrompt: BaziPrompts.followUpSystem(),
                userPrompt: BaziPrompts.followUpUser(
                    panSummary: ctx,
                    userQuestion: userQuestion,
                    assistantReply: assistantReply,
                    dialogueClock: clock,
                    recentDialogue: excerpt
                ),
                temperature: 0.52,
                maxTokens: 400
            )
            return Self.normalizeToThreeQuestions(raw)
        } catch {
            return Self.normalizeToThreeQuestions([])
        }
    }

    /// 取近期若干轮对话文本，供追问模型理解多轮语境（截断防超长）。
    private func buildRecentDialogueExcerpt() -> String {
        let slice = Array(messages.suffix(12))
        var lines: [String] = []
        for msg in slice {
            let role = msg.role == .user ? "用户" : "助手"
            var text = msg.content.trimmingCharacters(in: .whitespacesAndNewlines)
            if text.count > 1600 {
                text = String(text.prefix(1600)) + "…"
            }
            guard !text.isEmpty else { continue }
            lines.append("\(role)：\(text)")
        }
        var joined = lines.joined(separator: "\n\n")
        if joined.count > 5000 {
            joined = String(joined.suffix(5000))
            joined = "…（更早对话已省略）\n\n" + joined
        }
        return joined
    }

    /// 从本地知识包挑选与本问最相关的证据块，减少模型凭空补全。
    private func buildEvidencePacket(question: String, pack: AssistantKnowledgePack?) -> String {
        guard let pack, !pack.chunks.isEmpty else {
            return "（无本地知识包）"
        }
        let chunks = selectEvidenceChunks(question: question, chunks: pack.chunks, limit: 6)
        guard !chunks.isEmpty else {
            return "（知识包存在，但本问未召回到相关证据块）"
        }
        let header = "知识包版本 v\(pack.version)，来源 \(pack.source)"
        let body = chunks.map { c in
            "[\(c.id)] \(c.category)\n\(c.text)"
        }.joined(separator: "\n\n")
        return "\(header)\n\n\(body)"
    }

    private func selectEvidenceChunks(
        question: String,
        chunks: [AssistantFactChunk],
        limit: Int
    ) -> [AssistantFactChunk] {
        let q = question.trimmingCharacters(in: .whitespacesAndNewlines)
        if q.isEmpty { return Array(chunks.prefix(limit)) }
        let year = extractFirstYear(from: q)
        let hints = [
            "今年", "当前", "时间", "公历", "日主", "四柱", "大运", "流年", "流月", "流日",
            "十神", "喜神", "忌神", "刑冲", "干支", "起运", "前五年", "后五年", "十年"
        ]
        let matchedHints = hints.filter { q.contains($0) }

        let scored = chunks.map { chunk -> (AssistantFactChunk, Int) in
            var score = 0
            if let y = year, chunk.text.contains(y) { score += 8 }
            for hint in matchedHints where chunk.text.contains(hint) { score += 2 }
            if chunk.category.contains("大运") || chunk.category.contains("流年") { score += matchedHints.contains("流年") ? 2 : 0 }
            if chunk.category.contains("四柱十神") { score += matchedHints.contains("十神") ? 2 : 0 }
            if chunk.category.contains("流月") || chunk.category.contains("流日") { score += matchedHints.contains("流月") || matchedHints.contains("流日") ? 2 : 0 }
            return (chunk, score)
        }
        let sorted = scored
            .sorted { lhs, rhs in
                if lhs.1 == rhs.1 { return lhs.0.id < rhs.0.id }
                return lhs.1 > rhs.1
            }
            .filter { $0.1 > 0 }
            .map { $0.0 }
        if !sorted.isEmpty { return Array(sorted.prefix(limit)) }
        return Array(chunks.prefix(min(3, limit)))
    }

    private func extractFirstYear(from text: String) -> String? {
        let pattern = #"(19|20)\d{2}"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let hit = regex.firstMatch(in: text, range: range),
              let r = Range(hit.range, in: text) else { return nil }
        return String(text[r])
    }

    /// 去重并补足至 3 条，避免接口返回不足或为空时无芯片可点。
    private static func normalizeToThreeQuestions(_ raw: [String]) -> [String] {
        var seen = Set<String>()
        var out: [String] = []
        for q in raw {
            let t = q.trimmingCharacters(in: .whitespacesAndNewlines)
            guard t.count >= 2, !seen.contains(t) else { continue }
            seen.insert(t)
            out.append(t)
            if out.count == 3 { break }
        }
        let pad = [
            "能结合我的四柱再具体说说吗？",
            "这和当前大运、流年怎么一起看？",
            "有没有常见的理解误区要注意？"
        ]
        var i = 0
        while out.count < 3, i < pad.count {
            let p = pad[i]
            i += 1
            guard !seen.contains(p) else { continue }
            out.append(p)
            seen.insert(p)
        }
        return Array(out.prefix(3))
    }

    func clearHistory() {
        messages = []
        suggestedQuestions = []
        isLoadingSuggestedQuestions = false
        try? FileManager.default.removeItem(at: historyURL)
        Task { await loadSuggestedQuestionsIfNeeded(force: true) }
    }

    func deleteMessage(_ id: UUID) {
        guard !isStreaming, let idx = messages.firstIndex(where: { $0.id == id }) else { return }
        messages.remove(at: idx)
        saveHistory()
        if messages.isEmpty {
            suggestedQuestions = []
            Task { await loadSuggestedQuestionsIfNeeded(force: true) }
        }
    }

    /// 刷新用户提问：用于「助手繁忙/失败」时重试最后一条提问，不新增重复用户气泡。
    func refreshUserMessage(_ id: UUID) async {
        guard !isStreaming else { return }
        guard let userIndex = messages.firstIndex(where: { $0.id == id && $0.role == .user }) else { return }
        guard userIndex == messages.indices.last(where: { messages[$0].role == .user }) else {
            showApiToast("仅支持刷新最后一条提问")
            return
        }

        let userQuestion = messages[userIndex].content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userQuestion.isEmpty else {
            showApiToast("提问内容为空，无法刷新")
            return
        }

        if messages.indices.contains(userIndex + 1), messages[userIndex + 1].role == .assistant {
            messages.remove(at: userIndex + 1)
        }

        let now = Date()
        let today = gregorianLocalCalendar().startOfDay(for: now)
        let assistantId = UUID()
        messages.append(ChatMessage(
            id: assistantId,
            role: .assistant,
            content: "",
            isStreaming: true,
            sessionDate: today
        ))

        let apiHistory: [MiniMaxMessage] = messages
            .prefix(userIndex + 1)
            .suffix(Self.maxHistoryMessages)
            .compactMap { msg in
                guard !msg.content.isEmpty else { return nil }
                return MiniMaxMessage(role: msg.role.rawValue, content: msg.content)
            }

        let pack = mingPanStore.currentAssistantKnowledgePack()
        let capturedPan = pack?.summary ?? mingPanStore.currentAssistantPanSummary()
        let dialogueClock = BaziPrompts.dialogueClockContext(riGan: mingPanStore.currentRiGanForAssistant(), now: now)
        let evidencePacket = buildEvidencePacket(question: userQuestion, pack: pack)
        let principles = AssistantPrinciplesProvider.load()

        isStreaming = true
        let systemPrompt = BaziPrompts.chatSystemPrompt(
            panSummary: capturedPan,
            dialogueClock: dialogueClock,
            evidencePacket: evidencePacket,
            principles: principles
        )
        var streamSucceeded = false
        do {
            _ = try await ZhijiMiniMax.client.streamChat(
                history: apiHistory,
                systemPrompt: systemPrompt,
                temperature: 0.42,
                onToken: { [weak self] token in
                    Task { @MainActor [weak self] in
                        guard let self,
                              let idx = self.messages.firstIndex(where: { $0.id == assistantId })
                        else { return }
                        self.messages[idx].content += token
                    }
                },
                onThinking: { [weak self] thinking in
                    Task { @MainActor [weak self] in
                        guard let self,
                              let idx = self.messages.firstIndex(where: { $0.id == assistantId })
                        else { return }
                        self.messages[idx].thinkingText = thinking
                    }
                }
            )
            streamSucceeded = true
        } catch {
            if let idx = messages.firstIndex(where: { $0.id == assistantId }) {
                messages[idx].content = "抱歉，出了点小问题，请再试一次 🙏"
            }
            showApiToast(error.localizedDescription)
        }

        if let idx = messages.firstIndex(where: { $0.id == assistantId }) {
            messages[idx].isStreaming = false
        }
        isStreaming = false
        saveHistory()

        if streamSucceeded,
           let i = messages.firstIndex(where: { $0.id == assistantId }) {
            let reply = messages[i].content.trimmingCharacters(in: .whitespacesAndNewlines)
            if !reply.isEmpty {
                let followUps = await fetchContextualFollowUpQuestions(
                    userQuestion: userQuestion,
                    assistantReply: messages[i].content
                )
                if !followUps.isEmpty {
                    var updated = messages[i]
                    updated.followUpQuestions = followUps
                    messages[i] = updated
                    followUpChipsRevision += 1
                    saveHistory()
                }
            }
        }
    }

    /// 仅刷新最后一条助手回复，避免中间重刷导致后续上下文失真。
    func refreshAssistantReply(_ id: UUID) async {
        guard !isStreaming else { return }
        guard let assistantIndex = messages.firstIndex(where: { $0.id == id && $0.role == .assistant }) else { return }
        guard assistantIndex == messages.indices.last(where: { messages[$0].role == .assistant }) else {
            showApiToast("仅支持刷新最后一条 AI 回复")
            return
        }

        var userIndex: Int?
        if assistantIndex > 0 {
            for idx in stride(from: assistantIndex - 1, through: 0, by: -1) where messages[idx].role == .user {
                userIndex = idx
                break
            }
        }
        guard let userIndex else {
            showApiToast("未找到可刷新的提问")
            return
        }

        let userQuestion = messages[userIndex].content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userQuestion.isEmpty else {
            showApiToast("提问内容为空，无法刷新")
            return
        }

        let apiHistory: [MiniMaxMessage] = messages
            .prefix(userIndex + 1)
            .suffix(Self.maxHistoryMessages)
            .compactMap { msg in
                guard !msg.content.isEmpty else { return nil }
                return MiniMaxMessage(role: msg.role.rawValue, content: msg.content)
            }

        let now = Date()
        let pack = mingPanStore.currentAssistantKnowledgePack()
        let capturedPan = pack?.summary ?? mingPanStore.currentAssistantPanSummary()
        let dialogueClock = BaziPrompts.dialogueClockContext(riGan: mingPanStore.currentRiGanForAssistant(), now: now)
        let evidencePacket = buildEvidencePacket(question: userQuestion, pack: pack)
        let principles = AssistantPrinciplesProvider.load()

        messages[assistantIndex].content = ""
        messages[assistantIndex].thinkingText = nil
        messages[assistantIndex].followUpQuestions = nil
        messages[assistantIndex].isStreaming = true

        isStreaming = true
        let systemPrompt = BaziPrompts.chatSystemPrompt(
            panSummary: capturedPan,
            dialogueClock: dialogueClock,
            evidencePacket: evidencePacket,
            principles: principles
        )
        var streamSucceeded = false
        do {
            _ = try await ZhijiMiniMax.client.streamChat(
                history: apiHistory,
                systemPrompt: systemPrompt,
                temperature: 0.42,
                onToken: { [weak self] token in
                    Task { @MainActor [weak self] in
                        guard let self,
                              let idx = self.messages.firstIndex(where: { $0.id == id })
                        else { return }
                        self.messages[idx].content += token
                    }
                },
                onThinking: { [weak self] thinking in
                    Task { @MainActor [weak self] in
                        guard let self,
                              let idx = self.messages.firstIndex(where: { $0.id == id })
                        else { return }
                        self.messages[idx].thinkingText = thinking
                    }
                }
            )
            streamSucceeded = true
        } catch {
            if let idx = messages.firstIndex(where: { $0.id == id }) {
                messages[idx].content = "抱歉，出了点小问题，请再试一次 🙏"
            }
            showApiToast(error.localizedDescription)
        }

        if let idx = messages.firstIndex(where: { $0.id == id }) {
            messages[idx].isStreaming = false
        }
        isStreaming = false
        saveHistory()

        if streamSucceeded,
           let i = messages.firstIndex(where: { $0.id == id }) {
            let reply = messages[i].content.trimmingCharacters(in: .whitespacesAndNewlines)
            if !reply.isEmpty {
                let followUps = await fetchContextualFollowUpQuestions(
                    userQuestion: userQuestion,
                    assistantReply: messages[i].content
                )
                if !followUps.isEmpty {
                    var updated = messages[i]
                    updated.followUpQuestions = followUps
                    messages[i] = updated
                    followUpChipsRevision += 1
                    saveHistory()
                }
            }
        }
    }

    private func saveHistory() {
        let encoder = JSONEncoder()
        let toSave = messages.filter { !$0.isStreaming }
        guard let data = try? encoder.encode(toSave) else { return }
        try? data.write(to: historyURL, options: .atomic)
    }

    private func loadHistory() {
        guard let data = try? Data(contentsOf: historyURL),
              let saved = try? JSONDecoder().decode([ChatMessage].self, from: data)
        else { return }
        messages = saved.map {
            var m = $0
            m.isStreaming = false
            return m
        }
    }

    private func showApiToast(_ message: String) {
        toastClearTask?.cancel()
        apiErrorToast = message
        toastClearTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard !Task.isCancelled else { return }
            apiErrorToast = nil
        }
    }
}
