import Foundation

// MARK: - 八字上下文

/// 八字分析上下文，封装常用参数
/// 用于减少函数参数数量，提高代码可读性
struct BaziContext {
    let allGan: [String]
    let allZhi: [String]
    let positions: [String]
    let monthZhi: String

    /// 从 Bazi 创建上下文
    init(bazi: Bazi) {
        self.allGan = [bazi.year.gan, bazi.month.gan, bazi.day.gan, bazi.hour.gan]
        self.allZhi = [bazi.year.zhi, bazi.month.zhi, bazi.day.zhi, bazi.hour.zhi]
        self.positions = ["年", "月", "日", "时"]
        self.monthZhi = bazi.month.zhi
    }

    /// 从 Bazi + 额外一柱（如大运/流年）创建上下文，用于分析该柱与命盘的互动
    init(bazi: Bazi, extraGan: String, extraZhi: String, extraPositionName: String) {
        self.allGan = [bazi.year.gan, bazi.month.gan, bazi.day.gan, bazi.hour.gan, extraGan]
        self.allZhi = [bazi.year.zhi, bazi.month.zhi, bazi.day.zhi, bazi.hour.zhi, extraZhi]
        self.positions = ["年", "月", "日", "时", extraPositionName]
        self.monthZhi = bazi.month.zhi
    }

    /// 完整初始化
    init(allGan: [String], allZhi: [String], positions: [String], monthZhi: String) {
        self.allGan = allGan
        self.allZhi = allZhi
        self.positions = positions
        self.monthZhi = monthZhi
    }
}

// MARK: - 五行关系分析

/// 分析八字中的五行关系
///
/// 八字命理中，地支之间存在多种作用关系：
/// - **合**：六合、三合、三会，合则减力或化气
/// - **冲**：对冲位置的地支互相冲击，力量减弱
/// - **刑**：相刑带来不顺、灾祸
/// - **害**：相害主不和、损伤
/// - **库**：辰戌丑未四库，遇特定天干可成库藏气
/// - **贪生忘克**：克者去生他物，克力减弱
func analyzeWuXingRelations(bazi: Bazi) -> WuXingAnalysis {
    let context = BaziContext(bazi: bazi)

    let heResults = checkHe(context: context)
    let chongXingHaiResults = checkChongXingHai(context: context)
    let kuResults = checkKu(context: context)
    let tanShengWangKeResults = checkTanShengWangKe(bazi: bazi)

    return WuXingAnalysis(
        heResults: heResults,
        chongXingHaiResults: chongXingHaiResults,
        kuResults: kuResults,
        tanShengWangKeResults: tanShengWangKeResults
    )
}

/// 分析「额外一柱」（如大运/流年）与命盘的五行互动
/// - Parameters:
///   - bazi: 命盘
///   - extraGan: 额外柱天干（如大运干）
///   - extraZhi: 额外柱地支（如大运支）
///   - extraPositionName: 该柱在结果中的名称（如 "大运"、"流年"）
/// - Returns: 仅包含「涉及该柱」的合、冲刑破害、库（贪生忘克暂不纳入）
func analyzeBaziWithExtraPillar(bazi: Bazi, extraGan: String, extraZhi: String, extraPositionName: String) -> WuXingAnalysis {
    let context = BaziContext(bazi: bazi, extraGan: extraGan, extraZhi: extraZhi, extraPositionName: extraPositionName)
    let heResults = checkHe(context: context).filter { $0.positions.contains(extraPositionName) }
    let chongXingHaiResults = checkChongXingHai(context: context).filter { $0.positions.contains(extraPositionName) }
    let kuResults = checkKu(context: context).filter { $0.position == extraPositionName }
    return WuXingAnalysis(
        heResults: heResults,
        chongXingHaiResults: chongXingHaiResults,
        kuResults: kuResults,
        tanShengWangKeResults: []
    )
}

/// 判断地支六合是否合化成功
/// 委托给 WuXingHuaChecker 处理
/// - SeeAlso: `WuXingHuaChecker.canDiZhiLiuHeHua`
func canDiZhiLiuHeHua(zhi1: String, zhi2: String, huaWuXing: String, context: BaziContext) -> Bool {
    WuXingHuaChecker.canDiZhiLiuHeHua(
        zhi1: zhi1,
        zhi2: zhi2,
        huaWuXing: huaWuXing,
        allGan: context.allGan,
        allZhi: context.allZhi,
        positions: context.positions,
        monthZhi: context.monthZhi
    )
}

/// 判断地支三合是否合化成功
/// 委托给 WuXingHuaChecker 处理
/// - SeeAlso: `WuXingHuaChecker.canDiZhiSanHeHua`
func canDiZhiSanHeHua(elements: [String], huaWuXing: String, context: BaziContext, isFullSanHe: Bool) -> Bool {
    WuXingHuaChecker.canDiZhiSanHeHua(
        elements: elements,
        huaWuXing: huaWuXing,
        allGan: context.allGan,
        allZhi: context.allZhi,
        monthZhi: context.monthZhi,
        isFullSanHe: isFullSanHe
    )
}

