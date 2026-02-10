import SwiftUI

// MARK: - 干支项视图（大运/流年共用）

struct GanZhiItemView: View {
    let topLabel: String        // 顶部标签（年份或"xx年"）
    let gan: String             // 天干
    let zhi: String             // 地支
    let ganShiShen: String      // 天干十神
    let zhiShiShen: String      // 地支十神
    let bottomLabel: String     // 底部标签（"xx岁"）
    let isSelected: Bool
    let isCurrent: Bool
    /// true 时左右内边距为 0，与 HStack(spacing: 0) 配合使项紧贴
    var tightHorizontal: Bool = false
    let onTap: () -> Void

    var body: some View {
        let ganWx = BaziConstants.wuXing[gan] ?? "木"
        let zhiWx = BaziConstants.wuXing[zhi] ?? "木"
        let ganColors = WuXingColor.colors(for: ganWx)
        let zhiColors = WuXingColor.colors(for: zhiWx)

        VStack(spacing: 2) {
            VStack(spacing: 2) {
                // 顶部标签
                Text(topLabel)
                    .font(.system(size: 8, weight: isSelected ? .medium : .light))
                    .foregroundColor(isSelected ? DesignSystem.primaryOrange : DesignSystem.textTertiary)

                // 天干十神
                Text(ganShiShen)
                    .font(.system(size: 8, weight: .light))
                    .foregroundColor(DesignSystem.textTertiary)

                // 天干 + 五行（五行在底部）
                VStack(spacing: 0) {
                    Text(gan)
                        .font(.system(size: 15, weight: .light))
                        .foregroundColor(ganColors.secondary)
                    Text(ganWx)
                        .font(.system(size: 8, weight: .light))
                        .foregroundColor(ganColors.secondary.opacity(0.6))
                }

                // 地支 + 五行（五行在底部）
                VStack(spacing: 0) {
                    Text(zhi)
                        .font(.system(size: 15, weight: .light))
                        .foregroundColor(zhiColors.secondary)
                    Text(zhiWx)
                        .font(.system(size: 8, weight: .light))
                        .foregroundColor(zhiColors.secondary.opacity(0.6))
                }

                // 地支十神
                Text(zhiShiShen)
                    .font(.system(size: 8, weight: .light))
                    .foregroundColor(DesignSystem.textTertiary)

                // 底部标签
                Text(bottomLabel)
                    .font(.system(size: 7, weight: .light))
                    .foregroundColor(DesignSystem.textTertiary)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, tightHorizontal ? 0 : 4)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color(hex: "FFF5EE") : Color(hex: "FAFAFA"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 9.4)
                    .stroke(isSelected ? DesignSystem.primaryOrange : Color.clear, lineWidth: isSelected ? 1.2 : 0)
            )

            // 当前标记（小点）
            if isCurrent && !isSelected {
                Circle()
                    .fill(DesignSystem.primaryOrange)
                    .frame(width: 4, height: 4)
            } else {
                Color.clear.frame(width: 4, height: 4)
            }
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                onTap()
            }
        }
    }
}
