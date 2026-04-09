import Foundation

/// 生成与结果页一致的「助手引用」命盘摘要（供排盘结果与已保存命盘复用）。
enum MingPanSummaryBuilder {
    static func assistantPanSummary(bazi: Bazi, birth: (year: Int, month: Int, day: Int, hour: Int, minute: Int), gender: String) -> String {
        let genderText = (gender == "female") ? "女" : "男"
        let calculator = StrengthCalculator(bazi: bazi)
        let strengthResult = calculator.calculate()
        let xiYongShenResult = calculator.calculateXiYongShen(strength: strengthResult.strength)
        let tiaoHouResult = calculator.calculateTiaoHou()
        let qiYunAge = calculateQiYunAge(
            birthYear: birth.year,
            birthMonth: birth.month,
            birthDay: birth.day,
            gender: gender,
            yearGan: bazi.year.gan,
            monthZhi: bazi.month.zhi
        )
        let daYunList = getDaYun(
            gender: gender,
            yearGan: bazi.year.gan,
            monthGan: bazi.month.gan,
            monthZhi: bazi.month.zhi,
            qiYunAge: qiYunAge
        )
        let dayMasterWuXing = BaziConstants.wuXing[bazi.day.gan] ?? "木"

        var s = "【知几排盘 · 助手引用】\n"
        s += "说明：判断「当前」处于哪一步大运、哪一年流年，须用【对话时刻】中的公历年在「大运与流年」表中查找；判断流月须用该年公历日在十二节分段内对应之月柱；流日为该日公历日柱。均不得臆测日期。\n\n"
        s += "出生：\(birth.year)年\(birth.month)月\(birth.day)日 \(birth.hour):\(String(format: "%02d", birth.minute)) \(genderText)\n"
        s += "四柱：\(bazi.year.gan)\(bazi.year.zhi) \(bazi.month.gan)\(bazi.month.zhi) \(bazi.day.gan)\(bazi.day.zhi) \(bazi.hour.gan)\(bazi.hour.zhi)\n"
        s += "日主：\(bazi.day.gan)（五行：\(dayMasterWuXing)）\n"
        appendShiShenSection(to: &s, bazi: bazi)
        appendChongXingHaiSection(to: &s, bazi: bazi)
        s += "能量配置：\(strengthResult.strength)（得分 \(strengthResult.score)）\n"
        if let t = tiaoHouResult.tiaoHou, !t.isEmpty {
            s += "调候：\(t)\n"
        }
        s += "起运：\(qiYunAge)岁（虚岁）\n"
        s += "大运序列（共\(daYunList.count)步）：\(daYunList.map { "\($0.gan)\($0.zhi)" }.joined(separator: " "))\n\n"
        appendDaYunLiuNianTable(
            to: &s,
            riGan: bazi.day.gan,
            daYunList: daYunList,
            birthYear: birth.year,
            qiYunAge: qiYunAge
        )
        appendLiuYueTable(
            to: &s,
            daYunList: daYunList,
            birthYear: birth.year,
            qiYunAge: qiYunAge
        )
        appendLiuRiReference(to: &s, riGan: bazi.day.gan, reference: Date())
        s += "\n喜神：\(xiYongShenResult.xi.joined(separator: "、"))\n"
        s += "忌神：\(xiYongShenResult.ji.joined(separator: "、"))\n"
        return s
    }

    static func assistantPanSummary(record: SavedMingPanRecord) -> String {
        assistantPanSummary(bazi: record.bazi, birth: record.birth, gender: record.gender)
    }

    private static func yearsForDaYunStep(_ stepIndex: Int, daYunList: [DaYun], birthYear: Int, qiYunAge: Int) -> [Int] {
        guard stepIndex >= 0, stepIndex < daYunList.count else { return [] }
        let startAge = qiYunAge + stepIndex * 10 + 1
        let endAge = startAge + 9
        return (startAge...endAge).map { birthYear + $0 - 1 }
    }

