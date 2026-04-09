import Foundation

/// 用户保存的命盘快照（可多条），用于助手注入与再次展示。
struct SavedMingPanRecord: Codable, Identifiable, Equatable {
    var id: UUID
    /// 展示名称（如「我的」「家人」）
    var displayName: String
    var birthYear: Int
    var birthMonth: Int
    var birthDay: Int
    var birthHour: Int
    var birthMinute: Int
    var gender: String
    var yearGan: String
    var yearZhi: String
    var monthGan: String
    var monthZhi: String
    var dayGan: String
    var dayZhi: String
    var hourGan: String
    var hourZhi: String
    var shengXiao: String

    var birth: (year: Int, month: Int, day: Int, hour: Int, minute: Int) {
        (birthYear, birthMonth, birthDay, birthHour, birthMinute)
    }

    var bazi: Bazi {
        Bazi(
            year: Pillar(gan: yearGan, zhi: yearZhi),
            month: Pillar(gan: monthGan, zhi: monthZhi),
            day: Pillar(gan: dayGan, zhi: dayZhi),
            hour: Pillar(gan: hourGan, zhi: hourZhi),
            shengXiao: shengXiao
        )
    }

    init(
        id: UUID = UUID(),
        displayName: String,
        birth: (year: Int, month: Int, day: Int, hour: Int, minute: Int),
        gender: String,
        bazi: Bazi
    ) {
        self.id = id
        self.displayName = displayName
        self.birthYear = birth.year
        self.birthMonth = birth.month
        self.birthDay = birth.day
        self.birthHour = birth.hour
        self.birthMinute = birth.minute
        self.gender = gender
        self.yearGan = bazi.year.gan
        self.yearZhi = bazi.year.zhi
        self.monthGan = bazi.month.gan
        self.monthZhi = bazi.month.zhi
        self.dayGan = bazi.day.gan
        self.dayZhi = bazi.day.zhi
        self.hourGan = bazi.hour.gan
        self.hourZhi = bazi.hour.zhi
        self.shengXiao = bazi.shengXiao
    }
}
