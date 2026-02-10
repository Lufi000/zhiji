import Foundation

// MARK: - 五行能量统计模型

/// 单个五行的能量分析
struct WuXingEnergyItem {
    let wuXing: String          // 五行名称
    let count: Int              // 出现次数（天干地支）
    let tianGanCount: Int       // 天干出现次数
    let diZhiCount: Int         // 地支出现次数
    let cangGanCount: Int       // 藏干出现次数
    let percentage: Double      // 占比（基于总权重）
    let strength: String        // 强度描述："极旺"、"偏旺"、"中和"、"偏弱"、"极弱"
}

/// 五行能量整体分析结果
struct WuXingEnergyResult {
    let energyItems: [WuXingEnergyItem]  // 五行能量列表（按能量排序）
    let dayMasterWuXing: String          // 日主五行
    let strongestWuXing: String          // 最旺五行
    let weakestWuXing: String            // 最弱五行
    let missingWuXing: [String]          // 缺失的五行
    let interpretation: String           // 整体解读
}

// MARK: - 五行能量分析器

struct WuXingEnergyAnalyzer {
    let bazi: Bazi

    /// 各位置的权重（用于计算五行能量占比）
    /// 地支权重为天干的3倍，月令最重
    private let positionWeights: [String: Double] = [
        "年干": 1.0, "年支": 3.0,
        "月干": 1.2, "月支": 4.5,  // 月令最重（1.5 * 3）
        "日干": 1.0, "日支": 3.0,
        "时干": 1.0, "时支": 3.0
    ]

    /// 藏干权重（主气、中气、余气）
    private let cangGanWeights: [Double] = [0.6, 0.3, 0.1]

    /// 分析五行能量分布
    func analyze() -> WuXingEnergyResult {
        // 统计各五行的基础数量
        var wuXingTianGan: [String: Int] = ["木": 0, "火": 0, "土": 0, "金": 0, "水": 0]
        var wuXingDiZhi: [String: Int] = ["木": 0, "火": 0, "土": 0, "金": 0, "水": 0]
        var wuXingCangGan: [String: Int] = ["木": 0, "火": 0, "土": 0, "金": 0, "水": 0]
        var wuXingWeightedScore: [String: Double] = ["木": 0, "火": 0, "土": 0, "金": 0, "水": 0]

        let pillars = [
            ("年", bazi.year),
            ("月", bazi.month),
            ("日", bazi.day),
            ("时", bazi.hour)
        ]

        // 统计天干
        for (pos, pillar) in pillars {
            if let wx = BaziConstants.wuXing[pillar.gan] {
                wuXingTianGan[wx, default: 0] += 1
                let weight = positionWeights["\(pos)干"] ?? 1.0
                wuXingWeightedScore[wx, default: 0] += weight
            }
        }

        // 统计地支
        for (pos, pillar) in pillars {
            if let wx = BaziConstants.wuXing[pillar.zhi] {
                wuXingDiZhi[wx, default: 0] += 1
                let weight = positionWeights["\(pos)支"] ?? 1.0
                wuXingWeightedScore[wx, default: 0] += weight
            }

            // 统计藏干
            if let cangGans = BaziConstants.cangGan[pillar.zhi] {
                for (index, cangGan) in cangGans.enumerated() {
                    if let wx = BaziConstants.wuXing[cangGan] {
                        wuXingCangGan[wx, default: 0] += 1
                        let cangWeight = index < cangGanWeights.count ? cangGanWeights[index] : 0.1
                        let posWeight = positionWeights["\(pos)支"] ?? 1.0
                        wuXingWeightedScore[wx, default: 0] += cangWeight * posWeight * 0.5
                    }
                }
            }
        }

        // 计算合、会、库对五行能量的增强
        let analysis = analyzeWuXingRelations(bazi: bazi)
        applyHeHuiKuBonus(analysis: analysis, wuXingWeightedScore: &wuXingWeightedScore)

        // 计算总权重
        let totalWeight = wuXingWeightedScore.values.reduce(0, +)

        // 构建能量项目列表
        var energyItems: [WuXingEnergyItem] = []
        let allWuXing = ["木", "火", "土", "金", "水"]

        for wx in allWuXing {
            let tianGan = wuXingTianGan[wx] ?? 0
            let diZhi = wuXingDiZhi[wx] ?? 0
            let cangGan = wuXingCangGan[wx] ?? 0
            let score = wuXingWeightedScore[wx] ?? 0
            let percentage = totalWeight > 0 ? (score / totalWeight) * 100 : 0

            let strength = getStrengthDescription(percentage: percentage)

            energyItems.append(WuXingEnergyItem(
                wuXing: wx,
                count: tianGan + diZhi,
                tianGanCount: tianGan,
                diZhiCount: diZhi,
                cangGanCount: cangGan,
                percentage: percentage,
                strength: strength
            ))
        }

        // 按能量排序（从高到低）
        energyItems.sort { $0.percentage > $1.percentage }

        // 找出最旺、最弱、缺失的五行
        let strongestWuXing = energyItems.first?.wuXing ?? "木"
        let weakestWuXing = energyItems.last?.wuXing ?? "水"
        let missingWuXing = energyItems.filter { $0.count == 0 && $0.cangGanCount == 0 }.map { $0.wuXing }

        // 日主五行
        let dayMasterWuXing = BaziConstants.wuXing[bazi.day.gan] ?? "木"

        // 生成解读
        let interpretation = generateInterpretation(
            energyItems: energyItems,
            dayMasterWuXing: dayMasterWuXing,
            strongestWuXing: strongestWuXing,
            weakestWuXing: weakestWuXing,
            missingWuXing: missingWuXing
        )

        return WuXingEnergyResult(
            energyItems: energyItems,
            dayMasterWuXing: dayMasterWuXing,
            strongestWuXing: strongestWuXing,
            weakestWuXing: weakestWuXing,
            missingWuXing: missingWuXing,
            interpretation: interpretation
        )
    }

