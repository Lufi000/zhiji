import Foundation
import os.log

// MARK: - 节气数据

/// 节气数据支持的年份范围
let jieqiSupportedYearRange: ClosedRange<Int> = 1940...2050

/// 获取指定年份的12个"节"的日期
/// 返回顺序：[小寒, 立春, 惊蛰, 清明, 立夏, 芒种, 小暑, 立秋, 白露, 寒露, 立冬, 大雪]
/// 月份对应：[1月,   2月,   3月,   4月,   5月,   6月,   7月,   8月,   9月,  10月,  11月,  12月]
/// - Parameter year: 年份
/// - Returns: 节气日期数组。如果年份超出支持范围，会记录警告并使用通用算法计算
func getJieqiDates(year: Int) -> [(month: Int, day: Int)] {
    // 使用寿星天文历算法的简化版本
    // 基于2000年为基准的节气计算

    // 每个节气的大约日期（基于万年历数据）
    let jieqiTable: [Int: [(Int, Int)]] = [
        1940: [(1,6), (2,5), (3,6), (4,5), (5,6), (6,6), (7,7), (8,8), (9,8), (10,8), (11,7), (12,7)],
        1950: [(1,6), (2,4), (3,6), (4,5), (5,6), (6,6), (7,7), (8,8), (9,8), (10,8), (11,8), (12,7)],
        1960: [(1,6), (2,5), (3,6), (4,5), (5,5), (6,6), (7,7), (8,7), (9,8), (10,8), (11,7), (12,7)],
        1970: [(1,6), (2,4), (3,6), (4,5), (5,6), (6,6), (7,7), (8,8), (9,8), (10,8), (11,8), (12,7)],
        1980: [(1,6), (2,5), (3,5), (4,4), (5,5), (6,5), (7,7), (8,7), (9,7), (10,8), (11,7), (12,7)],
        1981: [(1,6), (2,4), (3,6), (4,5), (5,5), (6,6), (7,7), (8,7), (9,8), (10,8), (11,7), (12,7)],
        1982: [(1,5), (2,4), (3,6), (4,5), (5,6), (6,6), (7,7), (8,8), (9,8), (10,8), (11,8), (12,7)],
        1983: [(1,6), (2,4), (3,6), (4,5), (5,6), (6,6), (7,8), (8,8), (9,8), (10,9), (11,8), (12,7)],
        1984: [(1,6), (2,4), (3,5), (4,4), (5,5), (6,5), (7,7), (8,7), (9,7), (10,8), (11,7), (12,7)],
        1985: [(1,5), (2,4), (3,5), (4,5), (5,5), (6,6), (7,7), (8,7), (9,8), (10,8), (11,7), (12,7)],
        1986: [(1,5), (2,4), (3,6), (4,5), (5,5), (6,6), (7,7), (8,7), (9,8), (10,8), (11,7), (12,7)],
        1987: [(1,6), (2,4), (3,6), (4,5), (5,6), (6,6), (7,7), (8,8), (9,8), (10,8), (11,8), (12,7)],
        1988: [(1,6), (2,4), (3,5), (4,4), (5,5), (6,5), (7,7), (8,7), (9,7), (10,8), (11,7), (12,7)],
        1989: [(1,5), (2,4), (3,5), (4,5), (5,5), (6,6), (7,7), (8,7), (9,7), (10,8), (11,7), (12,7)],
        1990: [(1,5), (2,4), (3,6), (4,5), (5,5), (6,6), (7,7), (8,7), (9,8), (10,8), (11,7), (12,7)],
        1991: [(1,6), (2,4), (3,6), (4,5), (5,6), (6,6), (7,7), (8,8), (9,8), (10,9), (11,8), (12,7)],
        1992: [(1,6), (2,4), (3,5), (4,4), (5,5), (6,5), (7,7), (8,7), (9,7), (10,8), (11,7), (12,7)],
        1993: [(1,5), (2,4), (3,5), (4,5), (5,5), (6,6), (7,7), (8,7), (9,8), (10,8), (11,7), (12,7)],
        1994: [(1,5), (2,4), (3,6), (4,5), (5,6), (6,6), (7,7), (8,8), (9,8), (10,8), (11,7), (12,7)],
        1995: [(1,6), (2,4), (3,6), (4,5), (5,6), (6,6), (7,7), (8,8), (9,8), (10,9), (11,8), (12,7)],
        1996: [(1,6), (2,4), (3,5), (4,4), (5,5), (6,5), (7,7), (8,7), (9,7), (10,8), (11,7), (12,7)],
        1997: [(1,5), (2,4), (3,5), (4,5), (5,5), (6,6), (7,7), (8,7), (9,7), (10,8), (11,7), (12,7)],
        1998: [(1,5), (2,4), (3,6), (4,5), (5,5), (6,6), (7,7), (8,8), (9,8), (10,8), (11,7), (12,7)],
        1999: [(1,6), (2,4), (3,6), (4,5), (5,6), (6,6), (7,7), (8,8), (9,8), (10,9), (11,8), (12,7)],
        2000: [(1,6), (2,4), (3,5), (4,4), (5,5), (6,5), (7,7), (8,7), (9,7), (10,8), (11,7), (12,7)],
        2001: [(1,5), (2,4), (3,5), (4,5), (5,5), (6,6), (7,7), (8,7), (9,7), (10,8), (11,7), (12,7)],
        2002: [(1,5), (2,4), (3,6), (4,5), (5,6), (6,6), (7,7), (8,8), (9,8), (10,8), (11,7), (12,7)],
        2003: [(1,6), (2,4), (3,6), (4,5), (5,6), (6,6), (7,7), (8,8), (9,8), (10,9), (11,8), (12,7)],
        2004: [(1,6), (2,4), (3,5), (4,4), (5,5), (6,5), (7,7), (8,7), (9,7), (10,8), (11,7), (12,7)],
        2005: [(1,5), (2,4), (3,5), (4,5), (5,5), (6,6), (7,7), (8,7), (9,7), (10,8), (11,7), (12,7)],
        2006: [(1,5), (2,4), (3,6), (4,5), (5,5), (6,6), (7,7), (8,7), (9,8), (10,8), (11,7), (12,7)],
        2007: [(1,6), (2,4), (3,6), (4,5), (5,6), (6,6), (7,7), (8,8), (9,8), (10,8), (11,8), (12,7)],
        2008: [(1,6), (2,4), (3,5), (4,4), (5,5), (6,5), (7,7), (8,7), (9,7), (10,8), (11,7), (12,7)],
        2009: [(1,5), (2,4), (3,5), (4,4), (5,5), (6,5), (7,7), (8,7), (9,7), (10,8), (11,7), (12,7)],
        2010: [(1,5), (2,4), (3,6), (4,5), (5,5), (6,6), (7,7), (8,7), (9,8), (10,8), (11,7), (12,7)],
        2011: [(1,6), (2,4), (3,6), (4,5), (5,6), (6,6), (7,7), (8,8), (9,8), (10,8), (11,8), (12,7)],
        2012: [(1,6), (2,4), (3,5), (4,4), (5,5), (6,5), (7,7), (8,7), (9,7), (10,8), (11,7), (12,7)],
        2013: [(1,5), (2,4), (3,5), (4,4), (5,5), (6,5), (7,7), (8,7), (9,7), (10,8), (11,7), (12,7)],
        2014: [(1,5), (2,4), (3,6), (4,5), (5,5), (6,6), (7,7), (8,7), (9,8), (10,8), (11,7), (12,7)],
        2015: [(1,6), (2,4), (3,6), (4,5), (5,6), (6,6), (7,7), (8,8), (9,8), (10,8), (11,8), (12,7)],
        2016: [(1,6), (2,4), (3,5), (4,4), (5,5), (6,5), (7,7), (8,7), (9,7), (10,8), (11,7), (12,7)],
        2017: [(1,5), (2,3), (3,5), (4,4), (5,5), (6,5), (7,7), (8,7), (9,7), (10,8), (11,7), (12,7)],
        2018: [(1,5), (2,4), (3,5), (4,5), (5,5), (6,6), (7,7), (8,7), (9,8), (10,8), (11,7), (12,7)],
        2019: [(1,5), (2,4), (3,6), (4,5), (5,6), (6,6), (7,7), (8,8), (9,8), (10,8), (11,8), (12,7)],
        2020: [(1,6), (2,4), (3,5), (4,4), (5,5), (6,5), (7,6), (8,7), (9,7), (10,8), (11,7), (12,7)],
        2021: [(1,5), (2,3), (3,5), (4,4), (5,5), (6,5), (7,7), (8,7), (9,7), (10,8), (11,7), (12,7)],
        2022: [(1,5), (2,4), (3,5), (4,5), (5,5), (6,6), (7,7), (8,7), (9,7), (10,8), (11,7), (12,7)],
        2023: [(1,5), (2,4), (3,6), (4,5), (5,6), (6,6), (7,7), (8,8), (9,8), (10,8), (11,8), (12,7)],
        2024: [(1,6), (2,4), (3,5), (4,4), (5,5), (6,5), (7,6), (8,7), (9,7), (10,8), (11,7), (12,6)],
        2025: [(1,5), (2,3), (3,5), (4,4), (5,5), (6,5), (7,7), (8,7), (9,7), (10,8), (11,7), (12,7)],
        // 2026-2050 年节气数据（基于天文算法推算）
        2026: [(1,5), (2,4), (3,5), (4,5), (5,5), (6,6), (7,7), (8,7), (9,7), (10,8), (11,7), (12,7)],
        2027: [(1,5), (2,4), (3,6), (4,5), (5,6), (6,6), (7,7), (8,8), (9,8), (10,8), (11,8), (12,7)],
        2028: [(1,6), (2,4), (3,5), (4,4), (5,5), (6,5), (7,7), (8,7), (9,7), (10,8), (11,7), (12,7)],
        2029: [(1,5), (2,3), (3,5), (4,4), (5,5), (6,5), (7,7), (8,7), (9,7), (10,8), (11,7), (12,7)],
        2030: [(1,5), (2,4), (3,5), (4,5), (5,5), (6,6), (7,7), (8,7), (9,8), (10,8), (11,7), (12,7)],
        2031: [(1,5), (2,4), (3,6), (4,5), (5,6), (6,6), (7,7), (8,8), (9,8), (10,8), (11,8), (12,7)],
        2032: [(1,6), (2,4), (3,5), (4,4), (5,5), (6,5), (7,7), (8,7), (9,7), (10,8), (11,7), (12,7)],
        2033: [(1,5), (2,3), (3,5), (4,4), (5,5), (6,5), (7,7), (8,7), (9,7), (10,8), (11,7), (12,7)],
        2034: [(1,5), (2,4), (3,5), (4,5), (5,5), (6,6), (7,7), (8,7), (9,7), (10,8), (11,7), (12,7)],
        2035: [(1,5), (2,4), (3,6), (4,5), (5,6), (6,6), (7,7), (8,8), (9,8), (10,8), (11,8), (12,7)],
        2036: [(1,6), (2,4), (3,5), (4,4), (5,5), (6,5), (7,7), (8,7), (9,7), (10,8), (11,7), (12,7)],
        2037: [(1,5), (2,3), (3,5), (4,4), (5,5), (6,5), (7,7), (8,7), (9,7), (10,8), (11,7), (12,7)],
        2038: [(1,5), (2,4), (3,5), (4,5), (5,5), (6,6), (7,7), (8,7), (9,7), (10,8), (11,7), (12,7)],
        2039: [(1,5), (2,4), (3,6), (4,5), (5,6), (6,6), (7,7), (8,8), (9,8), (10,8), (11,8), (12,7)],
        2040: [(1,6), (2,4), (3,5), (4,4), (5,5), (6,5), (7,7), (8,7), (9,7), (10,8), (11,7), (12,7)],
        2041: [(1,5), (2,3), (3,5), (4,4), (5,5), (6,5), (7,7), (8,7), (9,7), (10,8), (11,7), (12,7)],
        2042: [(1,5), (2,4), (3,5), (4,5), (5,5), (6,6), (7,7), (8,7), (9,7), (10,8), (11,7), (12,7)],
        2043: [(1,5), (2,4), (3,6), (4,5), (5,6), (6,6), (7,7), (8,8), (9,8), (10,8), (11,8), (12,7)],
        2044: [(1,6), (2,4), (3,5), (4,4), (5,5), (6,5), (7,6), (8,7), (9,7), (10,8), (11,7), (12,6)],
        2045: [(1,5), (2,3), (3,5), (4,4), (5,5), (6,5), (7,7), (8,7), (9,7), (10,8), (11,7), (12,7)],
        2046: [(1,5), (2,4), (3,5), (4,5), (5,5), (6,6), (7,7), (8,7), (9,7), (10,8), (11,7), (12,7)],
        2047: [(1,5), (2,4), (3,6), (4,5), (5,6), (6,6), (7,7), (8,8), (9,8), (10,8), (11,8), (12,7)],
        2048: [(1,6), (2,4), (3,5), (4,4), (5,5), (6,5), (7,6), (8,7), (9,7), (10,8), (11,7), (12,6)],
        2049: [(1,5), (2,3), (3,5), (4,4), (5,5), (6,5), (7,7), (8,7), (9,7), (10,8), (11,7), (12,7)],
        2050: [(1,5), (2,4), (3,5), (4,5), (5,5), (6,6), (7,7), (8,7), (9,7), (10,8), (11,7), (12,7)]
    ]

    // 如果有精确数据则使用
    if let dates = jieqiTable[year] {
        return dates.map { (month: $0.0, day: $0.1) }
    }

    // 年份超出精确数据范围，记录警告
    if !jieqiSupportedYearRange.contains(year) {
        BaziLogger.shared.warning(
            "年份 \(year) 超出节气精确数据范围 (\(jieqiSupportedYearRange.lowerBound)-\(jieqiSupportedYearRange.upperBound))，使用通用算法计算，精度可能降低"
        )
    }

    // 否则使用通用算法
    var result: [(Int, Int)] = []

    // 使用寿星天文历简化公式
    let jieqiBase: [(month: Int, c21: Double, c20: Double)] = [
        (1, 5.4055, 6.11),    // 小寒
        (2, 3.87, 4.6295),    // 立春
        (3, 5.63, 6.3826),    // 惊蛰
        (4, 4.81, 5.59),      // 清明
        (5, 5.52, 6.318),     // 立夏
        (6, 5.678, 6.5),      // 芒种
        (7, 7.108, 7.928),    // 小暑
        (8, 7.5, 8.35),       // 立秋
        (9, 7.646, 8.44),     // 白露
        (10, 8.318, 9.098),   // 寒露
        (11, 7.438, 8.218),   // 立冬
        (12, 7.18, 7.9),      // 大雪
    ]

    let century = year / 100
    let y = year % 100

    for jieqi in jieqiBase {
        let c = century == 20 ? jieqi.c21 : jieqi.c20
        let leapCount = (y - 1) / 4
        let day = Int(Double(y) * 0.2422 + c) - leapCount
        result.append((jieqi.month, day))
    }

    return result
}

