import Foundation

// MARK: - 五行合化检查器

/// 五行合化检查器 - 负责判断合是否能够化气
struct WuXingHuaChecker {

    // MARK: - 地支六合化检查

    /// 判断地支六合是否合化成功
    ///
    /// 六合合化的四个条件：
    /// 1. **紧邻**：两地支必须相邻（年月、月日、日时）
    /// 2. **当令或得生**：化神五行在月令得旺或得生
    /// 3. **天干引化**：天干中需透出化神五行
    /// 4. **不被克制**：化神不能被天干克制
    static func canDiZhiLiuHeHua(
        zhi1: String,
        zhi2: String,
        huaWuXing: String,
        allGan: [String],
        allZhi: [String],
        positions: [String],
        monthZhi: String
    ) -> Bool {
        // 1. 检查是否紧邻
        guard checkAdjacent(zhi1: zhi1, zhi2: zhi2, allZhi: allZhi) else {
            return false
        }

        // 2. 检查化神当令或得生
        guard checkDangLingOrDeSheng(huaWuXing: huaWuXing, monthZhi: monthZhi) else {
            return false
        }

        // 3. 检查天干透出化神五行
        guard checkTouChu(huaWuXing: huaWuXing, allGan: allGan) else {
            return false
        }

        // 4. 检查化神不被克制
        guard checkNotRestricted(huaWuXing: huaWuXing, allGan: allGan, allZhi: allZhi) else {
            return false
        }

        return true
    }

    // MARK: - 地支三合化检查

    /// 判断地支三合是否合化成功
    ///
    /// 条件：
    /// 1. 三支齐全或半合带旺支
    /// 2. 化神当令或得生助
    /// 3. 天干透出化神五行
    /// 4. 化神不被克制
    static func canDiZhiSanHeHua(
        elements: [String],
        huaWuXing: String,
        allGan: [String],
        allZhi: [String],
        monthZhi: String,
        isFullSanHe: Bool
    ) -> Bool {
        // 1. 如果不是完整三合，检查是否包含旺支（三合局的中神）
        if !isFullSanHe {
            guard checkHasZhongShen(elements: elements, huaWuXing: huaWuXing) else {
                return false
            }
        }

        // 2. 检查化神当令或得生助
        guard checkDangLingOrDeSheng(huaWuXing: huaWuXing, monthZhi: monthZhi) else {
            return false
        }

        // 3. 检查天干透出化神五行
        guard checkTouChu(huaWuXing: huaWuXing, allGan: allGan) else {
            return false
        }

        // 4. 检查化神不被克制（三合局允许一个克神）
        guard checkNotRestrictedForSanHe(huaWuXing: huaWuXing, allGan: allGan) else {
            return false
        }

        return true
    }

    // MARK: - 天干合化检查

    /// 判断天干合化是否成功
    static func canTianGanHua(
        gan1: String,
        gan2: String,
        huaWuXing: String,
        allGan: [String],
        allZhi: [String],
        monthZhi: String
    ) -> Bool {
        // 1. 检查化神当令或得生
        guard checkDangLingOrDeSheng(huaWuXing: huaWuXing, monthZhi: monthZhi) else {
            return false
        }

        // 2. 检查合化的天干在地支没有强根
        let gan1Wx = BaziConstants.wuXing[gan1] ?? ""
        let gan2Wx = BaziConstants.wuXing[gan2] ?? ""
        for zhi in allZhi {
            let zhiWx = BaziConstants.wuXing[zhi] ?? ""
            if zhiWx == gan1Wx || zhiWx == gan2Wx {
                return false  // 有强根则不能化
            }
        }

        // 3. 检查化神不被天干克制
        guard let keHuaWx = BaziConstants.wuXingBeiKe[huaWuXing] else {
            return false
        }
        for gan in allGan {
            if BaziConstants.wuXing[gan] == keHuaWx {
                return false
            }
        }

        // 4. 检查地支有化神或生化神的五行支持
        var hasZhiSupport = false
        for zhi in allZhi {
            let zhiWx = BaziConstants.wuXing[zhi] ?? ""
            if zhiWx == huaWuXing || BaziConstants.wuXingSheng[zhiWx] == huaWuXing {
                hasZhiSupport = true
                break
            }
        }

        return hasZhiSupport
    }

    // MARK: - Private Helper Methods

    /// 检查两个地支是否紧邻
    private static func checkAdjacent(zhi1: String, zhi2: String, allZhi: [String]) -> Bool {
        var pos1: Int = -1
        var pos2: Int = -1

        for (i, zhi) in allZhi.enumerated() {
            if zhi == zhi1 && pos1 == -1 {
                pos1 = i
            } else if zhi == zhi2 && pos2 == -1 {
                pos2 = i
            }
        }

        return abs(pos1 - pos2) == 1
    }

    /// 检查化神是否当令或得生
    private static func checkDangLingOrDeSheng(huaWuXing: String, monthZhi: String) -> Bool {
        guard let monthWang = BaziConstants.monthWangXing[monthZhi] else {
            return false
        }

        let huaDangLing = (monthWang == huaWuXing)
        let huaDeSheng = (BaziConstants.wuXingSheng[monthWang] == huaWuXing)

        return huaDangLing || huaDeSheng
    }

    /// 检查天干是否透出化神五行
    private static func checkTouChu(huaWuXing: String, allGan: [String]) -> Bool {
        for gan in allGan {
            if BaziConstants.wuXing[gan] == huaWuXing {
                return true
            }
        }
        return false
    }

    /// 检查化神是否不被克制（六合用）
    private static func checkNotRestricted(huaWuXing: String, allGan: [String], allZhi: [String]) -> Bool {
        guard let keHuaWx = BaziConstants.wuXingBeiKe[huaWuXing] else {
            return false
        }

        var keCount = 0
        for gan in allGan {
            if BaziConstants.wuXing[gan] == keHuaWx {
                keCount += 1
            }
        }

        // 如果克神多于一个，则化神被克制
        if keCount > 1 {
            return false
        }

        // 如果有一个克神，检查是否有足够的生助
        if keCount == 1 {
            var supportCount = 0
            for zhi in allZhi {
                let zhiWx = BaziConstants.wuXing[zhi] ?? ""
                if zhiWx == huaWuXing || BaziConstants.wuXingSheng[zhiWx] == huaWuXing {
                    supportCount += 1
                }
            }
            // 需要有足够的生助才能抵消克制
            if supportCount < 2 {
                return false
            }
        }

        return true
    }

    /// 检查化神是否不被克制（三合用，允许一个克神）
    private static func checkNotRestrictedForSanHe(huaWuXing: String, allGan: [String]) -> Bool {
        guard let keHuaWx = BaziConstants.wuXingBeiKe[huaWuXing] else {
            return false
        }

        var keCount = 0
        for gan in allGan {
            if BaziConstants.wuXing[gan] == keHuaWx {
                keCount += 1
            }
        }

        // 三合局力量较强，允许一个克神存在
        return keCount <= 1
    }

    /// 检查半合是否包含中神
    private static func checkHasZhongShen(elements: [String], huaWuXing: String) -> Bool {
        // 三合局中神：子(水局)、午(火局)、卯(木局)、酉(金局)
        let sanHeZhongShen: [String: String] = [
            "水": "子",
            "火": "午",
            "木": "卯",
            "金": "酉"
        ]

        guard let zhongShen = sanHeZhongShen[huaWuXing] else {
            return false
        }

        return elements.contains(zhongShen)
    }
}
