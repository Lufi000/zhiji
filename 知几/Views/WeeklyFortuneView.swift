import SwiftUI

// MARK: - 周运势视图

struct WeeklyFortuneView: View {
    let riGan: String
    let bazi: Bazi
    @Binding var selectedWeekIndex: Int?
    @State private var fortunes: [WeeklyFortune] = []

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                // 标题栏
                Text("周运势")
                    .font(.system(size: 15, weight: .light))
                    .foregroundColor(DesignSystem.textPrimary)
                    .tracking(2)

                // 周运势列表
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(fortunes.enumerated()), id: \.element.id) { index, fortune in
                                WeeklyFortuneItemView(
                                    fortune: fortune,
                                    riGan: riGan,
                                    isSelected: selectedWeekIndex == index,
                                    onTap: { selectedWeekIndex = index }
                                )
                                .id(index)
                            }
                        }
                        .padding(.vertical, 2)
                        .padding(.horizontal, 2)
                    }
                    .onAppear {
                        // 初始化时滚动到当前周
                        if let currentIndex = fortunes.firstIndex(where: { $0.isCurrentWeek }) {
                            selectedWeekIndex = currentIndex
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                proxy.scrollTo(currentIndex, anchor: .center)
                            }
                        }
                    }
                    .onChange(of: selectedWeekIndex) { _, newIndex in
                        if let index = newIndex {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo(index, anchor: .center)
                            }
                        }
                    }
                }

                // 选中周的详情卡片
                if let index = selectedWeekIndex, index < fortunes.count {
                    WeeklyFortuneDetailView(fortune: fortunes[index])
                }
            }
            .padding(20)
        }
        .onAppear {
            loadFortunes()
        }
    }

    private func loadFortunes() {
        fortunes = WeeklyFortuneCalculator.generateWeeklyFortunes(
            riGan: riGan,
            bazi: bazi,
            weeksCount: 12
        )
    }
}

// MARK: - 周运势项视图

struct WeeklyFortuneItemView: View {
    let fortune: WeeklyFortune
    let riGan: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        let ganWx = BaziConstants.wuXing[fortune.gan] ?? "木"
        let zhiWx = BaziConstants.wuXing[fortune.zhi] ?? "木"
        let ganColors = WuXingColor.colors(for: ganWx)
        let zhiColors = WuXingColor.colors(for: zhiWx)

        VStack(spacing: 4) {
            VStack(spacing: 4) {
                // 日期范围
                Text(fortune.dateRangeString)
                    .font(.system(size: 9, weight: isSelected ? .medium : .light))
                    .foregroundColor(isSelected ? DesignSystem.primaryOrange : DesignSystem.textTertiary)

                // 运势等级图标
                Image(systemName: fortune.fortuneLevel.icon)
                    .font(.system(size: 10))
                    .foregroundColor(Color(hex: fortune.fortuneLevel.color))

                // 天干
                VStack(spacing: 1) {
                    Text(fortune.gan)
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(ganColors.secondary)
                    Text(ganWx)
                        .font(.system(size: 9, weight: .light))
                        .foregroundColor(ganColors.secondary.opacity(0.6))
                }

                // 地支
                VStack(spacing: 1) {
                    Text(fortune.zhi)
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(zhiColors.secondary)
                    Text(zhiWx)
                        .font(.system(size: 9, weight: .light))
                        .foregroundColor(zhiColors.secondary.opacity(0.6))
                }

                // 运势等级文字
                Text(fortune.fortuneLevel.rawValue)
                    .font(.system(size: 9, weight: .light))
                    .foregroundColor(Color(hex: fortune.fortuneLevel.color))

                // 周数
                Text(fortune.weekTitle)
                    .font(.system(size: 8, weight: .light))
                    .foregroundColor(DesignSystem.textTertiary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color(hex: "FFF5EE") : Color(hex: "FAFAFA"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? DesignSystem.primaryOrange : Color.clear, lineWidth: isSelected ? 1.5 : 0)
            )

            // 当前周标记
            if fortune.isCurrentWeek && !isSelected {
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

// MARK: - 周运势详情视图

struct WeeklyFortuneDetailView: View {
    let fortune: WeeklyFortune

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 分隔线
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 0.5)

            // 运势概览
            HStack(alignment: .center, spacing: 16) {
                // 左侧：运势分数环
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                        .frame(width: 50, height: 50)

                    Circle()
                        .trim(from: 0, to: CGFloat(fortune.fortuneScore) / 100)
                        .stroke(
                            Color(hex: fortune.fortuneLevel.color),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(-90))

                    Text("\(fortune.fortuneScore)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: fortune.fortuneLevel.color))
                }

                // 中间：十神信息
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("天干")
                            .font(.system(size: 10, weight: .light))
                            .foregroundColor(DesignSystem.textTertiary)
                        Text("\(fortune.gan) · \(fortune.ganShiShen)")
                            .font(.system(size: 12, weight: .light))
                            .foregroundColor(DesignSystem.textPrimary)
                    }
                    HStack(spacing: 8) {
                        Text("地支")
                            .font(.system(size: 10, weight: .light))
                            .foregroundColor(DesignSystem.textTertiary)
                        Text("\(fortune.zhi) · \(fortune.zhiShiShen)")
                            .font(.system(size: 12, weight: .light))
                            .foregroundColor(DesignSystem.textPrimary)
                    }
                }

                Spacer()

                // 右侧：关键词
                VStack(alignment: .trailing, spacing: 4) {
                    ForEach(fortune.keywords, id: \.self) { keyword in
                        Text(keyword)
                            .font(.system(size: 10, weight: .light))
                            .foregroundColor(DesignSystem.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(Color(hex: fortune.fortuneLevel.color).opacity(0.1))
                            )
                    }
                }
            }

            // 建议
            VStack(alignment: .leading, spacing: 6) {
                Text("本周建议")
                    .font(.system(size: 10, weight: .light))
                    .foregroundColor(DesignSystem.textTertiary)
                    .tracking(1)

                Text(fortune.advice)
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(DesignSystem.textPrimary)
                    .lineSpacing(4)
            }
        }
    }
}
