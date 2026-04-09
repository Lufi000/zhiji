import Foundation
import Observation

/// 本地持久化：多条命盘、「我的命盘」、助手当前选用的命盘。
@Observable
@MainActor
final class MingPanStore {
    private enum Keys {
        static let records = "zhiji.savedMingPanRecords"
        static let selfId = "zhiji.selfMingPanId"
        static let assistantOverrideId = "zhiji.assistantMingPanOverrideId"
    }

    private let defaults = UserDefaults.standard

    private(set) var records: [SavedMingPanRecord] = []

    /// 标记为「我的命盘」，助手默认使用此盘（可被助手内切换覆盖）。
    var selfMingPanId: UUID? {
        didSet { persistSelfId() }
    }

    /// 非 nil 时，助手使用指定 id；nil 表示跟随「我的命盘」。
    var assistantOverrideMingPanId: UUID? {
        didSet { persistAssistantOverride() }
    }

    init() {
        load()
    }

    /// 助手注入用的摘要：优先已保存命盘解析顺序，否则最近一次排盘写入的 UserDefaults。
    func currentAssistantPanSummary() -> String {
        if let id = resolvedAssistantMingPanId(),
           let record = records.first(where: { $0.id == id }) {
            return MingPanSummaryBuilder.assistantPanSummary(record: record)
        }
        return BaziAssistantContext.storedPanSummaryFromDefaults()
    }

    /// 当前助手语境的日主天干，用于【对话时刻】流年/流月/流日十神（与已保存命盘或最近一次排盘一致）。
    func currentRiGanForAssistant() -> String? {
        if let id = resolvedAssistantMingPanId(),
           let record = records.first(where: { $0.id == id }) {
            return record.bazi.day.gan
        }
        let g = UserDefaults.standard.string(forKey: BaziAssistantContext.lastRiGanKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return g.isEmpty ? nil : g
    }

    /// 本地可信资料源：优先当前选中保存命盘构建知识包；否则回退最近一次排盘已持久化知识包。
    func currentAssistantKnowledgePack() -> AssistantKnowledgePack? {
        if let id = resolvedAssistantMingPanId(),
           let record = records.first(where: { $0.id == id }) {
            let summary = MingPanSummaryBuilder.assistantPanSummary(record: record)
            return AssistantKnowledgePack.fromSummary(
                summary: summary,
                riGan: record.bazi.day.gan,
                source: "saved_record",
                sourceRecordId: record.id
            )
        }
        return BaziAssistantContext.storedKnowledgePackFromDefaults()
    }

    /// 助手菜单当前应高亮的命盘 id：显式覆盖 > 「我的命盘」；若均未设置则回退到最近一次排盘（UserDefaults），不自动选用某条已保存记录。
    func resolvedAssistantMingPanId() -> UUID? {
        if let o = assistantOverrideMingPanId, records.contains(where: { $0.id == o }) {
            return o
        }
        if let s = selfMingPanId, records.contains(where: { $0.id == s }) {
            return s
        }
        return nil
    }

    func add(record: SavedMingPanRecord, setAsSelf: Bool) {
        records.append(record)
        if setAsSelf {
            selfMingPanId = record.id
            assistantOverrideMingPanId = nil
        }
        persistRecords()
        notifyAssistantContextChanged()
    }

    func delete(id: UUID) {
        records.removeAll { $0.id == id }
        if selfMingPanId == id { selfMingPanId = nil }
        if assistantOverrideMingPanId == id { assistantOverrideMingPanId = nil }
        persistRecords()
        notifyAssistantContextChanged()
    }

    func rename(id: UUID, displayName: String) {
        guard let i = records.firstIndex(where: { $0.id == id }) else { return }
        records[i].displayName = displayName
        persistRecords()
    }

    func setSelfMingPan(id: UUID?) {
        selfMingPanId = id
        notifyAssistantContextChanged()
    }

    func setAssistantMingPan(id: UUID?) {
        assistantOverrideMingPanId = id
        notifyAssistantContextChanged()
    }

    /// 使用「我的命盘」作为助手上下文（清除显式覆盖）。
    func useSelfMingPanForAssistant() {
        assistantOverrideMingPanId = nil
        notifyAssistantContextChanged()
    }

    private func notifyAssistantContextChanged() {
        NotificationCenter.default.post(name: BaziAssistantContext.panContextDidUpdateNotification, object: nil)
    }

    private func load() {
        if let data = defaults.data(forKey: Keys.records),
           let decoded = try? JSONDecoder().decode([SavedMingPanRecord].self, from: data) {
            records = decoded
        }
        if let s = defaults.string(forKey: Keys.selfId), let u = UUID(uuidString: s) {
            selfMingPanId = u
        }
        if let s = defaults.string(forKey: Keys.assistantOverrideId), let u = UUID(uuidString: s) {
            assistantOverrideMingPanId = u
        }
    }

    private func persistRecords() {
        if let data = try? JSONEncoder().encode(records) {
            defaults.set(data, forKey: Keys.records)
        }
    }

    private func persistSelfId() {
        if let id = selfMingPanId {
            defaults.set(id.uuidString, forKey: Keys.selfId)
        } else {
            defaults.removeObject(forKey: Keys.selfId)
        }
    }

    private func persistAssistantOverride() {
        if let id = assistantOverrideMingPanId {
            defaults.set(id.uuidString, forKey: Keys.assistantOverrideId)
        } else {
            defaults.removeObject(forKey: Keys.assistantOverrideId)
        }
    }
}
