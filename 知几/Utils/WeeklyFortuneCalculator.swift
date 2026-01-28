import Foundation

// MARK: - 周运势计算器

/// 周运势计算器
/// 基于八字命理计算每周运势
struct WeeklyFortuneCalculator {

    // MARK: - 公开方法

    /// 生成指定周数的周运势列表
    /// - Parameters:
    ///   - riGan: 日主天干
    ///   - bazi: 八字命盘
    ///   - weeksCount: 生成周数（默认12周）
    ///   - startDate: 起始日期（默认当前日期）
    /// - Returns: 周运势数组
    static func generateWeeklyFortunes(
        riGan: String,
        bazi: Bazi,
        weeksCount: Int = 12,
        startDate: Date = Date()
    ) -> [WeeklyFortune] {
        var fortunes: [WeeklyFortune] = []
        let calendar = Calendar.current

        // 获取起始周的周一
        let currentMonday = getMonday(of: startDate)

        for i in 0..<weeksCount {
            if let monday = calendar.date(byAdding: .weekOfYear, value: i, to: currentMonday) {
                let fortune = calculateWeeklyFortune(
                    riGan: riGan,
                    bazi: bazi,
                    weekStartDate: monday
                )
                fortunes.append(fortune)
            }
        }

        return fortunes
    }

    /// 获取当前周的运势
    static func getCurrentWeekFortune(riGan: String, bazi: Bazi) -> WeeklyFortune {
        let monday = getMonday(of: Date())
        return calculateWeeklyFortune(riGan: riGan, bazi: bazi, weekStartDate: monday)
    }

    // MARK: - 私有方法

    /// 计算单周运势
    private static func calculateWeeklyFortune(
        riGan: String,
        bazi: Bazi,
        weekStartDate: Date
    ) -> WeeklyFortune {
        let calendar = Calendar.current

        // 计算周末日期
        let weekEndDate = calendar.date(byAdding: .day, value: 6, to: weekStartDate) ?? weekStartDate

        // 获取周数
        let weekNumber = calendar.component(.weekOfYear, from: weekStartDate)

        // 获取周一的日柱干支
        let components = calendar.dateComponents([.year, .month, .day], from: weekStartDate)
        let dayPillar = getDayPillar(year: components.year ?? 2024,
                                      month: components.month ?? 1,
                                      day: components.day ?? 1)

        // 计算十神
        let ganShiShen = getShiShen(riGan: riGan, targetGan: dayPillar.gan)
        let zhiShiShen = getZhiShiShen(riGan: riGan, zhi: dayPillar.zhi)

        // 计算运势评分
        let (score, level) = calculateFortuneScore(
            riGan: riGan,
            bazi: bazi,
            weekGan: dayPillar.gan,
            weekZhi: dayPillar.zhi
        )

        // 生成关键词和建议
        let keywords = generateKeywords(ganShiShen: ganShiShen, zhiShiShen: zhiShiShen, level: level)
        let advice = generateAdvice(ganShiShen: ganShiShen, zhiShiShen: zhiShiShen, level: level)

        return WeeklyFortune(
            weekStartDate: weekStartDate,
            weekEndDate: weekEndDate,
            weekNumber: weekNumber,
            gan: dayPillar.gan,
            zhi: dayPillar.zhi,
            ganShiShen: ganShiShen,
            zhiShiShen: zhiShiShen,
            fortuneScore: score,
            fortuneLevel: level,
            keywords: keywords,
            advice: advice
        )
    }

