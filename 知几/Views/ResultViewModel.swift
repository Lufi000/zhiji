import Foundation
import SwiftUI

// MARK: - ResultView ViewModel

/// ResultView 的 ViewModel，负责管理八字分析的业务逻辑和状态
@Observable
@MainActor
final class ResultViewModel {
    // MARK: - Input Data

    let bazi: Bazi
    let birth: (year: Int, month: Int, day: Int, hour: Int, minute: Int)
    let gender: String

    // MARK: - UI State

    /// Toast 文案：nil 表示不显示；非 nil 时显示对应提示（如「已复制到剪贴板」「已复制，可粘贴到 AI 进行解读」）
    var copiedToastMessage: String?

    /// 用于取消上一次 Toast 的 2 秒 Task，避免连续复制时第二次 Toast 被提前清掉
    private var toastClearTask: Task<Void, Never>?

    // MARK: - Cached Calculation Results (在 init 中一次性计算)

    /// 能量配置计算结果（内部使用传统术语）
    let strengthResult: StrengthResult

    /// 调候用神计算结果
    let tiaoHouResult: TiaoHouResult

    /// 十神分析结果
    let shiShenResult: ShiShenResult

    /// 喜用神计算结果（按系统算出的能量配置计算）
    let xiYongShenResult: XiYongShenResult

    /// 大运列表（11 步，每步 10 年）
    let daYunList: [DaYun]

    /// 起运年龄（虚岁）
    let qiYunAge: Int

    // MARK: - Initialization

    init(bazi: Bazi, birth: (year: Int, month: Int, day: Int, hour: Int, minute: Int), gender: String) {
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

    /// 当前年龄（虚岁近似：周岁 + 1）
    var currentAge: Int {
        let currentYear = Calendar.current.component(.year, from: Date())
        return currentYear - birth.year + 1
    }

    /// 当前所处大运步数（0-based），未起运为 0
    var currentDaYunStepIndex: Int {
        guard currentAge >= qiYunAge else { return 0 }
        let step = (currentAge - qiYunAge) / 10
        return min(step, max(0, daYunList.count - 1))
    }

    /// 指定大运步对应的公历年份（该大运十年所涵盖的流年）
    ///  convention: 每步大运「起」于虚岁 (起运+步数*10+1) 岁当年，即显示为 2027–2036 式起算（己丑等从次年始）
    /// 虚岁 = 公历年 - 出生年 + 1，故公历年 = 出生年 + 虚岁 - 1
    func yearsForDaYunStep(_ stepIndex: Int) -> [Int] {
        guard stepIndex >= 0, stepIndex < daYunList.count else { return [] }
        let startAge = qiYunAge + stepIndex * 10 + 1
        let endAge = startAge + 9
        return (startAge...endAge).map { birth.year + $0 - 1 }
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

    /// 复制全盘信息（通用）
    func copyFullBaziInfo() {
        let info = generateFullBaziInfo()
        UIPasteboard.general.string = info
        showCopiedToast(message: "已复制到剪贴板")
    }

    /// 复制当前命盘信息，并加上「请根据以下八字命盘进行解读」的提示语，便于用户粘贴到 AI（如 DeepSeek、ChatGPT 等）进行解读
    func copyMingPanForDeepSeek() {
        let prompt = "请根据以下八字命盘进行解读：\n\n"
        let info = prompt + generateFullBaziInfo()
        UIPasteboard.general.string = info
        showCopiedToast(message: "已复制，可粘贴到 AI 进行解读")
    }

    private func showCopiedToast(message: String) {
        toastClearTask?.cancel()
        copiedToastMessage = message
        toastClearTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard !Task.isCancelled else { return }
            copiedToastMessage = nil
        }
    }

    /// 生成全盘信息文本（含大运与流年）
    private func generateFullBaziInfo() -> String {
        var info = "【八字命盘】\n"
        info += "\(birth.year)年\(birth.month)月\(birth.day)日 \(birth.hour)时\(birth.minute)分 \(gender)\n\n"
        info += "四柱：\(bazi.year.gan)\(bazi.year.zhi) \(bazi.month.gan)\(bazi.month.zhi) \(bazi.day.gan)\(bazi.day.zhi) \(bazi.hour.gan)\(bazi.hour.zhi)\n"
        info += "日主：\(bazi.day.gan)\n"
        info += "起运：\(qiYunAge) 岁\n"
        info += "大运：\(daYunList.map { "\($0.gan)\($0.zhi)" }.joined(separator: " "))\n\n"
        info += "【流年】每步大运十年，下列为各年公历年份及流年干支：\n"
        for (index, daYun) in daYunList.enumerated() {
            let years = yearsForDaYunStep(index)
            let ageStart = daYun.age
            let ageEnd = daYun.age + 9
            let liuNianStr = years.map { y in
                let ln = getLiuNianGanZhi(year: y)
                return "\(y)\(ln.gan)\(ln.zhi)"
            }.joined(separator: " ")
            info += "  \(daYun.gan)\(daYun.zhi)（\(ageStart)-\(ageEnd)岁）：\(liuNianStr)\n"
        }
        info += "\n喜神：\(xiYongShenResult.xi.joined(separator: "、"))\n"
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

}
