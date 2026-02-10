import Foundation

// MARK: - 十神解读报告数据模型

/// 天干分析
struct GanAnalysis {
    let gan: String           // 天干
    let wuXing: String        // 五行
    let shiShen: String?      // 十神（日干无十神）
    let description: String   // 天干本身含义
    let shiShenDescription: String?  // 十神在此柱位的解读
}

/// 藏干分析
struct CangGanAnalysis {
    let gan: String           // 藏干
    let wuXing: String        // 五行
    let shiShen: String       // 十神
    let type: String          // 本气、中气、余气
    let description: String   // 十神在此柱位的解读
}

/// 地支分析
struct ZhiAnalysis {
    let zhi: String           // 地支
    let wuXing: String        // 五行
    let description: String   // 地支本身含义
    let cangGanList: [CangGanAnalysis]  // 藏干分析列表
}

/// 柱位分析
struct PillarAnalysis {
    let pillarName: String    // 年柱、月柱、日柱、时柱
    let ageRange: String      // 年龄段
    let tianGan: GanAnalysis?
    let diZhi: ZhiAnalysis
}

/// 日主概述
struct DayMasterSection {
    let gan: String
    let wuXing: String
    let description: String
    let strength: String
    let strengthScore: Int
    let xiYong: XiYongShenResult?
    let tiaoHou: TiaoHouResult?
}

/// 十神格局总结
struct ShiShenSummary {
    let strongestShiShen: String?      // 最旺十神
    let strongestDescription: String?  // 最旺十神解读
}

/// 完整的十神解读报告
/// - TODO: 暂未接入。若产品需要「十神解读」全屏报告，需增加从 ResultViewModel / StrengthCalculator / ShiShenAnalyzer 等构建本结构的工厂，并在命盘页提供展示入口。
struct ShiShenReport {
    let dayMaster: DayMasterSection       // 日主概述
    let pillarAnalysisList: [PillarAnalysis]  // 四柱分析
    let summary: ShiShenSummary           // 格局总结

    /// 生成完整的文字报告
    func generateFullText() -> String {
        var text = ""

        // 一、日主概述
        text += "【日主概述】\n\n"
        text += "你的日主是\(dayMaster.gan)，五行属\(dayMaster.wuXing)。\n"
        text += dayMaster.description + "\n\n"

        if let xiYong = dayMaster.xiYong, !xiYong.xi.isEmpty {
            text += "喜神：\(xiYong.xi.joined(separator: "、"))\n"
            text += "忌神：\(xiYong.ji.joined(separator: "、"))\n"
        }
        if let tiaoHou = dayMaster.tiaoHou,
           let th = tiaoHou.tiaoHou,
           let reason = tiaoHou.reason {
            text += "调候：\(th)（\(reason)）\n"
        }

        text += "\n"

        // 二、四柱解读
        for pillar in pillarAnalysisList {
            text += "【\(pillar.pillarName)】（\(pillar.ageRange)）\n\n"

            // 天干解读（日柱跳过天干，因为日干就是日主）
            if let tianGan = pillar.tianGan {
                text += "○ \(pillar.pillarName.prefix(1))干 \(tianGan.gan)（\(tianGan.wuXing)）"
                if let shiShen = tianGan.shiShen {
                    text += " - \(shiShen)"
                }
                text += "\n"

                if let shiShenDesc = tianGan.shiShenDescription {
                    text += shiShenDesc + "\n"
                }
                text += "\n"
            }

            // 地支解读
            text += "○ \(pillar.pillarName.prefix(1))支 \(pillar.diZhi.zhi)（\(pillar.diZhi.wuXing)）\n"

            // 藏干解读
            for cangGan in pillar.diZhi.cangGanList {
                text += "\n  · 藏干 \(cangGan.gan)（\(cangGan.wuXing)·\(cangGan.type)）- \(cangGan.shiShen)\n"
                text += "    " + cangGan.description.replacingOccurrences(of: "\n", with: "\n    ") + "\n"
            }

            text += "\n"
        }

        // 三、格局总结
        if let strongest = summary.strongestShiShen, let desc = summary.strongestDescription {
            text += "【格局特点】\n\n"
            text += "你的命盘中\(strongest)能量最旺。\n"
            text += desc + "\n"
        }

        return text
    }
}