    /// 获取强度描述
    private func getStrengthDescription(percentage: Double) -> String {
        switch percentage {
        case 30...: return "极旺"
        case 23..<30: return "偏旺"
        case 17..<23: return "中和"
        case 10..<17: return "偏弱"
        default: return "极弱"
        }
    }

    /// 生成整体解读
    private func generateInterpretation(
        energyItems: [WuXingEnergyItem],
        dayMasterWuXing: String,
        strongestWuXing: String,
        weakestWuXing: String,
        missingWuXing: [String]
    ) -> String {
        var parts: [String] = []

        // 日主五行能量状态
        if let dayItem = energyItems.first(where: { $0.wuXing == dayMasterWuXing }) {
            let dayStatus = getDayMasterStatus(item: dayItem, allItems: energyItems)
            parts.append("日主\(dayMasterWuXing)：\(dayStatus)")
        }

        // 最旺五行
        if strongestWuXing != dayMasterWuXing {
            let relation = getWuXingRelation(from: strongestWuXing, to: dayMasterWuXing)
            parts.append("\(strongestWuXing)气最旺（\(relation)）")
        }

        // 缺失五行
        if !missingWuXing.isEmpty {
            let missingRelations = missingWuXing.map { wx in
                let relation = getWuXingRelation(from: wx, to: dayMasterWuXing)
                return "\(wx)(\(relation))"
            }
            parts.append("缺\(missingRelations.joined(separator: "、"))")
        }

        return parts.joined(separator: "；")
    }

    /// 获取日主状态描述
    private func getDayMasterStatus(item: WuXingEnergyItem, allItems: [WuXingEnergyItem]) -> String {
        // 计算同类五行（比劫+印）的总能量
        let shengWoWx = BaziConstants.wuXingSheng.first { $0.value == item.wuXing }?.key ?? ""
        let tongLeiItems = allItems.filter { $0.wuXing == item.wuXing || $0.wuXing == shengWoWx }
        let tongLeiPercentage = tongLeiItems.reduce(0) { $0 + $1.percentage }

        switch tongLeiPercentage {
        case 50...: return "得助很强"
        case 40..<50: return "得助较强"
        case 30..<40: return "得助中等"
        case 20..<30: return "得助较弱"
        default: return "孤立无援"
        }
    }

    /// 获取五行与日主的关系
    private func getWuXingRelation(from wx: String, to dayWx: String) -> String {
        if wx == dayWx {
            return "比劫"
        } else if BaziConstants.wuXingSheng[wx] == dayWx {
            return "生我·印"
        } else if BaziConstants.wuXingSheng[dayWx] == wx {
            return "我生·食伤"
        } else if BaziConstants.wuXingKe[wx] == dayWx {
            return "克我·官杀"
        } else if BaziConstants.wuXingKe[dayWx] == wx {
            return "我克·财"
        }
        return ""
    }

    /// 应用合、会、库对五行能量的增强
    private func applyHeHuiKuBonus(analysis: WuXingAnalysis, wuXingWeightedScore: inout [String: Double]) {
        // 处理合的增强
        for he in analysis.heResults {
            switch he.type {
            case .tianGanHe:
                // 天干合化成功时增强化出的五行
                if let huaWx = he.huaWuXing {
                    wuXingWeightedScore[huaWx, default: 0] += 1.5
                }

            case .diZhiLiuHe:
                // 地支六合增强合化的五行
                if let huaWx = he.huaWuXing {
                    wuXingWeightedScore[huaWx, default: 0] += 1.2
                }

            case .diZhiSanHe:
                // 地支三合：完全三合增强更多，半合也有增强
                if let huaWx = he.huaWuXing {
                    // 完全三合
                    wuXingWeightedScore[huaWx, default: 0] += 2.0
                } else if let banHeWx = he.banHeWuXing {
                    // 半合
                    wuXingWeightedScore[banHeWx, default: 0] += 1.0
                }

            case .diZhiSanHui:
                // 地支三会：完全三会增强最多，半会也有增强
                if let huaWx = he.huaWuXing {
                    // 完全三会
                    wuXingWeightedScore[huaWx, default: 0] += 2.5
                } else if let banHeWx = he.banHeWuXing {
                    // 半会
                    wuXingWeightedScore[banHeWx, default: 0] += 1.2
                }
            }
        }

        // 处理库的增强
        for ku in analysis.kuResults {
            if ku.isFormed, let kuWx = ku.kuWuXing {
                // 形成库时增强对应五行
                wuXingWeightedScore[kuWx, default: 0] += 1.0
            }
        }
    }
}
