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

    var body: some View {
        let ganWx = BaziConstants.wuXing[gan] ?? "木"
        let zhiWx = BaziConstants.wuXing[zhi] ?? "木"
        let ganColors = WuXingColor.colors(for: ganWx)
        let zhiColors = WuXingColor.colors(for: zhiWx)
        let cangGanList = BaziConstants.cangGan[zhi] ?? []

        VStack(spacing: 8) {
            // 标题 - 细体
            Text(title)
                .font(.system(size: 12, weight: .light))
                .foregroundColor(DesignSystem.textTertiary)
                .tracking(1)

            // 天干十神标签
            Text(isDay ? "日主" : shiShen)
                .font(.system(size: 10, weight: .light))
                .foregroundColor(isDay ? DesignSystem.primaryOrange : DesignSystem.textTertiary)
                .frame(height: 14)

            // 天干 - 细体优雅风格（五行在底部）
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

            // 地支 - 细体优雅风格（五行在底部）
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
