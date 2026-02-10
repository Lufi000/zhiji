import Foundation

// MARK: - 节气与季节（手帐展示用，不解读）

/// 12「节」名称，与 getJieqiDates(year:) 返回顺序一致
/// 顺序：小寒、立春、惊蛰、清明、立夏、芒种、小暑、立秋、白露、寒露、立冬、大雪
let jieQiNames: [String] = [
    "小寒", "立春", "惊蛰", "清明", "立夏", "芒种",
    "小暑", "立秋", "白露", "寒露", "立冬", "大雪"
]

/// 四季（用于手帐分区展示）
enum Season: String, CaseIterable {
    case spring = "春"
    case summer = "夏"
    case autumn = "秋"
    case winter = "冬"
}

/// 某年一个节气的展示用信息
struct JieQiItem: Identifiable {
    var id: String { "\(year)-\(index)" }
    let year: Int
    let index: Int
    let name: String
    let month: Int
    let day: Int

    var dateText: String { "\(month)月\(day)日" }
}

/// 某年四季的展示（起止节气名）
struct SeasonRange: Identifiable {
    var id: String { season.rawValue }
    let season: Season
    let rangeText: String  // 如 "立春～立夏"
}

/// 获取某年 12 节的展示列表（名称 + 月日）
func getJieQiItems(year: Int) -> [JieQiItem] {
    let dates = getJieqiDates(year: year)
    return zip(jieQiNames, dates).enumerated().map { index, pair in
        JieQiItem(year: year, index: index, name: pair.0, month: pair.1.month, day: pair.1.day)
    }
}

/// 获取某年四季的展示（立春～立夏 / 立夏～立秋 / 立秋～立冬 / 立冬～小寒）
func getSeasonRanges(year: Int) -> [SeasonRange] {
    [
        SeasonRange(season: .spring, rangeText: "立春～立夏"),
        SeasonRange(season: .summer, rangeText: "立夏～立秋"),
        SeasonRange(season: .autumn, rangeText: "立秋～立冬"),
        SeasonRange(season: .winter, rangeText: "立冬～小寒")
    ]
}
