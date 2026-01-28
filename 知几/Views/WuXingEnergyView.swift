import SwiftUI

// MARK: - 五行能量解读视图

struct WuXingEnergyView: View {
    let bazi: Bazi

    private var analyzer: WuXingEnergyAnalyzer { WuXingEnergyAnalyzer(bazi: bazi) }
    private var result: WuXingEnergyResult { analyzer.analyze() }
    private var analysis: WuXingAnalysis { analyzeWuXingRelations(bazi: bazi) }

    // 检查是否有五行关系
    private var hasWuXingRelations: Bool {
        !analysis.heResults.isEmpty ||
        !analysis.chongXingHaiResults.isEmpty ||
        !analysis.kuResults.isEmpty ||
        !analysis.tanShengWangKeResults.isEmpty
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                // 标题
                Text("五行能量")
                    .font(.system(size: 15, weight: .light))
                    .foregroundColor(DesignSystem.textPrimary)
                    .tracking(2)

                // 能量条形图
                VStack(spacing: 12) {
                    ForEach(result.energyItems, id: \.wuXing) { item in
                        WuXingEnergyBar(item: item, dayMasterWuXing: result.dayMasterWuXing)
                    }
                }

                // 五行能量关系部分
                if hasWuXingRelations {
                    // 分割线
                    Divider()
                        .background(Color.gray.opacity(0.2))

                    // 能量互动标题
                    Text("能量互动")
                        .font(.system(size: 13, weight: .light))
                        .foregroundColor(DesignSystem.textSecondary)
                        .tracking(1)

                    // 合会
                    if !analysis.heResults.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("合会")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(DesignSystem.textSecondary)

                            ForEach(analysis.heResults.indices, id: \.self) { i in
                                let he = analysis.heResults[i]
                                HStack(spacing: 6) {
                                    // 合的类型标签
                                    Text(he.type.rawValue)
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(WuXingColor.waveColor)
                                        .clipShape(RoundedRectangle(cornerRadius: 4))

                                    // 参与元素
                                    Text(he.elements.joined(separator: ""))
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundColor(DesignSystem.textPrimary)

                                    // 合化结果
                                    if let huaWx = he.huaWuXing {
                                        Text("→ 化\(huaWx)")
                                            .font(.system(size: 11, weight: .light))
                                            .foregroundColor(WuXingColor.colors(for: huaWx).secondary)
                                    } else if he.type == .tianGanHe {
                                        // 天干合不化显示"合绊"
                                        Text("(合绊)")
                                            .font(.system(size: 10, weight: .light))
                                            .foregroundColor(DesignSystem.textTertiary)
                                    } else if let banHeWx = he.banHeWuXing {
                                        // 地支半合/半会显示五行
                                        Text("(半合\(banHeWx))")
                                            .font(.system(size: 10, weight: .light))
                                            .foregroundColor(WuXingColor.colors(for: banHeWx).secondary.opacity(0.7))
                                    }

                                    Spacer()

                                    // 位置
                                    Text(he.positions.joined(separator: ""))
                                        .font(.system(size: 10, weight: .light))
                                        .foregroundColor(DesignSystem.textTertiary)
                                }
                            }
                        }
                    }

                    // 库
                    if !analysis.kuResults.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("库")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(DesignSystem.textSecondary)

