import Foundation

/// 与排盘结果联动：排盘完成或复制命盘时写入，供 AI 助手 Tab 注入 system prompt。
enum BaziAssistantContext {
    static let userDefaultsKey = "zhiji.lastPanContextForAssistant"
    /// 与 `userDefaultsKey` 同步写入，供【对话时刻】按日主推算流年/流月/流日十神（与四柱算法一致）。
    static let lastRiGanKey = "zhiji.lastPanRiGanForAssistant"
    /// 本地事实知识包（NotebookLM 风格单一可信资料源）。
    static let knowledgePackKey = "zhiji.lastAssistantKnowledgePack"

    /// 排盘摘要写入 UserDefaults 后发出，便于助手空对话时刷新「你可能想问」。
    static let panContextDidUpdateNotification = Notification.Name("zhiji.panContextDidUpdate")

    /// 最近一次排盘或「复制到 AI」写入的摘要（未使用已保存命盘时的回退）。
    static func storedPanSummaryFromDefaults() -> String {
        UserDefaults.standard.string(forKey: userDefaultsKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    static func storedKnowledgePackFromDefaults() -> AssistantKnowledgePack? {
        guard let data = UserDefaults.standard.data(forKey: knowledgePackKey) else { return nil }
        return try? JSONDecoder().decode(AssistantKnowledgePack.self, from: data)
    }
}
