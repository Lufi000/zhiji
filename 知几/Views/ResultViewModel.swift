import Foundation
import SwiftUI

// MARK: - ResultView ViewModel

/// ResultView 的 ViewModel，负责管理八字分析的业务逻辑和状态
@Observable
@MainActor
final class ResultViewModel {
    // MARK: - Input Data

    let bazi: Bazi
    let birth: (year: Int, month: Int, day: Int, hour: Int)
    let gender: String

    // MARK: - UI State

    var showStrengthPicker = false
    var selectedDaYunIndex: Int? = nil
    var selectedLiuNianYear: Int? = nil
    var selectedWeekIndex: Int? = nil
    var customStrength: String? = nil
    var selectedExplanationType: ExplanationType?

    // Toast State
    var showCopiedToast = false

    // MARK: - Cached Calculation Results (在 init 中一次性计算)

    /// 身强身弱计算结果
    let strengthResult: StrengthResult

    /// 调候用神计算结果
    let tiaoHouResult: TiaoHouResult

    /// 大运列表
    let daYunList: [DaYun]

    /// 十神分析结果
    let shiShenResult: ShiShenResult

    /// 起运年龄
    let qiYunAge: Int

    /// 喜用神计算结果（可变，因为用户可以自定义身强身弱）
    private(set) var xiYongShenResult: XiYongShenResult

    // MARK: - Initialization

    init(bazi: Bazi, birth: (year: Int, month: Int, day: Int, hour: Int), gender: String) {
        self.bazi = bazi
        self.birth = birth
        self.gender = gender

        // 一次性计算所有核心结果
        let calculator = StrengthCalculator(bazi: bazi)
        self.strengthResult = calculator.calculate()
        self.xiYongShenResult = calculator.calculateXiYongShen(strength: strengthResult.strength)
        self.tiaoHouResult = calculator.calculateTiaoHou()
        self.shiShenResult = ShiShenAnalyzer(bazi: bazi).analyze()

        self.qiYunAge = calculateQiYunAge(
            birthYear: birth.year,
            birthMonth: birth.month,
            birthDay: birth.day,
            gender: gender,
            yearGan: bazi.year.gan,
            monthZhi: bazi.month.zhi
        )

        self.daYunList = getDaYun(
            gender: gender,
            yearGan: bazi.year.gan,
            monthGan: bazi.month.gan,
            monthZhi: bazi.month.zhi,
            qiYunAge: qiYunAge
        )
    }

    // MARK: - Computed Properties

    /// 当前生效的身强身弱
    var effectiveStrength: String {
        customStrength ?? strengthResult.strength
    }

    /// 当前年龄
    var currentAge: Int {
        let currentYear = Calendar.current.component(.year, from: Date())
        return currentYear - birth.year
    }

    /// 当前所处大运索引
    var currentDaYunIndex: Int {
        daYunList.firstIndex { currentAge >= $0.age && currentAge < $0.age + 10 } ?? 0
    }

    /// 日主五行
    var dayMasterWuXing: String {
        BaziConstants.wuXing[bazi.day.gan] ?? "木"
    }

    /// 五行关系分析
    var wuXingAnalysis: WuXingAnalysis {
        analyzeWuXingRelations(bazi: bazi)
    }

    // MARK: - Actions

    /// 更新喜用神（当用户手动选择身强身弱时）
    func updateXiYongShen() {
        xiYongShenResult = StrengthCalculator(bazi: bazi).calculateXiYongShen(strength: effectiveStrength)
    }

    /// 切换身强身弱选择器
    func toggleStrengthPicker() {
        withAnimation(.easeInOut(duration: 0.2)) {
            showStrengthPicker.toggle()
        }
    }

    /// 选择身强身弱
    func selectStrength(_ option: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if option == strengthResult.strength {
                customStrength = nil
            } else {
                customStrength = option
            }
            updateXiYongShen()
            showStrengthPicker = false
        }
    }

    /// 复制全盘信息
    func copyFullBaziInfo() {
        let info = generateFullBaziInfo()
        UIPasteboard.general.string = info
        showCopiedToast = true

        // 自动隐藏 Toast
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            showCopiedToast = false
        }
    }

    /// 生成全盘信息文本
    private func generateFullBaziInfo() -> String {
        var info = "【八字命盘】\n"
        info += "\(birth.year)年\(birth.month)月\(birth.day)日 \(birth.hour)时 \(gender)\n\n"
        info += "四柱：\(bazi.year.gan)\(bazi.year.zhi) \(bazi.month.gan)\(bazi.month.zhi) \(bazi.day.gan)\(bazi.day.zhi) \(bazi.hour.gan)\(bazi.hour.zhi)\n"
        info += "日主：\(bazi.day.gan) \(effectiveStrength)\n"
        info += "喜神：\(xiYongShenResult.xi.joined(separator: "、"))\n"
        info += "忌神：\(xiYongShenResult.ji.joined(separator: "、"))\n"
        return info
    }

    /// 获取天干十神
    func getGanShiShen(position: String, gan: String) -> String {
        if position == "日" {
            return "日主"
        }
        return getShiShen(riGan: bazi.day.gan, targetGan: gan)
    }

    /// 获取地支十神（本气）
    func getZhiShiShenDisplay(_ zhi: String) -> String {
        return getZhiShiShen(riGan: bazi.day.gan, zhi: zhi)
    }

    /// 获取命盘标识（用于内购）
    var baziIdentifier: BaziIdentifier {
        BaziIdentifier(
            year: birth.year,
            month: birth.month,
            day: birth.day,
            hour: birth.hour,
            gender: gender
        )
    }

    /// 检查流年解析是否已解锁
    var isLiuNianUnlocked: Bool {
        StoreManager.shared.isLiuNianUnlocked(for: baziIdentifier)
    }
}

// MARK: - 身强身弱选项

extension ResultViewModel {
    /// 身强身弱选项列表
    static let strengthOptions = ["从强", "极强", "身强", "身弱", "极弱", "从弱"]
}
