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
    let onTap: () -> Void

    var body: some View {
        let ganWx = BaziConstants.wuXing[gan] ?? "木"
        let zhiWx = BaziConstants.wuXing[zhi] ?? "木"
        let ganColors = WuXingColor.colors(for: ganWx)
        let zhiColors = WuXingColor.colors(for: zhiWx)

        VStack(spacing: 4) {
            VStack(spacing: 4) {
                // 顶部标签
                Text(topLabel)
                    .font(.system(size: 9, weight: isSelected ? .medium : .light))
                    .foregroundColor(isSelected ? DesignSystem.primaryOrange : DesignSystem.textTertiary)

                // 天干十神
                Text(ganShiShen)
                    .font(.system(size: 9, weight: .light))
                    .foregroundColor(DesignSystem.textTertiary)

                // 天干 + 五行（五行在底部）
                VStack(spacing: 1) {
                    Text(gan)
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(ganColors.secondary)
                    Text(ganWx)
                        .font(.system(size: 9, weight: .light))
                        .foregroundColor(ganColors.secondary.opacity(0.6))
                }

                // 地支 + 五行（五行在底部）
                VStack(spacing: 1) {
                    Text(zhi)
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(zhiColors.secondary)
                    Text(zhiWx)
                        .font(.system(size: 9, weight: .light))
                        .foregroundColor(zhiColors.secondary.opacity(0.6))
                }

                // 地支十神
                Text(zhiShiShen)
                    .font(.system(size: 9, weight: .light))
                    .foregroundColor(DesignSystem.textTertiary)

                // 底部标签
                Text(bottomLabel)
                    .font(.system(size: 8, weight: .light))
                    .foregroundColor(DesignSystem.textTertiary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color(hex: "FFF5EE") : Color(hex: "FAFAFA"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? DesignSystem.primaryOrange : Color.clear, lineWidth: isSelected ? 1.5 : 0)
            )

            // 当前标记（小点）
            if isCurrent && !isSelected {
                Circle()
                    .fill(DesignSystem.primaryOrange)
                    .frame(width: 5, height: 5)
            } else {
                Color.clear.frame(width: 5, height: 5)
            }
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                onTap()
            }
        }
    }
}