    /// 获取指定日期所在周的周一
    private static func getMonday(of date: Date) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        components.weekday = 2  // 周一
        return calendar.date(from: components) ?? date
    }

    /// 计算运势评分和等级
    private static func calculateFortuneScore(
        riGan: String,
        bazi: Bazi,
        weekGan: String,
        weekZhi: String
    ) -> (Int, FortuneLevel) {
        var score = 50  // 基础分

        // 获取日主五行
        guard let riWuXing = BaziConstants.wuXing[riGan],
              let weekGanWuXing = BaziConstants.wuXing[weekGan],
              let weekZhiWuXing = BaziConstants.wuXing[weekZhi] else {
            return (50, .neutral)
        }

        // 1. 天干关系评分 (+/- 15分)
        score += evaluateGanRelation(riWuXing: riWuXing, targetWuXing: weekGanWuXing)

        // 2. 地支关系评分 (+/- 15分)
        score += evaluateZhiRelation(riWuXing: riWuXing, targetWuXing: weekZhiWuXing)

        // 3. 与八字的合冲关系 (+/- 20分)
        score += evaluateBaziRelation(bazi: bazi, weekGan: weekGan, weekZhi: weekZhi)

        // 限制分数范围
        score = max(10, min(95, score))

        // 确定等级
        let level: FortuneLevel
        switch score {
        case 80...: level = .excellent
        case 65..<80: level = .good
        case 45..<65: level = .neutral
        case 30..<45: level = .caution
        default: level = .poor
        }

        return (score, level)
    }

    /// 评估天干五行关系
    private static func evaluateGanRelation(riWuXing: String, targetWuXing: String) -> Int {
        // 生我者（正印、偏印）+15
        if BaziConstants.wuXingSheng[targetWuXing] == riWuXing {
            return 15
        }
        // 同我者（比肩、劫财）+10
        if riWuXing == targetWuXing {
            return 10
        }
        // 我生者（食神、伤官）+5
        if BaziConstants.wuXingSheng[riWuXing] == targetWuXing {
            return 5
        }
        // 我克者（正财、偏财）-5
        if BaziConstants.wuXingKe[riWuXing] == targetWuXing {
            return -5
        }
        // 克我者（正官、七杀）-15
        if BaziConstants.wuXingKe[targetWuXing] == riWuXing {
            return -15
        }
        return 0
    }

    /// 评估地支五行关系
    private static func evaluateZhiRelation(riWuXing: String, targetWuXing: String) -> Int {
        // 与天干评分逻辑类似，但权重略低
        if BaziConstants.wuXingSheng[targetWuXing] == riWuXing {
            return 12
        }
        if riWuXing == targetWuXing {
            return 8
        }
        if BaziConstants.wuXingSheng[riWuXing] == targetWuXing {
            return 4
        }
        if BaziConstants.wuXingKe[riWuXing] == targetWuXing {
            return -4
        }
        if BaziConstants.wuXingKe[targetWuXing] == riWuXing {
            return -12
        }
        return 0
    }

    /// 评估与八字的合冲关系
    private static func evaluateBaziRelation(bazi: Bazi, weekGan: String, weekZhi: String) -> Int {
        var score = 0
        let baziZhis = [bazi.year.zhi, bazi.month.zhi, bazi.day.zhi, bazi.hour.zhi]
        let baziGans = [bazi.year.gan, bazi.month.gan, bazi.day.gan, bazi.hour.gan]

        // 检查地支六合 (+8)
        for liuHe in BaziConstants.diZhiLiuHe {
            for baziZhi in baziZhis {
                if (liuHe.0 == weekZhi && liuHe.1 == baziZhi) ||
                   (liuHe.1 == weekZhi && liuHe.0 == baziZhi) {
                    score += 8
                }
            }
        }

        // 检查天干五合 (+6)
        for tianGanHe in BaziConstants.tianGanHe {
            for baziGan in baziGans {
                if (tianGanHe.0 == weekGan && tianGanHe.1 == baziGan) ||
                   (tianGanHe.1 == weekGan && tianGanHe.0 == baziGan) {
                    score += 6
                }
            }
        }

        // 检查地支六冲 (-12)
        for chong in BaziConstants.diZhiChong {
            for baziZhi in baziZhis {
                if (chong.0 == weekZhi && chong.1 == baziZhi) ||
                   (chong.1 == weekZhi && chong.0 == baziZhi) {
                    score -= 12
                }
            }
        }

        // 检查地支相刑 (-8)
        for xing in BaziConstants.diZhiXing {
            for baziZhi in baziZhis {
                if (xing.0 == weekZhi && xing.1 == baziZhi) ||
                   (xing.1 == weekZhi && xing.0 == baziZhi) {
                    score -= 8
                }
            }
        }

        // 检查地支相害 (-6)
        for hai in BaziConstants.diZhiHai {
            for baziZhi in baziZhis {
                if (hai.0 == weekZhi && hai.1 == baziZhi) ||
                   (hai.1 == weekZhi && hai.0 == baziZhi) {
                    score -= 6
                }
            }
        }

        return max(-20, min(20, score))
    }

    /// 生成关键词
    private static func generateKeywords(ganShiShen: String, zhiShiShen: String, level: FortuneLevel) -> [String] {
        var keywords: [String] = []

        // 根据天干十神添加关键词
        switch ganShiShen {
        case "比肩": keywords.append("合作")
        case "劫财": keywords.append("竞争")
        case "食神": keywords.append("创意")
        case "伤官": keywords.append("表达")
        case "偏财": keywords.append("机遇")
        case "正财": keywords.append("收获")
        case "七杀": keywords.append("挑战")
        case "正官": keywords.append("责任")
        case "偏印": keywords.append("学习")
        case "正印": keywords.append("贵人")
        default: break
        }

        // 根据地支十神添加关键词
        switch zhiShiShen {
        case "比肩": keywords.append("人脉")
        case "劫财": keywords.append("变动")
        case "食神": keywords.append("享受")
        case "伤官": keywords.append("突破")
        case "偏财": keywords.append("投资")
        case "正财": keywords.append("稳定")
        case "七杀": keywords.append("压力")
        case "正官": keywords.append("规范")
        case "偏印": keywords.append("思考")
        case "正印": keywords.append("支持")
        default: break
        }

        // 根据运势等级添加关键词
        switch level {
        case .excellent: keywords.append("顺遂")
        case .good: keywords.append("进展")
        case .neutral: keywords.append("平稳")
        case .caution: keywords.append("谨慎")
        case .poor: keywords.append("蛰伏")
        }

        return Array(keywords.prefix(3))
    }

    /// 生成建议
    private static func generateAdvice(ganShiShen: String, zhiShiShen: String, level: FortuneLevel) -> String {
        // 基于十神组合生成建议
        let ganAdvice = getShiShenAdvice(ganShiShen)
        let levelAdvice = getLevelAdvice(level)

        return "\(ganAdvice)\(levelAdvice)"
    }

    /// 获取十神相关建议
    private static func getShiShenAdvice(_ shiShen: String) -> String {
        switch shiShen {
        case "比肩": return "本周适合团队协作，与朋友合作能事半功倍。"
        case "劫财": return "本周注意竞争关系，保护好自己的资源和机会。"
        case "食神": return "本周灵感丰富，适合创作和休闲放松。"
        case "伤官": return "本周表达欲强，但需注意言辞分寸。"
        case "偏财": return "本周有意外收获的机会，可留意投资信息。"
        case "正财": return "本周财运稳健，适合理财规划。"
        case "七杀": return "本周压力较大，需保持冷静应对挑战。"
        case "正官": return "本周工作运佳，适合处理正事和提升。"
        case "偏印": return "本周适合学习新技能，思考人生方向。"
        case "正印": return "本周贵人运好，多向长辈前辈请教。"
        default: return "本周保持平常心，稳步前行。"
        }
    }

    /// 获取等级相关建议
    private static func getLevelAdvice(_ level: FortuneLevel) -> String {
        switch level {
        case .excellent: return "整体运势大吉，可大胆行动。"
        case .good: return "运势顺畅，把握机会。"
        case .neutral: return "运势平稳，宜守不宜攻。"
        case .caution: return "需多加谨慎，避免冲动决策。"
        case .poor: return "宜低调行事，蓄势待发。"
        }
    }
}

// MARK: - 日期格式化扩展

extension WeeklyFortune {
    /// 获取周日期范围的格式化字符串
    var dateRangeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M.d"
        let start = formatter.string(from: weekStartDate)
        let end = formatter.string(from: weekEndDate)
        return "\(start)-\(end)"
    }

    /// 获取周标题（如"第3周"）
    var weekTitle: String {
        return "第\(weekNumber)周"
    }

    /// 判断是否为当前周
    var isCurrentWeek: Bool {
        let calendar = Calendar.current
        return calendar.isDate(Date(), equalTo: weekStartDate, toGranularity: .weekOfYear)
    }
}