// MARK: - 节气计算常量（寿星万年历算法）

private let D = 0.2422

/// 21世纪节气C值表
private let SOLAR_TERM_C_21 = [
    6.11, 20.84,    // 小寒、大寒
    4.21, 19.04,    // 立春、雨水
    5.96, 20.85,    // 惊蛰、春分
    5.26, 20.26,    // 清明、谷雨
    5.99, 21.40,    // 立夏、小满
    6.41, 21.93,    // 芒种、夏至
    7.65, 23.33,    // 小暑、大暑
    7.83, 23.42,    // 立秋、处暑
    8.08, 23.44,    // 白露、秋分
    8.82, 23.81,    // 寒露、霜降
    8.08, 22.83,    // 立冬、小雪
    7.53, 22.18     // 大雪、冬至
]

/// 20世纪节气C值表
private let SOLAR_TERM_C_20 = [
    6.50, 21.20,    // 小寒、大寒
    4.64, 19.44,    // 立春、雨水
    6.31, 21.22,    // 惊蛰、春分
    5.59, 20.59,    // 清明、谷雨
    6.32, 21.73,    // 立夏、小满
    6.72, 22.24,    // 芒种、夏至
    7.93, 23.60,    // 小暑、大暑
    8.09, 23.69,    // 立秋、处暑
    8.32, 23.70,    // 白露、秋分
    9.05, 24.05,    // 寒露、霜降
    8.32, 23.07,    // 立冬、小雪
    7.77, 22.41     // 大雪、冬至
]