    /// 与命盘页一致：天干十神（日干为日主）、地支取本气藏干十神；并附 App 十神能量综合结论，供模型引用而非自算。
    private static func appendShiShenSection(to s: inout String, bazi: Bazi) {
        let ri = bazi.day.gan
        let yGan = getShiShen(riGan: ri, targetGan: bazi.year.gan)
        let yZhi = getZhiShiShen(riGan: ri, zhi: bazi.year.zhi)
        let mGan = getShiShen(riGan: ri, targetGan: bazi.month.gan)
        let mZhi = getZhiShiShen(riGan: ri, zhi: bazi.month.zhi)
        let dZhi = getZhiShiShen(riGan: ri, zhi: bazi.day.zhi)
        let hGan = getShiShen(riGan: ri, targetGan: bazi.hour.gan)
        let hZhi = getZhiShiShen(riGan: ri, zhi: bazi.hour.zhi)

        s += "【四柱十神】（均以日干「\(ri)」为参照；天干为相对日主的十神，地支为藏干**本气**相对日主的十神，与知几命盘页一致；请勿自行重算十神）\n"
        s += "年柱 \(bazi.year.gan)\(bazi.year.zhi)：天干→\(yGan)；地支本气→\(yZhi)\n"
        s += "月柱 \(bazi.month.gan)\(bazi.month.zhi)：天干→\(mGan)；地支本气→\(mZhi)\n"
        s += "日柱 \(bazi.day.gan)\(bazi.day.zhi)：天干→日主；地支本气→\(dZhi)\n"
        s += "时柱 \(bazi.hour.gan)\(bazi.hour.zhi)：天干→\(hGan)；地支本气→\(hZhi)\n"

        let ssResult = ShiShenAnalyzer(bazi: bazi).analyze()
        if let dom = ssResult.dominant {
            s += "十神能量（知几综合干支得分）：相对最旺为「\(dom)」"
            let missing = ssResult.missing
            if !missing.isEmpty {
                let shown = missing.count > 8 ? Array(missing.prefix(8)).joined(separator: "、") + "等" : missing.joined(separator: "、")
                s += "；盘中该算法下能量未体现者：\(shown)"
            }
            s += "\n"
        }
    }

    /// 与命盘页「能量互动」中刑冲破害一致：`analyzeWuXingRelations` → `chongXingHaiResults`。
    private static func appendChongXingHaiSection(to s: inout String, bazi: Bazi) {
        let items = analyzeWuXingRelations(bazi: bazi).chongXingHaiResults
        s += "【地支刑冲破害】（四柱地支间关系，与知几命盘「能量互动」一致；请勿自行另推）\n"
        if items.isEmpty {
            s += "无（四柱地支间未出现刑、冲、破、害）\n"
            return
        }
        for r in items {
            let el = r.elements.joined(separator: "、")
            let pos = r.positions.joined(separator: "、")
            s += "  \(r.type)：\(el)（柱位：\(pos)）\n"
        }
    }

