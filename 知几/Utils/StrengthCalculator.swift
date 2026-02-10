import Foundation

// MARK: - 能量配置计算常量

/// 能量配置判定阈值（直接使用能量配置等级）
///
/// 计算原理：八字中共有8个位置（4天干+4地支），总分100分
/// - 天干权重较低（年干5、月干5、时干5 = 15分）
/// - 地支权重较高（年支20、月支35、日支20、时支10 = 85分）
/// - 月支（月令）权重最高，因为"得令者旺"
///
/// 判定标准（能量配置模式：自主型 / 均衡型 / 协作型）：
/// - 自主型(≥46)：同类五行占优势，内在资源较充沛，倾向于独立应对
/// - 均衡型(21-45)：相对均衡，可独立可协作
/// - 协作型(<21)：需要更多补充，倾向于借助外力、协作应对
private enum StrengthThreshold {
    static let strong = 46   // ≥46 → 自主型
    static let weak = 21     // 21..<46 → 均衡型，<21 → 协作型
}

// MARK: - 能量配置计算器（直接输出能量配置等级）
// 结果类型定义在 Models/StrengthModels.swift，此处仅负责计算

struct StrengthCalculator {
    let bazi: Bazi

    /// 各位置的分值权重
    ///
    /// 权重分配依据：
    /// - 月令最重（35分）：月支决定五行旺衰，"得令者旺，失令者衰"
    /// - 年支、日支次之（各20分）：坐下和年柱根基重要
    /// - 时支再次（10分）：时柱影响相对较小
    /// - 天干最轻（各5分）：天干透出但力量较弱，需地支有根才强
    private enum PositionScore {
        static let yearGan = 5
        static let yearZhi = 20
        static let monthGan = 5
        static let monthZhi = 35
        static let dayZhi = 20
        static let hourGan = 5
        static let hourZhi = 10
    }

    private let positionScores: [String: Int] = [
        "年干": PositionScore.yearGan,
        "年支": PositionScore.yearZhi,
        "月干": PositionScore.monthGan,
        "月支": PositionScore.monthZhi,
        "日支": PositionScore.dayZhi,
        "时干": PositionScore.hourGan,
        "时支": PositionScore.hourZhi
    ]

    /// 判断五行是否帮扶日主（同类或生我）
    private func isHelpful(_ wx: String, dayWx: String) -> Bool {
        wx == dayWx || BaziConstants.wuXingSheng[wx] == dayWx
    }

    /// 统计八字中各五行的出现次数
    private func countWuXing() -> [String: Int] {
        var count: [String: Int] = ["木": 0, "火": 0, "土": 0, "金": 0, "水": 0]
        let elements = [
            bazi.year.gan, bazi.year.zhi,
            bazi.month.gan, bazi.month.zhi,
            bazi.day.gan, bazi.day.zhi,
            bazi.hour.gan, bazi.hour.zhi
        ]
        for element in elements {
            if let wx = BaziConstants.wuXing[element] {
                count[wx, default: 0] += 1
            }
        }
        return count
    }

    /// 计算能量配置（直接返回能量配置等级）
    func calculate() -> StrengthResult {
        let dayWx = BaziConstants.wuXing[bazi.day.gan] ?? "木"
        var score = 0
        var details = "日主: \(bazi.day.gan)(\(dayWx))\n\n"

        var energyTransformedPositions: Set<String> = []
        var energyDetails: [String] = []

        let analysis = analyzeWuXingRelations(bazi: bazi)

        // 检查合会转化
        for he in analysis.heResults {
            if let huaWx = he.huaWuXing, isHelpful(huaWx, dayWx: dayWx) {
                for pos in he.positions {
                    let isGan = (he.type == .tianGanHe)
                    let posKey = "\(pos)\(isGan ? "干" : "支")"
                    if !energyTransformedPositions.contains(posKey), let posScore = positionScores[posKey] {
                        energyTransformedPositions.insert(posKey)
                        energyDetails.append("\(he.type.rawValue)\(he.elements.joined())化\(huaWx)助日主，\(posKey)转化 +\(posScore)")
                    }
                }
            }
        }

        // 检查库转化
        for ku in analysis.kuResults {
            if ku.isFormed, let kuWuXing = ku.kuWuXing, isHelpful(kuWuXing, dayWx: dayWx) {
                let posKey = "\(ku.position)支"
                if !energyTransformedPositions.contains(posKey), let posScore = positionScores[posKey] {
                    energyTransformedPositions.insert(posKey)
                    energyDetails.append("\(ku.zhi)成\(kuWuXing)库助日主，\(posKey)转化 +\(posScore)")
                }
            }
        }

        // 检查贪生忘克转化
        for tswk in analysis.tanShengWangKeResults {
            let posKey = tswk.kePosition
            if !energyTransformedPositions.contains(posKey), let posScore = positionScores[posKey] {
                energyTransformedPositions.insert(posKey)
                energyDetails.append("\(tswk.keWuXing)(\(posKey))贪生\(tswk.shengWuXing)忘克，\(posKey)转化 +\(posScore)")
            }
        }

        // 计算基础分
        details += "【基础得分】\n\n"

        let pillars: [(String, String, String, String)] = [
            ("年干", bazi.year.gan, "年支", bazi.year.zhi),
            ("月干", bazi.month.gan, "月支", bazi.month.zhi),
            ("时干", bazi.hour.gan, "时支", bazi.hour.zhi)
        ]

        for (ganPos, gan, zhiPos, zhi) in pillars {
            if let ganWx = BaziConstants.wuXing[gan], isHelpful(ganWx, dayWx: dayWx) {
                let ganScore = positionScores[ganPos] ?? 0
                score += ganScore
                details += "\(ganPos) \(gan)(\(ganWx)) +\(ganScore)\n"
            }
            if let zhiWx = BaziConstants.wuXing[zhi], isHelpful(zhiWx, dayWx: dayWx), !energyTransformedPositions.contains(zhiPos) {
                let zhiScore = positionScores[zhiPos] ?? 0
                score += zhiScore
                details += "\(zhiPos) \(zhi)(\(zhiWx)) +\(zhiScore)\n"
            }
        }

        // 日支单独处理
        if let zhiWx = BaziConstants.wuXing[bazi.day.zhi], isHelpful(zhiWx, dayWx: dayWx), !energyTransformedPositions.contains("日支") {
            score += PositionScore.dayZhi
            details += "日支 \(bazi.day.zhi)(\(zhiWx)) +\(PositionScore.dayZhi)\n"
        }

        // 五行能量转化加分
        if !energyDetails.isEmpty {
            details += "\n【五行能量转化】\n\n"
            for detail in energyDetails {
                if let posScore = detail.components(separatedBy: "+").last?.trimmingCharacters(in: .whitespaces),
                   let scoreValue = Int(posScore) {
                    score += scoreValue
                }
                details += detail + "\n"
            }
        }

        details += "\n总分: \(score)"

        let strength = determineStrength(score: score)

        return StrengthResult(strength: strength, score: score, details: details)
    }