/// 特殊年份节气偏移修正表
private let SOLAR_TERM_OFFSET: [Int: [Int: Int]] = [
    0: [2019: -1],       // 小寒
    2: [2026: -1],       // 立春
    4: [2084: -1],       // 惊蛰
    6: [2019: 1],        // 清明
    8: [1911: 1, 2016: 1],  // 立夏
    9: [2008: 1],        // 小满
    10: [1902: 1],       // 芒种
    11: [1928: 1],       // 夏至
    12: [1925: 1, 2016: 1], // 小暑
    13: [1922: 1],       // 大暑
    14: [2002: 1],       // 立秋
    16: [1927: 1],       // 白露
    17: [1942: 1],       // 秋分
    19: [2089: 1],       // 霜降
    20: [2089: 1],       // 立冬
    21: [1978: 1],       // 小雪
    22: [1954: 1],       // 大雪
    23: [1918: -1, 2021: -1]  // 冬至
]

/// 计算指定年份指定节气的公历日期
func getSolarTermDay(year: Int, termIndex: Int) -> Int {
    let y = year % 100
    let century = year / 100

    let c: Double
    if century == 20 {
        c = SOLAR_TERM_C_21[termIndex]
    } else if century == 19 {
        c = SOLAR_TERM_C_20[termIndex]
    } else {
        c = SOLAR_TERM_C_21[termIndex]
    }

    let leapYears = (century == 19) ? ((y - 1) / 4) : (y / 4)
    var day = Int(Double(y) * D + c) - leapYears

    if let offsets = SOLAR_TERM_OFFSET[termIndex], let offset = offsets[year] {
        day += offset
    }

    return day
}

