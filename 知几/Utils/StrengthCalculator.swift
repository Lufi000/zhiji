import Foundation

// MARK: - 身强身弱计算常量

/// 身强身弱判定阈值
///
/// 计算原理：八字中共有8个位置（4天干+4地支），总分100分
/// - 天干权重较低（年干5、月干5、时干5 = 15分）
/// - 地支权重较高（年支20、月支35、日支20、时支10 = 85分）
/// - 月支（月令）权重最高，因为"得令者旺"
///
/// 判定标准：
/// - 极强(≥80)：同类五行占据绝大多数位置，几乎无克泄耗
/// - 身强(46-79)：同类五行占优势，得月令或多处帮扶
/// - 身弱(21-45)：异类五行占优势，缺乏帮扶
/// - 极弱(<21)：同类五行极少，几乎全是克泄耗
private enum StrengthThreshold {
    static let veryStrong = 80
    static let strong = 46
    static let weak = 21
}

// MARK: - 身强身弱计算结果

struct StrengthResult {
    let strength: String   // "极强"、"身强"、"身弱"、"极弱"
    let score: Int
    let details: String
}

struct XiYongShenResult {
    let xi: [String]   // 喜神五行
    let ji: [String]   // 忌神五行
}

struct TiaoHouResult {
    let tiaoHou: String?   // 调候用神
    let reason: String?    // 调候原因说明
}

// MARK: - 身强身弱计算器

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

    /// 计算身强身弱
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

    /// 根据分数判断身强身弱等级
    private func determineStrength(score: Int) -> String {
        switch score {
        case StrengthThreshold.veryStrong...:
            return "极强"
        case StrengthThreshold.strong..<StrengthThreshold.veryStrong:
            return "身强"
        case StrengthThreshold.weak..<StrengthThreshold.strong:
            return "身弱"
        default:
            return "极弱"
        }
    }

    /// 计算喜用神
    func calculateXiYongShen(strength: String) -> XiYongShenResult {
        let dayWx = BaziConstants.wuXing[bazi.day.gan] ?? "木"

        // 生我者（印星）
        let shengWoWx = BaziConstants.wuXingSheng.first { $0.value == dayWx }?.key ?? ""
        // 我生者（食伤）
        let woShengWx = BaziConstants.wuXingSheng[dayWx] ?? ""
        // 克我者（官杀）
        let keWoWx = BaziConstants.wuXingKe.first { $0.value == dayWx }?.key ?? ""
        // 我克者（财星）
        let woKeWx = BaziConstants.wuXingKe[dayWx] ?? ""

        switch strength {
        case "身强", "极强":
            // 身强喜克泄耗：官杀、食伤、财星
            return XiYongShenResult(xi: [keWoWx, woShengWx, woKeWx], ji: [shengWoWx, dayWx])

        case "身弱", "极弱":
            // 身弱喜生扶：印星、比劫
            return XiYongShenResult(xi: [shengWoWx, dayWx], ji: [keWoWx, woShengWx, woKeWx])

        case "从强":
            // 从强格：顺从强势，喜生扶
            return XiYongShenResult(xi: [shengWoWx, dayWx], ji: [keWoWx, woShengWx, woKeWx])

        case "从弱":
            // 从弱格：顺从弱势，喜克泄耗
            return XiYongShenResult(xi: [keWoWx, woShengWx, woKeWx], ji: [shengWoWx, dayWx])

        default:
            // 默认按身弱处理
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