/// 判断天干合化是否成功
/// 委托给 WuXingHuaChecker 处理
/// - SeeAlso: `WuXingHuaChecker.canTianGanHua`
func canTianGanHua(gan1: String, gan2: String, huaWuXing: String, context: BaziContext) -> Bool {
    WuXingHuaChecker.canTianGanHua(
        gan1: gan1,
        gan2: gan2,
        huaWuXing: huaWuXing,
        allGan: context.allGan,
        allZhi: context.allZhi,
        monthZhi: context.monthZhi
    )
}

/// 检查天干五合和地支合会
func checkHe(context: BaziContext) -> [HeResult] {
    var results: [HeResult] = []

    // 检查天干五合
    for he in BaziConstants.tianGanHe {
        var foundPositions: [Int] = []
        for (i, gan) in context.allGan.enumerated() {
            if gan == he.0 || gan == he.1 {
                foundPositions.append(i)
            }
        }
        if foundPositions.count >= 2 {
            let hasFirst = context.allGan.contains(he.0)
            let hasSecond = context.allGan.contains(he.1)
            if hasFirst && hasSecond {
                let pos = foundPositions.map { context.positions[$0] }

                let canHua = canTianGanHua(
                    gan1: he.0, gan2: he.1, huaWuXing: he.2,
                    context: context
                )

                results.append(HeResult(
                    type: .tianGanHe,
                    elements: [he.0, he.1],
                    huaWuXing: canHua ? he.2 : nil,
                    banHeWuXing: nil,
                    positions: pos
                ))
            }
        }
    }

    // 检查地支六合
    for he in BaziConstants.diZhiLiuHe {
        let hasFirst = context.allZhi.contains(he.0)
        let hasSecond = context.allZhi.contains(he.1)
        if hasFirst && hasSecond {
            var pos: [String] = []
            for (i, zhi) in context.allZhi.enumerated() {
                if zhi == he.0 || zhi == he.1 {
                    pos.append(context.positions[i])
                }
            }

            // 判断是否能合化成功
            let canHua = canDiZhiLiuHeHua(
                zhi1: he.0, zhi2: he.1, huaWuXing: he.2,
                context: context
            )

            results.append(HeResult(
                type: .diZhiLiuHe,
                elements: [he.0, he.1],
                huaWuXing: canHua ? he.2 : nil,  // 只有合化成功才有化神
                banHeWuXing: nil,
                positions: pos
            ))
        }
    }

    // 检查地支三合
    for he in BaziConstants.diZhiSanHe {
        let count = [he.0, he.1, he.2].filter { context.allZhi.contains($0) }.count
        if count >= 2 {
            var elements: [String] = []
            var pos: [String] = []
            for (i, zhi) in context.allZhi.enumerated() {
                if zhi == he.0 || zhi == he.1 || zhi == he.2 {
                    elements.append(zhi)
                    pos.append(context.positions[i])
                }
            }

            let isFullSanHe = (count == 3)
            // 判断是否能合化成功
            let canHua = canDiZhiSanHeHua(
                elements: elements, huaWuXing: he.3,
                context: context,
                isFullSanHe: isFullSanHe
            )

            results.append(HeResult(
                type: .diZhiSanHe,
                elements: elements,
                huaWuXing: canHua ? he.3 : nil,  // 只有合化成功才有化神
                banHeWuXing: !canHua && count >= 2 ? he.3 : nil,  // 不能化则显示为半合/合绊
                positions: pos
            ))
        }
    }

    // 检查地支三会
    for hui in BaziConstants.diZhiSanHui {
        let count = [hui.0, hui.1, hui.2].filter { context.allZhi.contains($0) }.count
        if count >= 2 {
            var elements: [String] = []
            var pos: [String] = []
            for (i, zhi) in context.allZhi.enumerated() {
                if zhi == hui.0 || zhi == hui.1 || zhi == hui.2 {
                    elements.append(zhi)
                    pos.append(context.positions[i])
                }
            }
            results.append(HeResult(
                type: .diZhiSanHui,
                elements: elements,
                huaWuXing: count == 3 ? hui.3 : nil,
                banHeWuXing: count == 2 ? hui.3 : nil,
                positions: pos
            ))
        }
    }

    return results
}