// MARK: - 四柱计算命名空间

/// 四柱（年月日时柱）计算器
/// 封装所有柱子计算的核心逻辑
enum PillarCalculator {

    // MARK: - 年柱计算

    /// 根据立春判断年柱的年份
    static func getLunarYear(year: Int, month: Int, day: Int) -> Int {
        let jieqiDates = getJieqiDates(year: year)
        let lichun = jieqiDates[1]  // 立春

        if month < lichun.month || (month == lichun.month && day < lichun.day) {
            return year - 1
        }
        return year
    }

    /// 获取年柱信息
    static func getYearPillar(year: Int, month: Int, day: Int) -> (yearGan: String, yearZhi: String, shengXiao: String) {
        let lunarYear = getLunarYear(year: year, month: month, day: day)
        let g = (lunarYear - 1984) % 10
        let z = (lunarYear - 1984) % 12
        let ganIndex = (g + 10) % 10
        let zhiIndex = (z + 12) % 12
        return (BaziConstants.tianGan[ganIndex], BaziConstants.diZhi[zhiIndex], BaziConstants.shengXiao[zhiIndex])
    }

    // MARK: - 月柱计算

    /// 根据节气确定月支索引（0=子, 1=丑, 2=寅, ...）
    static func getMonthZhiByJieqi(year: Int, month: Int, day: Int) -> Int {
        let jieqiDates = getJieqiDates(year: year)

        // 检查是否在大雪之后（子月）
        if month > jieqiDates[11].month || (month == jieqiDates[11].month && day >= jieqiDates[11].day) {
            return 0  // 子月
        }

        // 检查是否在小寒之前（还是上一年的子月）
        if month < jieqiDates[0].month || (month == jieqiDates[0].month && day < jieqiDates[0].day) {
            return 0  // 子月
        }

        // 检查各个节气
        for i in (0..<12).reversed() {
            let jieqi = jieqiDates[i]
            if month > jieqi.month || (month == jieqi.month && day >= jieqi.day) {
                return (i + 1) % 12
            }
        }

        return 1  // 默认丑月
    }

