import SwiftUI

// MARK: - 柱子视图（极简风格）

struct PillarView: View {
    let title: String
    let gan: String
    let zhi: String
    let shiShen: String
    let zhiShiShen: String  // 地支十神（本气）
    let isDay: Bool
    var riGan: String = ""  // 日干，用于计算藏干十神
    var onTapExplanation: ((ExplanationType) -> Void)?  // 点击解释回调

    // 获取柱位名称
    private var pillarName: String {
        switch title {
        case "年": return "年柱"
        case "月": return "月柱"
        case "日": return "日柱"
        case "时": return "时柱"
        default: return title
        }
    }

    // 获取人生阶段标签（白话翻译）
    private var lifeStageLabel: String {
        switch title {
        case "年": return "童年·祖辈"
        case "月": return "成长·父母"
        case "日": return "自己·婚姻"
        case "时": return "晚年·子女"
        default: return ""
        }
    }

    var body: some View {
        let ganWx = BaziConstants.wuXing[gan] ?? "木"
        let zhiWx = BaziConstants.wuXing[zhi] ?? "木"
        let ganColors = WuXingColor.colors(for: ganWx)
        let zhiColors = WuXingColor.colors(for: zhiWx)
        let cangGanList = BaziConstants.cangGan[zhi] ?? []

        VStack(spacing: 8) {
            // 人生阶段标签（白话翻译）
            Text(lifeStageLabel)
                .font(.system(size: 9, weight: .light))
                .foregroundColor(DesignSystem.textTertiary.opacity(0.7))

            // 标题 - 细体
            Text(title)
                .font(.system(size: 12, weight: .light))
                .foregroundColor(DesignSystem.textTertiary)
                .tracking(1)

            // 天干十神标签（可点击）
            Text(isDay ? "日主" : shiShen)
                .font(.system(size: 10, weight: .light))
                .foregroundColor(isDay ? DesignSystem.primaryOrange : DesignSystem.textTertiary)
                .frame(height: 14)
                .onTapGesture {
                    if !isDay {
                        onTapExplanation?(.shiShen(shiShen))
                    }
                }

            // 天干 - 细体优雅风格（五行在底部）（可点击）
            VStack(spacing: 4) {
                Text(gan)
                    .font(.system(size: 34, weight: .light))
                    .foregroundColor(ganColors.secondary)
                Text(ganWx)
                    .font(.system(size: 10, weight: .light))
                    .foregroundColor(ganColors.primary)
            }
            .frame(width: 62, height: 62)
            .background(Color(hex: "FAFAFA"))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .onTapGesture {
                onTapExplanation?(.tianGan(gan, pillar: pillarName, shiShen: isDay ? nil : shiShen))
            }

            // 地支 - 细体优雅风格（五行在底部）（可点击）
            VStack(spacing: 4) {
                Text(zhi)
                    .font(.system(size: 34, weight: .light))
                    .foregroundColor(zhiColors.secondary)
                Text(zhiWx)
                    .font(.system(size: 10, weight: .light))
                    .foregroundColor(zhiColors.primary)
            }
            .frame(width: 62, height: 62)
            .background(Color(hex: "FAFAFA"))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .onTapGesture {
                // 获取地支所有藏干的十神信息
                let cangGanInfoList: [CangGanInfo] = {
                    guard !riGan.isEmpty,
                          let cangGanList = BaziConstants.cangGan[zhi] else { return [] }
                    let types = ["本气", "中气", "余气"]
                    return cangGanList.enumerated().compactMap { index, gan in
                        let shiShen = getShiShen(riGan: riGan, targetGan: gan)
                        return CangGanInfo(gan: gan, shiShen: shiShen, type: types[min(index, 2)])
                    }
                }()
                onTapExplanation?(.diZhi(zhi, pillar: pillarName, cangGanList: cangGanInfoList))
            }

            // 藏干及其十神（固定高度，居中对齐）
            VStack(spacing: 2) {
                ForEach(0..<3, id: \.self) { index in
                    if index < cangGanList.count {
                        let cg = cangGanList[index]
                        let cgWx = BaziConstants.wuXing[cg] ?? "木"
                        let cgColors = WuXingColor.colors(for: cgWx)
                        let cgShiShen = riGan.isEmpty ? "" : getShiShen(riGan: riGan, targetGan: cg)

                        HStack(spacing: 3) {
                            Text(cg)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(cgColors.secondary)
                                .frame(width: 14, height: 14)
                                .background(Color(hex: "F0F0F0"))
                                .clipShape(RoundedRectangle(cornerRadius: 3))

                            Text(cgShiShen)
                                .font(.system(size: 9, weight: .light))
                                .foregroundColor(index == 0 ? DesignSystem.textSecondary : DesignSystem.textTertiary)
                        }
                        .frame(height: 16)
                        .onTapGesture {
                            onTapExplanation?(.cangGan(cg, pillar: pillarName, shiShen: cgShiShen.isEmpty ? nil : cgShiShen))
                        }
                    } else {
                        // 占位，保持高度一致
                        Color.clear.frame(height: 16)
                    }
                }
            }
            .frame(width: 62, height: 54)
        }
    }
}