    /// 根据分数判断能量配置模式（自主型 / 均衡型 / 协作型）
    private func determineStrength(score: Int) -> String {
        switch score {
        case StrengthThreshold.strong...:
            return "自主型"
        case StrengthThreshold.weak..<StrengthThreshold.strong:
            return "均衡型"
        default:
            return "协作型"
        }
    }

    /// 计算喜用五行（入参为能量配置模式：自主型/均衡型/协作型）
    func calculateXiYongShen(strength: String) -> XiYongShenResult {
        let dayWx = BaziConstants.wuXing[bazi.day.gan] ?? "木"

        let shengWoWx = BaziConstants.wuXingSheng.first { $0.value == dayWx }?.key ?? ""
        let woShengWx = BaziConstants.wuXingSheng[dayWx] ?? ""
        let keWoWx = BaziConstants.wuXingKe.first { $0.value == dayWx }?.key ?? ""
        let woKeWx = BaziConstants.wuXingKe[dayWx] ?? ""

        switch strength {
        case "自主型":
            return XiYongShenResult(xi: [keWoWx, woShengWx, woKeWx], ji: [shengWoWx, dayWx])
        case "均衡型", "协作型":
            return XiYongShenResult(xi: [shengWoWx, dayWx], ji: [keWoWx, woShengWx, woKeWx])
        default:
            return XiYongShenResult(xi: [shengWoWx, dayWx], ji: [keWoWx, woShengWx, woKeWx])
        }
    }

    /// 计算调候用神
    ///
    /// 调候用神的核心逻辑：
    /// 1. 判断日主五行在月令是否得令（当旺）
    /// 2. 结合月令的寒暖燥湿特性
    /// 3. 综合判断需要什么五行来调和气候
    func calculateTiaoHou() -> TiaoHouResult {
        let dayGan = bazi.day.gan
        let dayWx = BaziConstants.wuXing[dayGan] ?? "木"
        let monthZhi = bazi.month.zhi
        let monthWangWx = BaziConstants.monthWangXing[monthZhi] ?? "土"

        // 月令特性
        let hanYue: Set<String> = ["亥", "子", "丑"]  // 寒月（冬季）
        let reYue: Set<String> = ["巳", "午", "未"]   // 热月（夏季）
        let zaoYue: Set<String> = ["巳", "午", "未", "戌"]  // 燥月

        // 判断日主是否得令
        let isDeLing = (dayWx == monthWangWx) ||
                       (BaziConstants.wuXingSheng[monthWangWx] == dayWx)  // 月令生日主也算有气

        var tiaoHou: String? = nil
        var reason: String? = nil

        // 根据日主五行和月令特性判断调候
        switch dayWx {
        case "木":
            if hanYue.contains(monthZhi) {
                // 木在冬月，水冷木寒，需火暖局
                tiaoHou = "火"
                reason = "暖局"
            } else if reYue.contains(monthZhi) && !isDeLing {
                // 木在夏月失令，火旺木焚，需水润
                tiaoHou = "水"
                reason = "润局"
            }

        case "火":
            if hanYue.contains(monthZhi) {
                // 火在冬月，水旺火熄，需木生火
                tiaoHou = "木"
                reason = "生扶"
            } else if reYue.contains(monthZhi) && isDeLing {
                // 火在夏月得令太旺，需水制
                tiaoHou = "水"
                reason = "润局"
            }

        case "土":
            if hanYue.contains(monthZhi) {
                // 土在冬月，寒土冻结，需火暖
                tiaoHou = "火"
                reason = "暖局"
            } else if zaoYue.contains(monthZhi) {
                // 土在燥月，需水润
                tiaoHou = "水"
                reason = "润局"
            }

        case "金":
            if hanYue.contains(monthZhi) {
                // 金在冬月，金寒水冷，需火暖
                tiaoHou = "火"
                reason = "暖局"
            } else if reYue.contains(monthZhi) {
                // 金在夏月，火旺金熔，需水降温
                tiaoHou = "水"
                reason = "润局"
            }

        case "水":
            if hanYue.contains(monthZhi) && isDeLing {
                // 水在冬月得令，水旺成冰，需火暖
                tiaoHou = "火"
                reason = "暖局"
            } else if reYue.contains(monthZhi) {
                // 水在夏月，火旺水枯，需金生水
                tiaoHou = "金"
                reason = "生扶"
            }

        default:
            break
        }

        return TiaoHouResult(tiaoHou: tiaoHou, reason: reason)
    }
}