    /// 获取月柱
    static func getMonthPillar(year: Int, month: Int, day: Int, yearGan: String) -> Pillar {
        let lunarYear = getLunarYear(year: year, month: month, day: day)
        let g = (lunarYear - 1984) % 10
        let actualYearGanIndex = (g + 10) % 10

        let zhiIndex = getMonthZhiByJieqi(year: year, month: month, day: day)

        // 月天干：五虎遁月诀（甲己丙作首、乙庚戊为头、丙辛寻庚上、丁壬壬位、戊癸壬寅）
        let yinGanMap = [2, 4, 6, 8, 8]  // 甲0己5→丙2, 乙1庚6→戊4, 丙2辛7→庚6, 丁3壬8→壬8, 戊4癸9→壬8
        let yinGan = yinGanMap[actualYearGanIndex % 5]

        let offset = (zhiIndex - 2 + 12) % 12
        let ganIndex = (yinGan + offset) % 10

        return Pillar(gan: BaziConstants.tianGan[ganIndex], zhi: BaziConstants.diZhi[zhiIndex])
    }

    // MARK: - 日柱计算

    /// 获取日柱
    /// 基准日期：2000年1月1日为戊午日
    /// 戊在天干中索引为4，午在地支中索引为6
    static func getDayPillar(year: Int, month: Int, day: Int) -> Pillar {
        let calendar = Calendar.current
        guard let baseDate = calendar.date(from: DateComponents(year: 2000, month: 1, day: 1)),
              let targetDate = calendar.date(from: DateComponents(year: year, month: month, day: day)) else {
            BaziLogger.shared.warning("日期无效无法计算日柱: \(year)年\(month)月\(day)日，回退为甲子")
            return Pillar(gan: "甲", zhi: "子")
        }

        let diff = calendar.dateComponents([.day], from: baseDate, to: targetDate).day ?? 0

        // 基准日干支索引：戊(4)午(6)
        let baseDayGanIndex = 4
        let baseDayZhiIndex = 6

        // 使用大数确保取模结果为正数
        let ganIndex = (baseDayGanIndex + diff % 10 + 10000) % 10
        let zhiIndex = (baseDayZhiIndex + diff % 12 + 12000) % 12

        return Pillar(gan: BaziConstants.tianGan[ganIndex], zhi: BaziConstants.diZhi[zhiIndex])
    }

