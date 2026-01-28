import Foundation

// MARK: - 十神分析数据模型

/// 根气类型
enum RootType: String {
    case benQi = "本气"      // 地支藏干第一位，力量最强
    case zhongQi = "中气"    // 地支藏干第二位，力量中等
    case yuQi = "余气"       // 地支藏干第三位，力量较弱
}

/// 根气信息
struct RootInfo {
    let position: String     // 位置（年支、月支、日支、时支）
    let zhi: String          // 地支
    let rootType: RootType   // 根气类型
    let weight: Double       // 权重
}

/// 十神详细信息（干支一体分析）
struct ShiShenDetail: Identifiable {
    let id = UUID()
    let shiShen: String              // 十神名称
    let tianGanPositions: [String]   // 天干透出位置
    let roots: [RootInfo]            // 根气信息
    let totalScore: Double           // 综合得分
    let hasRoot: Bool                // 是否有根
    let isTouChu: Bool               // 是否透出天干
    let strengthLevel: String        // 强度等级
}

/// 十神分析结果
struct ShiShenResult {
    let items: [ShiShenDetail]       // 各十神详细分析
    let dominant: String?            // 最旺的十神
    let missing: [String]            // 缺失的十神
}

// MARK: - 十神分析器（干支一体，地支为基）

struct ShiShenAnalyzer {
    let bazi: Bazi

    /// 十神列表（固定顺序）
    private let allShiShen = ["比肩", "劫财", "食神", "伤官", "偏财", "正财", "七杀", "正官", "偏印", "正印"]

    /// 位置权重
    private let positionWeights: [String: Double] = [
        "年干": 1.0, "月干": 1.5, "时干": 1.0,
        "年支": 1.2, "月支": 2.5, "日支": 1.8, "时支": 1.2  // 月令最重
    ]

    /// 藏干层次权重
    private let rootWeights: [RootType: Double] = [
        .benQi: 1.0,    // 本气
        .zhongQi: 0.5,  // 中气
        .yuQi: 0.2      // 余气
    ]

    /// 执行十神分析
    func analyze() -> ShiShenResult {
        let riGan = bazi.day.gan

        // 存储每个十神的分析数据
        var shiShenData: [String: (tianGanPositions: [String], roots: [RootInfo], score: Double)] = [:]

        // 初始化
        for ss in allShiShen {
            shiShenData[ss] = ([], [], 0)
        }

        // === 第一步：分析天干透出 ===
        let tianGanPillars: [(String, String)] = [
            ("年干", bazi.year.gan),
            ("月干", bazi.month.gan),
            ("时干", bazi.hour.gan)
        ]

        for (position, gan) in tianGanPillars {
            let ss = getShiShen(riGan: riGan, targetGan: gan)
            if !ss.isEmpty, var data = shiShenData[ss] {
                data.tianGanPositions.append(position)
                // 天干透出基础分
                data.score += positionWeights[position] ?? 1.0
                shiShenData[ss] = data
            }
        }

        // === 第二步：分析地支藏干（根气）===
        let diZhiPillars: [(String, String)] = [
            ("年支", bazi.year.zhi),
            ("月支", bazi.month.zhi),
            ("日支", bazi.day.zhi),
            ("时支", bazi.hour.zhi)
        ]

        for (position, zhi) in diZhiPillars {
            guard let cangGanList = BaziConstants.cangGan[zhi] else { continue }

            for (index, cangGan) in cangGanList.enumerated() {
                let ss = getShiShen(riGan: riGan, targetGan: cangGan)
                if ss.isEmpty { continue }

                guard var data = shiShenData[ss] else { continue }

                // 确定根气类型
                let rootType: RootType
                switch index {
                case 0: rootType = .benQi
                case 1: rootType = .zhongQi
                default: rootType = .yuQi
                }

                // 计算权重 = 位置权重 × 藏干层次权重
                let posWeight = positionWeights[position] ?? 1.0
                let layerWeight = rootWeights[rootType] ?? 0.2
                let weight = posWeight * layerWeight

                let rootInfo = RootInfo(
                    position: position,
                    zhi: zhi,
                    rootType: rootType,
                    weight: weight
                )

                data.roots.append(rootInfo)
                data.score += weight
                shiShenData[ss] = data
            }
        }

        // === 第三步：透干得根加成 ===
        // 天干透出且地支有根，能量更强
        for ss in allShiShen {
            guard var data = shiShenData[ss] else { continue }
            if !data.tianGanPositions.isEmpty && !data.roots.isEmpty {
                // 透干得根加成 30%
                data.score *= 1.3
                shiShenData[ss] = data
            }
        }

        // === 第四步：生成分析结果 ===
        let totalScore = shiShenData.values.reduce(0) { $0 + $1.score }

        var items: [ShiShenDetail] = []
        for ss in allShiShen {
            guard let data = shiShenData[ss] else { continue }

            let hasRoot = !data.roots.isEmpty
            let isTouChu = !data.tianGanPositions.isEmpty
            let strengthLevel = getStrengthLevel(score: data.score, totalScore: totalScore)

            items.append(ShiShenDetail(
                shiShen: ss,
                tianGanPositions: data.tianGanPositions,
                roots: data.roots,
                totalScore: data.score,
                hasRoot: hasRoot,
                isTouChu: isTouChu,
                strengthLevel: strengthLevel
            ))
        }

        // 按得分排序
        let sortedItems = items.sorted { $0.totalScore > $1.totalScore }

        // 找出最旺和缺失的十神
        let dominant = sortedItems.first { $0.totalScore > 0 }?.shiShen
        let missing = items.filter { $0.totalScore == 0 }.map { $0.shiShen }

        return ShiShenResult(
            items: sortedItems,
            dominant: dominant,
            missing: missing
        )
    }

    /// 获取强度等级
    private func getStrengthLevel(score: Double, totalScore: Double) -> String {
        guard totalScore > 0 else { return "无" }
        let percentage = score / totalScore * 100

        switch percentage {
        case 25...: return "极旺"
        case 18..<25: return "偏旺"
        case 12..<18: return "中和"
        case 5..<12: return "偏弱"
        case 0..<5 where score > 0: return "虚浮"
        default: return "无"
        }
    }
}

// MARK: - 旧版兼容（保留 ShiShenItem 用于视图）

struct ShiShenItem: Identifiable {
    let id = UUID()
    let shiShen: String
    let count: Int
    let tianGanCount: Int
    let diZhiCount: Int
    let positions: [String]
    let percentage: Double
    let category: ShiShenCategory
}

enum ShiShenCategory: String {
    case biJie = "比劫"
    case yinXing = "印星"
    case shiShang = "食伤"
    case caiXing = "财星"
    case guanSha = "官杀"

    var description: String {
        switch self {
        case .biJie: return "自我·竞争"
        case .yinXing: return "学习·庇护"
        case .shiShang: return "表达·才华"
        case .caiXing: return "财富·欲望"
        case .guanSha: return "事业·压力"
        }
    }
}

struct ShiShenCategoryStat: Identifiable {
    let id = UUID()
    let category: ShiShenCategory
    let count: Int
    let percentage: Double
    let shiShenList: [String]
}
