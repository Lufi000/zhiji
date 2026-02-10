import Foundation

// MARK: - 能量配置模式（自主型 / 均衡型 / 协作型）

/// 全 app 统一使用能量配置模式：自主型、均衡型、协作型
/// 描述的是资源配置方式和应对策略偏好，而非能力强弱
struct StrengthTermMapper {

    /// 能量配置选项（用于 UI 与内部）
    static var energyStateOptions: [String] {
        ["自主型", "均衡型", "协作型"]
    }

    /// 兼容旧调用：直接返回入参
    static func toEnergyState(_ strength: String) -> String {
        strength
    }

    /// 兼容旧调用：直接返回入参
    static func toTraditionalTerm(_ strength: String) -> String {
        strength
    }
}
