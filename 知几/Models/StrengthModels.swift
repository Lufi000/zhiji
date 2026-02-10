import Foundation

// MARK: - 能量配置计算结果（Domain 层，Utils 仅负责计算并返回）

/// 能量配置计算结果
/// - Note: 由 `StrengthCalculator` 计算，ViewModel/Report 使用
struct StrengthResult {
    let strength: String   // 能量配置模式："自主型"、"均衡型"、"协作型"
    let score: Int
    let details: String
}

/// 喜用神计算结果
struct XiYongShenResult {
    let xi: [String]   // 喜神五行
    let ji: [String]   // 忌神五行
}

/// 调候用神计算结果
struct TiaoHouResult {
    let tiaoHou: String?   // 调候用神
    let reason: String?    // 调候原因说明
}