                            ForEach(analysis.kuResults.indices, id: \.self) { i in
                                let ku = analysis.kuResults[i]
                                HStack(spacing: 6) {
                                    // 库标签
                                    if ku.isFormed, let kuWuXing = ku.kuWuXing {
                                        // 已形成库
                                        Text("\(kuWuXing)库")
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(WuXingColor.colors(for: kuWuXing).secondary)
                                            .clipShape(RoundedRectangle(cornerRadius: 4))
                                    } else {
                                        // 未形成库，只是土
                                        Text("土")
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(WuXingColor.earthColor)
                                            .clipShape(RoundedRectangle(cornerRadius: 4))
                                    }

                                    // 地支
                                    Text(ku.zhi)
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundColor(DesignSystem.textPrimary)

                                    // 形成库的条件说明
                                    if ku.isFormed, let triggerGan = ku.triggerGan, let kuWuXing = ku.kuWuXing {
                                        Text("遇\(triggerGan)→\(kuWuXing)库")
                                            .font(.system(size: 10, weight: .light))
                                            .foregroundColor(WuXingColor.colors(for: kuWuXing).secondary)
                                    } else {
                                        Text("未成库(属土)")
                                            .font(.system(size: 10, weight: .light))
                                            .foregroundColor(DesignSystem.textTertiary)
                                    }

                                    Spacer()

                                    // 位置
                                    Text(ku.position)
                                        .font(.system(size: 10, weight: .light))
                                        .foregroundColor(DesignSystem.textTertiary)
                                }
                            }
                        }
                    }

                    // 贪生忘克
                    if !analysis.tanShengWangKeResults.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("贪生忘克")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(DesignSystem.textSecondary)

                            ForEach(analysis.tanShengWangKeResults.indices, id: \.self) { i in
                                let tanShengResult = analysis.tanShengWangKeResults[i]
                                let keColors = WuXingColor.colors(for: tanShengResult.keWuXing)

                                HStack(spacing: 6) {
                                    // 贪生者五行标签
                                    Text(tanShengResult.keWuXing)
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(keColors.secondary)
                                        .clipShape(RoundedRectangle(cornerRadius: 4))

                                    Text(tanShengResult.description)
                                        .font(.system(size: 11, weight: .light))
                                        .foregroundColor(DesignSystem.textSecondary)
                                        .lineLimit(2)
                                }
                            }
                        }
                    }

                    // 刑冲破害
                    if !analysis.chongXingHaiResults.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("刑冲破害")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(DesignSystem.textSecondary)

                            ForEach(analysis.chongXingHaiResults.indices, id: \.self) { i in
                                let chongResult = analysis.chongXingHaiResults[i]
                                HStack(spacing: 6) {
                                    // 类型标签
                                    Text(chongResult.type)
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(WuXingColor.stoneColor)
                                        .clipShape(RoundedRectangle(cornerRadius: 4))

                                    // 参与元素
                                    Text(chongResult.elements.joined(separator: ""))
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundColor(DesignSystem.textPrimary)

                                    Spacer()

                                    // 位置
                                    Text(chongResult.positions.joined(separator: ""))
                                        .font(.system(size: 10, weight: .light))
                                        .foregroundColor(DesignSystem.textTertiary)
                                }
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
    }
}

// MARK: - 五行能量条

struct WuXingEnergyBar: View {
    let item: WuXingEnergyItem
    let dayMasterWuXing: String

    private var colors: (primary: Color, secondary: Color) {
        WuXingColor.colors(for: item.wuXing)
    }

    private var isDayMaster: Bool {
        item.wuXing == dayMasterWuXing
    }

    var body: some View {
        HStack(spacing: 10) {
            // 五行标签
            HStack(spacing: 4) {
                Text(item.wuXing)
                    .font(.system(size: 14, weight: isDayMaster ? .medium : .light))
                    .foregroundColor(colors.secondary)
                    .frame(width: 20)

                if isDayMaster {
                    Text("主")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(colors.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                }
            }
            .frame(width: 44, alignment: .leading)

            // 能量条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 背景条
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 8)

                    // 能量填充（限制最大宽度不超过容器）
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [colors.primary, colors.secondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: min(geometry.size.width, max(4, geometry.size.width * CGFloat(item.percentage / 100) * 2.5)), height: 8)
                }
            }
            .frame(height: 8)

            // 百分比和强度
            HStack(spacing: 4) {
                Text(String(format: "%.0f%%", item.percentage))
                    .font(.system(size: 11, weight: .light, design: .monospaced))
                    .foregroundColor(DesignSystem.textSecondary)
                    .frame(width: 32, alignment: .trailing)

                Text(item.strength)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(getStrengthColor(item.strength))
                    .frame(width: 28)
            }

            // 详细数量
            HStack(spacing: 2) {
                // 天干数量
                Text("\(item.tianGanCount)")
                    .font(.system(size: 9, weight: .light))
                    .foregroundColor(DesignSystem.textTertiary)
                Text("干")
                    .font(.system(size: 8, weight: .light))
                    .foregroundColor(DesignSystem.textTertiary.opacity(0.7))

                Text("\(item.diZhiCount)")
                    .font(.system(size: 9, weight: .light))
                    .foregroundColor(DesignSystem.textTertiary)
                Text("支")
                    .font(.system(size: 8, weight: .light))
                    .foregroundColor(DesignSystem.textTertiary.opacity(0.7))

                if item.cangGanCount > 0 {
                    Text("\(item.cangGanCount)")
                        .font(.system(size: 9, weight: .light))
                        .foregroundColor(DesignSystem.textTertiary)
                    Text("藏")
                        .font(.system(size: 8, weight: .light))
                        .foregroundColor(DesignSystem.textTertiary.opacity(0.7))
                }
            }
            .frame(width: 60, alignment: .trailing)
        }
    }

    private func getStrengthColor(_ strength: String) -> Color {
        switch strength {
        case "极旺": return WuXingColor.stoneColor
        case "偏旺": return DesignSystem.primaryOrange
        case "中和": return WuXingColor.grassColor
        case "偏弱": return WuXingColor.waveColor
        case "极弱": return DesignSystem.textTertiary
        default: return DesignSystem.textSecondary
        }
    }
}
