import SwiftUI

// MARK: - 十神分析视图

struct ShiShenView: View {
    let bazi: Bazi

    private var analyzer: ShiShenAnalyzer { ShiShenAnalyzer(bazi: bazi) }
    private var result: ShiShenResult { analyzer.analyze() }

    // 获取日主五行
    private var dayMasterWuXing: String {
        BaziConstants.wuXing[bazi.day.gan] ?? "木"
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                // 标题
                Text("十神分布")
                    .font(.system(size: 15, weight: .light))
                    .foregroundColor(DesignSystem.textPrimary)
                    .tracking(2)

                // 十神统计 - 只显示有能量的十神
                VStack(spacing: 12) {
                    ForEach(result.items.filter { $0.totalScore > 0 }) { item in
                        ShiShenDetailBar(item: item, dayMasterWuXing: dayMasterWuXing, totalScore: result.items.reduce(0) { $0 + $1.totalScore })
                    }
                }
            }
            .padding(20)
        }
    }
}

// MARK: - 十神详细条形图

struct ShiShenDetailBar: View {
    let item: ShiShenDetail
    let dayMasterWuXing: String
    let totalScore: Double

    // 根据十神获取对应的五行颜色
    private var shiShenColor: Color {
        let wuXing = getWuXingForShiShen(item.shiShen)
        return WuXingColor.colors(for: wuXing).secondary
    }

    // 十神对应的五行（基于日主五行推算）
    private func getWuXingForShiShen(_ shiShen: String) -> String {
        let wuXingOrder = ["木", "火", "土", "金", "水"]
        guard let dayMasterIndex = wuXingOrder.firstIndex(of: dayMasterWuXing) else {
            return dayMasterWuXing
        }

        switch shiShen {
        case "比肩", "劫财":
            return dayMasterWuXing
        case "正印", "偏印":
            return wuXingOrder[(dayMasterIndex + 4) % 5]
        case "食神", "伤官":
            return wuXingOrder[(dayMasterIndex + 1) % 5]
        case "正财", "偏财":
            return wuXingOrder[(dayMasterIndex + 2) % 5]
        case "正官", "七杀":
            return wuXingOrder[(dayMasterIndex + 3) % 5]
        default:
            return dayMasterWuXing
        }
    }

    // 获取十神的白话名称（让用户秒懂）
    private var shiShenNickname: String {
        switch item.shiShen {
        case "比肩": return "朋友能量"
        case "劫财": return "竞争能量"
        case "正印": return "贵人能量"
        case "偏印": return "思考能量"
        case "食神": return "才华能量"
        case "伤官": return "创意能量"
        case "正财": return "稳财能量"
        case "偏财": return "横财能量"
        case "正官": return "事业能量"
        case "七杀": return "拼搏能量"
        default: return ""
        }
    }

    // 获取十神的简要说明
    private var shiShenDescription: String {
        switch item.shiShen {
        case "比肩": return "独立·合作"
        case "劫财": return "竞争·冲劲"
        case "正印": return "学习·贵人"
        case "偏印": return "偏才·孤独"
        case "食神": return "才华·福气"
        case "伤官": return "表现·叛逆"
        case "正财": return "稳定·务实"
        case "偏财": return "机遇·慷慨"
        case "正官": return "责任·正统"
        case "七杀": return "魄力·压力"
        default: return ""
        }
    }

    // 计算百分比
    private var percentage: Double {
        guard totalScore > 0 else { return 0 }
        return item.totalScore / totalScore * 100
    }

    var body: some View {
        HStack(spacing: 10) {
            // 十神标签
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(item.shiShen)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(shiShenColor)

                    // 白话名称
                    Text(shiShenNickname)
                        .font(.system(size: 10, weight: .light))
                        .foregroundColor(DesignSystem.textSecondary)

                }

                Text(shiShenDescription)
                    .font(.system(size: 9, weight: .light))
                    .foregroundColor(DesignSystem.textTertiary)
            }
            .frame(width: 115, alignment: .leading)

            // 能量条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 背景条
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 8)

                    // 能量填充
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [shiShenColor.opacity(0.6), shiShenColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: max(4, geometry.size.width * CGFloat(percentage / 100) * 2.5),
                            height: 8
                        )
                }
            }
            .frame(height: 8)

            // 强度和百分比
            HStack(spacing: 4) {
                Text(item.strengthLevel)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(getStrengthColor(item.strengthLevel))

                Text(String(format: "%.0f%%", percentage))
                    .font(.system(size: 10, weight: .light, design: .monospaced))
                    .foregroundColor(DesignSystem.textSecondary)
            }
            .frame(width: 55, alignment: .trailing)
        }
    }

    private func getStrengthColor(_ strength: String) -> Color {
        switch strength {
        case "极旺": return WuXingColor.stoneColor
        case "偏旺": return DesignSystem.primaryOrange
        case "中和": return WuXingColor.grassColor
        case "偏弱": return WuXingColor.waveColor
        case "虚浮": return DesignSystem.textTertiary
        default: return DesignSystem.textSecondary
        }
    }
}
