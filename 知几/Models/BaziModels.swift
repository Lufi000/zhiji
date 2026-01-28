import Foundation

// MARK: - 基础数据模型

/// 四柱中的单柱（天干+地支）
/// - Note: 请优先使用类型安全的 `GanZhiPillar`，它使用枚举而非字符串
/// - SeeAlso: `GanZhiPillar`
struct Pillar {
    /// 天干（甲乙丙丁戊己庚辛壬癸）
    let gan: String
    /// 地支（子丑寅卯辰巳午未申酉戌亥）
    let zhi: String

    /// 转换为类型安全的 GanZhiPillar
    var toTypeSafe: GanZhiPillar? {
        GanZhiPillar(ganString: gan, zhiString: zhi)
    }
}

/// 八字命盘（四柱八字）
struct Bazi {
    let year: Pillar     // 年柱：代表祖上、父母宫
    let month: Pillar    // 月柱：代表兄弟、父母宫，月令决定五行旺衰
    let day: Pillar      // 日柱：日干为"日主"，代表自己
    let hour: Pillar     // 时柱：代表子女、晚年
    let shengXiao: String
}

/// 大运（每10年一步运）
struct DaYun {
    let gan: String   // 大运天干
    let zhi: String   // 大运地支
    let age: Int      // 起运年龄（虚岁）
}

// MARK: - 五行关系分析模型

/// 合的类型
enum CombinationType: String {
    case tianGanHe = "天干五合"      // 甲己、乙庚、丙辛、丁壬、戊癸
    case diZhiLiuHe = "地支六合"     // 子丑、寅亥、卯戌、辰酉、巳申、午未
    case diZhiSanHe = "地支三合"     // 申子辰、寅午戌、巳酉丑、亥卯未
    case diZhiSanHui = "地支三会"    // 寅卯辰、巳午未、申酉戌、亥子丑
}

// 兼容旧代码
typealias HeType = CombinationType

/// 合的结果
struct CombinationResult {
    let type: CombinationType
    let elements: [String]       // 参与合的元素
    let huaWuXing: String?       // 合化的五行（nil表示合而不化）
    let banHeWuXing: String?     // 半合的五行（三合/三会只有两个时）
    let positions: [String]      // 位置（年、月、日、时）
}

// 兼容旧代码
typealias HeResult = CombinationResult

/// 冲刑破害的结果
struct ClashResult {
    let type: String             // "冲"、"刑"、"破"、"害"
    let elements: [String]       // 参与的元素
    let positions: [String]      // 位置
}

// 兼容旧代码
typealias ChongXingHaiResult = ClashResult

/// 库的结果（辰戌丑未为四库）
struct StorageResult {
    let zhi: String              // 库的地支
    let kuWuXing: String?        // 形成的库五行（nil表示未成库，仍为土）
    let triggerGan: String?      // 触发成库的天干
    let position: String         // 库地支的位置
    let isFormed: Bool           // 是否成库
}

// 兼容旧代码
typealias KuResult = StorageResult

/// 贪生忘克的结果
///
/// 当克日主的五行去生另一个五行时，会减弱其克力
/// 例如：金克木，但金去生水，则金对木的克力减弱
struct GreedyProductionResult {
    let keWuXing: String         // 克日主的五行
    let shengWuXing: String      // 被贪生的五行
    let kePosition: String       // 克者位置
    let shengPosition: String    // 被生者位置
    let description: String
}

// 兼容旧代码
typealias TanShengWangKeResult = GreedyProductionResult

/// 五行关系分析结果
struct WuXingAnalysis {
    let heResults: [CombinationResult]           // 合
    let chongXingHaiResults: [ClashResult]       // 冲刑破害
    let kuResults: [StorageResult]               // 库
    let tanShengWangKeResults: [GreedyProductionResult]  // 贪生忘克
}

// MARK: - 月运势模型

/// 月运势数据
struct MonthlyFortune: Identifiable {
    let id = UUID()
    let year: Int                 // 年份
    let month: Int                // 月份（1-12）
    let gan: String               // 月干
    let zhi: String               // 月支
    let ganShiShen: String        // 天干十神
    let zhiShiShen: String        // 地支十神
    let fortuneScore: Int         // 运势评分（1-100）
    let fortuneLevel: FortuneLevel  // 运势等级
    let keywords: [String]        // 本月关键词
    let advice: String            // 本月建议

    /// 月份显示名称
    var monthName: String {
        "\(month)月"
    }

    /// 判断是否为当前月
    var isCurrentMonth: Bool {
        let calendar = Calendar.current
        let now = Date()
        let currentYear = calendar.component(.year, from: now)
        let currentMonth = calendar.component(.month, from: now)
        return year == currentYear && month == currentMonth
    }
}

// MARK: - 周运势模型

/// 周运势数据
struct WeeklyFortune: Identifiable {
    let id = UUID()
    let weekStartDate: Date      // 周一日期
    let weekEndDate: Date        // 周日日期
    let weekNumber: Int          // 当年第几周
    let gan: String              // 周主干（基于周一日干）
    let zhi: String              // 周主支（基于周一日支）
    let ganShiShen: String       // 天干十神
    let zhiShiShen: String       // 地支十神
    let fortuneScore: Int        // 运势评分（1-100）
    let fortuneLevel: FortuneLevel  // 运势等级
    let keywords: [String]       // 本周关键词
    let advice: String           // 本周建议
}

/// 运势等级
enum FortuneLevel: String {
    case excellent = "大吉"
    case good = "吉"
    case neutral = "平"
    case caution = "小凶"
    case poor = "凶"

    var color: String {
        switch self {
        case .excellent: return "#D35400"  // 橙红（与app主色调一致）
        case .good: return "#4A9F5E"       // 木绿
        case .neutral: return "#8B7355"    // 土棕
        case .caution: return "#F5B041"    // 金黄
        case .poor: return "#2980B9"       // 水蓝
        }
    }

    var icon: String {
        switch self {
        case .excellent: return "sun.max.fill"
        case .good: return "leaf.fill"
        case .neutral: return "circle.fill"
        case .caution: return "exclamationmark.triangle.fill"
        case .poor: return "cloud.fill"
        }
    }
}