    // MARK: - 时柱计算

    /// 获取时柱
    /// - Parameters:
    ///   - hour: 小时（0-23）
    ///   - dayGan: 日天干
    /// - Returns: 时柱。如果天干无效，返回默认的甲子时柱并记录错误
    static func getHourPillar(hour: Int, dayGan: String) -> Pillar {
        guard let dayGanIndex = BaziConstants.tianGan.firstIndex(of: dayGan) else {
            BaziLogger.shared.error("无效的日天干: \(dayGan)，使用默认时柱")
            return Pillar(gan: "甲", zhi: "子")
        }
        let zhiIndex = (hour + 1) / 2 % 12
        let ganIndex = (dayGanIndex % 5 * 2 + zhiIndex) % 10
        return Pillar(gan: BaziConstants.tianGan[ganIndex], zhi: BaziConstants.diZhi[zhiIndex])
    }

    /// 计算夜子时的日干
    /// 23:00-23:59 使用当天日柱，但时柱用下一天日干计算
    /// - Parameters:
    ///   - year: 年
    ///   - month: 月
    ///   - day: 日
    ///   - hour: 时（0-23）
    ///   - currentDayPillar: 当天日柱
    /// - Returns: 用于计算时柱的日干
    static func getHourDayGan(year: Int, month: Int, day: Int, hour: Int, currentDayPillar: Pillar) -> String {
        guard hour == 23 else {
            return currentDayPillar.gan
        }

        // 夜子时：获取下一天的日干
        let calendar = Calendar.current
        let currentComponents = DateComponents(year: year, month: month, day: day)

        guard let currentDate = calendar.date(from: currentComponents),
              let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
            return currentDayPillar.gan
        }

        let nextComponents = calendar.dateComponents([.year, .month, .day], from: nextDate)
        let nextDayPillar = getDayPillar(
            year: nextComponents.year ?? year,
            month: nextComponents.month ?? month,
            day: nextComponents.day ?? day + 1
        )
        return nextDayPillar.gan
    }
}