/// 检查刑冲破害
func checkChongXingHai(context: BaziContext) -> [ChongXingHaiResult] {
    var results: [ChongXingHaiResult] = []

    // 检查相刑
    for xing in BaziConstants.diZhiXing {
        if xing.0 == xing.1 {
            let count = context.allZhi.filter { $0 == xing.0 }.count
            if count >= 2 {
                var pos: [String] = []
                for (i, zhi) in context.allZhi.enumerated() {
                    if zhi == xing.0 {
                        pos.append(context.positions[i])
                    }
                }
                results.append(ChongXingHaiResult(
                    type: "自刑",
                    elements: [xing.0, xing.1],
                    positions: pos
                ))
            }
        } else {
            let hasFirst = context.allZhi.contains(xing.0)
            let hasSecond = context.allZhi.contains(xing.1)
            if hasFirst && hasSecond {
                var pos: [String] = []
                for (i, zhi) in context.allZhi.enumerated() {
                    if zhi == xing.0 || zhi == xing.1 {
                        pos.append(context.positions[i])
                    }
                }
                results.append(ChongXingHaiResult(
                    type: "刑",
                    elements: [xing.0, xing.1],
                    positions: pos
                ))
            }
        }
    }

    // 检查六冲
    for chong in BaziConstants.diZhiChong {
        let hasFirst = context.allZhi.contains(chong.0)
        let hasSecond = context.allZhi.contains(chong.1)
        if hasFirst && hasSecond {
            var pos: [String] = []
            for (i, zhi) in context.allZhi.enumerated() {
                if zhi == chong.0 || zhi == chong.1 {
                    pos.append(context.positions[i])
                }
            }
            results.append(ChongXingHaiResult(
                type: "冲",
                elements: [chong.0, chong.1],
                positions: pos
            ))
        }
    }

    // 检查相破
    for po in BaziConstants.diZhiPo {
        let hasFirst = context.allZhi.contains(po.0)
        let hasSecond = context.allZhi.contains(po.1)
        if hasFirst && hasSecond {
            var pos: [String] = []
            for (i, zhi) in context.allZhi.enumerated() {
                if zhi == po.0 || zhi == po.1 {
                    pos.append(context.positions[i])
                }
            }
            results.append(ChongXingHaiResult(
                type: "破",
                elements: [po.0, po.1],
                positions: pos
            ))
        }
    }

    // 检查相害
    for hai in BaziConstants.diZhiHai {
        let hasFirst = context.allZhi.contains(hai.0)
        let hasSecond = context.allZhi.contains(hai.1)
        if hasFirst && hasSecond {
            var pos: [String] = []
            for (i, zhi) in context.allZhi.enumerated() {
                if zhi == hai.0 || zhi == hai.1 {
                    pos.append(context.positions[i])
                }
            }
            results.append(ChongXingHaiResult(
                type: "害",
                elements: [hai.0, hai.1],
                positions: pos
            ))
        }
    }

    return results
}

/// 检查四库
func checkKu(context: BaziContext) -> [KuResult] {
    var results: [KuResult] = []

    for (i, zhi) in context.allZhi.enumerated() {
        guard BaziConstants.siKuZhi.contains(zhi) else { continue }

        var formedKu: (kuWuXing: String, triggerGan: String)? = nil

        if let triggers = BaziConstants.siKuTrigger[zhi] {
            for gan in context.allGan {
                for trigger in triggers {
                    if trigger.triggerGan.contains(gan) {
                        formedKu = (trigger.kuWuXing, gan)
                        break
                    }
                }
                if formedKu != nil { break }
            }
        }

        results.append(KuResult(
            zhi: zhi,
            kuWuXing: formedKu?.kuWuXing,
            triggerGan: formedKu?.triggerGan,
            position: context.positions[i],
            isFormed: formedKu != nil
        ))
    }

    return results
}

/// 检查贪生忘克
func checkTanShengWangKe(bazi: Bazi) -> [TanShengWangKeResult] {
    var results: [TanShengWangKeResult] = []

    guard let dayWx = BaziConstants.wuXing[bazi.day.gan] else { return results }

    var keRiZhuWx: String? = nil
    for (wx, target) in BaziConstants.wuXingKe {
        if target == dayWx {
            keRiZhuWx = wx
            break
        }
    }
    guard let keWx = keRiZhuWx else { return results }

    var shengRiZhuWx: String? = nil
    for (wx, target) in BaziConstants.wuXingSheng {
        if target == dayWx {
            shengRiZhuWx = wx
            break
        }
    }
    guard let shengWx = shengRiZhuWx else { return results }

    guard BaziConstants.wuXingSheng[keWx] == shengWx else { return results }

    let allPositions: [(pos: String, gan: String, zhi: String)] = [
        ("年", bazi.year.gan, bazi.year.zhi),
        ("月", bazi.month.gan, bazi.month.zhi),
        ("日", bazi.day.gan, bazi.day.zhi),
        ("时", bazi.hour.gan, bazi.hour.zhi)
    ]

    for (pos, gan, zhi) in allPositions {
        let ganWx = BaziConstants.wuXing[gan]
        let zhiWx = BaziConstants.wuXing[zhi]

        if zhiWx == keWx && ganWx == shengWx {
            results.append(TanShengWangKeResult(
                keWuXing: keWx,
                shengWuXing: shengWx,
                kePosition: "\(pos)支",
                shengPosition: "\(pos)干",
                description: "\(keWx)(\(pos)支)克日主\(dayWx)，但\(keWx)生\(shengWx)(\(pos)干)，\(keWx)贪生忘克"
            ))
        }
    }

    return results
}