    private static func appendDaYunLiuNianTable(
        to info: inout String,
        riGan: String,
        daYunList: [DaYun],
        birthYear: Int,
        qiYunAge: Int
    ) {
        info += "【大运与流年】每步大运十年；天干、地支本气十神均以日干「\(riGan)」为参照（与命盘大运/流年格一致），**须直接引用下列十神，禁止凭记忆自算**：\n"
        for (index, daYun) in daYunList.enumerated() {
            let years = yearsForDaYunStep(index, daYunList: daYunList, birthYear: birthYear, qiYunAge: qiYunAge)
            let ageStart = daYun.age
            let ageEnd = daYun.age + 9
            let dyGanSS = getShiShen(riGan: riGan, targetGan: daYun.gan)
            let dyZhiSS = getZhiShiShen(riGan: riGan, zhi: daYun.zhi)
            let liuNianStr = years.map { y in
                let ln = getLiuNianGanZhi(year: y)
                let gss = getShiShen(riGan: riGan, targetGan: ln.gan)
                let zss = getZhiShiShen(riGan: riGan, zhi: ln.zhi)
                return "\(y)\(ln.gan)\(ln.zhi) 干→\(gss) 支本气→\(zss)"
            }.joined(separator: " | ")
            info += "  大运\(daYun.gan)\(daYun.zhi) 干→\(dyGanSS) 支本气→\(dyZhiSS)（\(ageStart)-\(ageEnd)岁虚岁）：\(liuNianStr)\n"
        }
        info += """
        【大运干支与十年分段（常见流派讲法，供文化性解读参考）】
        每步大运为十年。一种常见分法：大运**天干**所主之象，往往在前五年相对更显；大运**地支**所主之象，往往在后五年相对更显。同时，地支多被视为根基与环境，其影响常被说成**贯穿该步大运全程**；天干则常被说成在**前五年影响相对更大**。不同典籍表述不一，此处仅作叙事框架，不作吉凶断言。

        """
    }

    /// 大运表中出现过的全部公历年（去重、升序），用于流月表
    private static func allSolarYearsInPan(daYunList: [DaYun], birthYear: Int, qiYunAge: Int) -> [Int] {
        var set = Set<Int>()
        for index in daYunList.indices {
            for y in yearsForDaYunStep(index, daYunList: daYunList, birthYear: birthYear, qiYunAge: qiYunAge) {
                set.insert(y)
            }
        }
        return set.sorted()
    }

    private static func appendLiuYueTable(
        to info: inout String,
        daYunList: [DaYun],
        birthYear: Int,
        qiYunAge: Int
    ) {
        let years = allSolarYearsInPan(daYunList: daYunList, birthYear: birthYear, qiYunAge: qiYunAge)
        guard !years.isEmpty else { return }
        info += "\n【流月】以十二节为月界（正月寅～腊月丑），下列为各公历年十二流月干支（与 App 命盘「流月与流日」一致）：\n"
        for y in years {
            let parts = (0..<12).map { i -> String in
                let lab = LiuYueIndex(rawValue: i)?.monthLabel ?? ""
                let g = getLiuYueGanZhi(solarYear: y, liuYueIndex: i)
                return "\(lab)\(g.gan)\(g.zhi)"
            }
            info += "  \(y)年：\(parts.joined(separator: " "))\n"
        }
    }

    private static func appendLiuRiReference(to info: inout String, riGan: String, reference: Date) {
        let cal = gregorianLocalCalendar()
        let y = cal.component(.year, from: reference)
        let mo = cal.component(.month, from: reference)
        let day = cal.component(.day, from: reference)
        let idx = liuYueIndexContaining(solarYear: y, reference: reference)
        let ly = getLiuYueGanZhi(solarYear: y, liuYueIndex: idx)
        let lab = LiuYueIndex(rawValue: idx)?.monthLabel ?? "正月"
        let dp = PillarCalculator.getDayPillar(year: y, month: mo, day: day)
        let lyGanSS = getShiShen(riGan: riGan, targetGan: ly.gan)
        let lyZhiSS = getZhiShiShen(riGan: riGan, zhi: ly.zhi)
        let lrGanSS = getShiShen(riGan: riGan, targetGan: dp.gan)
        let lrZhiSS = getZhiShiShen(riGan: riGan, zhi: dp.zhi)
        info += "\n【流日】每一流月为节日起至下一节日前一日；该段内逐公历日之干支为流日，与 App 命盘横条一致（日柱算法同四柱日柱）。\n"
        info += "摘要生成时刻参考：公历 \(y)年\(mo)月\(day)日 → 所属流月「\(lab)」柱 \(ly.gan)\(ly.zhi) 干→\(lyGanSS) 支本气→\(lyZhiSS)，当日流日 \(dp.gan)\(dp.zhi) 干→\(lrGanSS) 支本气→\(lrZhiSS)。\n"
    }
}