// MARK: - 全局函数（向后兼容，建议使用 PillarCalculator）

/// 根据立春判断年柱的年份
/// - Note: 建议使用 `PillarCalculator.getLunarYear`
func getLunarYear(year: Int, month: Int, day: Int) -> Int {
    PillarCalculator.getLunarYear(year: year, month: month, day: day)
}

/// 根据节气确定月支索引
/// - Note: 建议使用 `PillarCalculator.getMonthZhiByJieqi`
func getMonthZhiByJieqi(year: Int, month: Int, day: Int) -> Int {
    PillarCalculator.getMonthZhiByJieqi(year: year, month: month, day: day)
}

/// 获取年柱信息
/// - Note: 建议使用 `PillarCalculator.getYearPillar`
func getLunar(year: Int, month: Int, day: Int) -> (yearGan: String, yearZhi: String, shengXiao: String) {
    PillarCalculator.getYearPillar(year: year, month: month, day: day)
}

/// 获取月柱
/// - Note: 建议使用 `PillarCalculator.getMonthPillar`
func getMonthPillar(year: Int, month: Int, day: Int, yearGan: String) -> Pillar {
    PillarCalculator.getMonthPillar(year: year, month: month, day: day, yearGan: yearGan)
}

/// 获取日柱
/// - Note: 建议使用 `PillarCalculator.getDayPillar`
func getDayPillar(year: Int, month: Int, day: Int) -> Pillar {
    PillarCalculator.getDayPillar(year: year, month: month, day: day)
}

/// 获取时柱
/// - Note: 建议使用 `PillarCalculator.getHourPillar`
func getHourPillar(hour: Int, dayGan: String) -> Pillar {
    PillarCalculator.getHourPillar(hour: hour, dayGan: dayGan)
}

// MARK: - 大运计算

/// 获取大运列表
/// - Parameters:
///   - gender: 性别 ("male" 或 "female")
///   - yearGan: 年天干
///   - monthGan: 月天干
///   - monthZhi: 月地支
///   - qiYunAge: 起运年龄
/// - Returns: 大运列表（11步）。如果参数无效，返回空数组并记录错误
func getDaYun(gender: String, yearGan: String, monthGan: String, monthZhi: String, qiYunAge: Int) -> [DaYun] {
    let isYangYear = BaziConstants.yinYang[yearGan] == "阳"
    let isMale = gender == "male"
    let forward = isYangYear == isMale

    guard var gi = BaziConstants.tianGan.firstIndex(of: monthGan) else {
        BaziLogger.shared.error("无效的月天干: \(monthGan)，无法计算大运")
        return []
    }

    guard var zi = BaziConstants.diZhi.firstIndex(of: monthZhi) else {
        BaziLogger.shared.error("无效的月地支: \(monthZhi)，无法计算大运")
        return []
    }

    return (0..<11).map { i in
        gi = forward ? (gi + 1) % 10 : (gi + 9) % 10
        zi = forward ? (zi + 1) % 12 : (zi + 11) % 12
        return DaYun(gan: BaziConstants.tianGan[gi], zhi: BaziConstants.diZhi[zi], age: qiYunAge + i * 10)
    }
}

/// 计算起运年龄（虚岁）
/// 三天折一年，计算从出生日到下一个（或上一个）节气的天数
func calculateQiYunAge(birthYear: Int, birthMonth: Int, birthDay: Int, gender: String, yearGan: String, monthZhi: String) -> Int {
    let defaultAge = 4  // 默认起运年龄

    let isYangYear = BaziConstants.yinYang[yearGan] == "阳"
    let isMale = gender == "male"
    let forward = isYangYear == isMale

    let monthZhiToJie: [String: Int] = [
        "寅": 2, "卯": 4, "辰": 6, "巳": 8, "午": 10, "未": 12,
        "申": 14, "酉": 16, "戌": 18, "亥": 20, "子": 22, "丑": 0
    ]

    guard let currentJieIndex = monthZhiToJie[monthZhi] else { return defaultAge }

    let targetJieIndex: Int
    if forward {
        targetJieIndex = (currentJieIndex + 2) % 24
    } else {
        targetJieIndex = currentJieIndex
    }

    let targetMonth = (targetJieIndex / 2) + 1
    let adjustedTargetYear: Int
    if forward && targetJieIndex < currentJieIndex {
        adjustedTargetYear = birthYear + 1
    } else if !forward && targetJieIndex > currentJieIndex {
        adjustedTargetYear = birthYear
    } else {
        adjustedTargetYear = birthYear
    }

    let targetDay = getSolarTermDay(year: adjustedTargetYear, termIndex: targetJieIndex)

    let calendar = Calendar.current
    let birthComponents = DateComponents(year: birthYear, month: birthMonth, day: birthDay)
    let targetComponents = DateComponents(year: adjustedTargetYear, month: targetMonth, day: targetDay)

    guard let birthDate = calendar.date(from: birthComponents),
          let targetDate = calendar.date(from: targetComponents) else { return defaultAge }

    // 使用当日 0 点再算天数差，避免时辰影响；取绝对值（顺推/逆推都可能 target 在 birth 前）
    let birthStart = calendar.startOfDay(for: birthDate)
    let targetStart = calendar.startOfDay(for: targetDate)
    let daysDiff = abs(calendar.dateComponents([.day], from: birthStart, to: targetStart).day ?? 0)

    // 三天折一年
    let daysPerYear = 3
    let qiYunAge = max(1, (daysDiff + daysPerYear - 1) / daysPerYear)

    return qiYunAge
}

// MARK: - 十神计算

/// 获取十神
/// - Parameters:
///   - riGan: 日主天干
///   - targetGan: 目标天干
/// - Returns: 十神名称。如果参数无效，返回"未知"并记录警告
func getShiShen(riGan: String, targetGan: String) -> String {
    guard let riWx = BaziConstants.wuXing[riGan],
          let targetWx = BaziConstants.wuXing[targetGan],
          let riYy = BaziConstants.yinYang[riGan],
          let targetYy = BaziConstants.yinYang[targetGan] else {
        if BaziConstants.wuXing[riGan] == nil {
            BaziLogger.shared.warning("无效的日主天干: \(riGan)")
        }
        if BaziConstants.wuXing[targetGan] == nil {
            BaziLogger.shared.warning("无效的目标天干: \(targetGan)")
        }
        return "未知"
    }
    let same = riYy == targetYy

    if riWx == targetWx { return same ? "比肩" : "劫财" }
    if BaziConstants.wuXingSheng[riWx] == targetWx { return same ? "食神" : "伤官" }
    if BaziConstants.wuXingKe[riWx] == targetWx { return same ? "偏财" : "正财" }
    if BaziConstants.wuXingKe[targetWx] == riWx { return same ? "七杀" : "正官" }
    if BaziConstants.wuXingSheng[targetWx] == riWx { return same ? "偏印" : "正印" }

    // 理论上不应该到达这里，但作为防御性编程
    BaziLogger.shared.warning("无法确定十神关系: 日主=\(riGan)(\(riWx)), 目标=\(targetGan)(\(targetWx))")
    return "未知"
}

/// 获取地支对应的十神（通过地支藏干的本气）
/// - Parameters:
///   - riGan: 日主天干
///   - zhi: 地支
/// - Returns: 十神名称。如果地支无效，返回"未知"并记录警告
func getZhiShiShen(riGan: String, zhi: String) -> String {
    guard let cangGanList = BaziConstants.cangGan[zhi], !cangGanList.isEmpty else {
        BaziLogger.shared.warning("无效的地支或藏干为空: \(zhi)")
        return "未知"
    }
    return getShiShen(riGan: riGan, targetGan: cangGanList[0])
}

// MARK: - 流年干支

/// 获取指定公历年份的流年干支（与年柱基准一致：1984 甲子年）
/// - Parameter year: 公历年份
/// - Returns: (天干, 地支)
func getLiuNianGanZhi(year: Int) -> (gan: String, zhi: String) {
    let g = (year - 1984) % 10
    let z = (year - 1984) % 12
    return (BaziConstants.tianGan[(g + 10) % 10], BaziConstants.diZhi[(z + 12) % 12])
}
