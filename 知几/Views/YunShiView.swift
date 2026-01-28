import SwiftUI

// MARK: - 运势子标签

enum YunShiTab: String, CaseIterable {
    case zhiYun = "知运"   // 大运 + 流年
    case zhiShi = "知时"   // 月运 + 周运
}

// MARK: - 运势视图

struct YunShiView: View {
    @Bindable var viewModel: ResultViewModel
    let onBack: () -> Void
    @State private var selectedSubTab: YunShiTab = .zhiYun

    var body: some View {
        ZStack(alignment: .top) {
            // 内容区域
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    // 顶部占位，为 header + tab 留出空间
                    Color.clear.frame(height: 100)
                    
                    switch selectedSubTab {
                    case .zhiYun:
                        zhiYunContent
                    case .zhiShi:
                        zhiShiContent
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100) // 为底部导航留空间
            }
            
            // 顶部整体区域（状态栏 + headerBar + tab 统一背景）
            VStack(spacing: 0) {
                // 顶部导航栏
                headerBar
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                
                // tab 导航
                subTabBar
                    .padding(.bottom, 8)
            }
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    // 毛玻璃材质，自然融合背景
                    Rectangle()
                        .fill(.ultraThinMaterial)
                    
                    // 渐变遮罩，让底部透明
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .clear, location: 0.7),
                            .init(color: .white, location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .blendMode(.destinationOut)
                }
                .compositingGroup()
                .padding(.bottom, -20)
                .ignoresSafeArea(edges: .top)
            )
        }
    }

    // MARK: - 顶部导航栏
    
    private var headerBar: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                    Text("重新排盘")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundColor(DesignSystem.textPrimary)
            }

            Spacer()

            AppLogo(size: 32)
        }
    }
    
    // MARK: - 二级标签栏

    private var subTabBar: some View {
        HStack(spacing: 4) {
            ForEach(YunShiTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedSubTab = tab
                    }
                }) {
                    Text(tab.rawValue)
                        .font(.system(size: 13, weight: selectedSubTab == tab ? .medium : .light))
                        .foregroundColor(selectedSubTab == tab ? DesignSystem.textPrimary : DesignSystem.textTertiary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(selectedSubTab == tab ? Color.gray.opacity(0.15) : Color.clear)
                        )
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.6), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
        .padding(.horizontal, 20)
    }

    // MARK: - 知运内容（大运 + 流年）

    private var zhiYunContent: some View {
        VStack(spacing: 16) {
            // 大运选择器
            DaYunView(
                daYunList: viewModel.daYunList,
                riGan: viewModel.bazi.day.gan,
                currentAge: viewModel.currentAge,
                birthYear: viewModel.birth.year,
                selectedIndex: $viewModel.selectedDaYunIndex
            )

            // 流年选择器（根据选中的大运显示对应10年）
            LiuNianView(
                riGan: viewModel.bazi.day.gan,
                birthYear: viewModel.birth.year,
                currentYear: Calendar.current.component(.year, from: Date()),
                daYunList: viewModel.daYunList,
                selectedDaYunIndex: viewModel.selectedDaYunIndex,
                selectedYear: $viewModel.selectedLiuNianYear
            )

            // 流年详情解析
            if let selectedYear = viewModel.selectedLiuNianYear {
                LiuNianAnalysisView(
                    year: selectedYear,
                    riGan: viewModel.bazi.day.gan,
                    bazi: viewModel.bazi,
                    birth: viewModel.birth,
                    gender: viewModel.gender
                )
            }

            // 当前大运概览（简化版）
            if let index = viewModel.selectedDaYunIndex, index < viewModel.daYunList.count {
                daYunSummaryCard(daYun: viewModel.daYunList[index], index: index)
            }
        }
    }

    /// 大运概览卡片（简化版，放在流年下方作为背景信息）
    private func daYunSummaryCard(daYun: DaYun, index: Int) -> some View {
        let ganWx = BaziConstants.wuXing[daYun.gan] ?? "木"
        let zhiWx = BaziConstants.wuXing[daYun.zhi] ?? "木"
        let ganColors = WuXingColor.colors(for: ganWx)
        let zhiColors = WuXingColor.colors(for: zhiWx)
        let ganShiShen = getShiShen(riGan: viewModel.bazi.day.gan, targetGan: daYun.gan)

        return GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                // 标题行
                HStack {
                    Text("大运背景")
                        .font(.system(size: 13, weight: .light))
                        .foregroundColor(DesignSystem.textSecondary)
                        .tracking(1)

                    Spacer()

                    // 干支标签
                    HStack(spacing: 4) {
                        Text(daYun.gan)
                            .foregroundColor(ganColors.secondary)
                        Text(daYun.zhi)
                            .foregroundColor(zhiColors.secondary)
                    }
                    .font(.system(size: 16, weight: .medium))

                    Text("·")
                        .foregroundColor(DesignSystem.textTertiary)

                    Text("\(daYun.age)-\(daYun.age + 9)岁")
                        .font(.system(size: 12, weight: .light))
                        .foregroundColor(DesignSystem.textTertiary)

                    if index == viewModel.currentDaYunIndex {
                        Text("当前")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(DesignSystem.primaryOrange)
                            .clipShape(Capsule())
                    }
                }

                // 运势特征（简短版）
                Text(getDaYunDescription(ganShiShen: ganShiShen))
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(DesignSystem.textSecondary)
                    .lineSpacing(3)
            }
            .padding(16)
        }
    }

    private func getDaYunDescription(ganShiShen: String) -> String {
        switch ganShiShen {
        case "比肩":
            return "此运期人际关系活跃，有合作发展机会。宜广结善缘，但需注意分清主次。"
        case "劫财":
            return "此运期竞争意识增强，财务上需谨慎。适合提升自我能力，不宜盲目投资。"
        case "食神":
            return "此运期思维活跃，创意丰富。适合学习新技能、发展兴趣爱好。"
        case "伤官":
            return "此运期表现欲强，才华易显。但需注意言行分寸，避免与人冲突。"
        case "偏财":
            return "此运期财运活跃，可能有意外收入。适合适度投资，但需控制风险。"
        case "正财":
            return "此运期正财运稳定，工作收入有保障。适合稳健理财，踏实积累。"
        case "七杀":
            return "此运期压力与机遇并存，需注意健康。宜积极面对挑战，化压力为动力。"
        case "正官":
            return "此运期贵人运佳，事业有上升机会。宜守规矩、重诚信。"
        case "偏印":
            return "此运期学习运佳，适合进修或研究。但需注意身体健康和情绪。"
        case "正印":
            return "此运期有长辈或贵人相助，学业事业皆顺。宜感恩回报。"
        default:
            return "此运期运势平稳，宜稳中求进，把握当下。"
        }
    }

    // MARK: - 知时内容（月运 + 周运）

    @State private var monthlyFortunes: [MonthlyFortune] = []
    @State private var selectedMonthIndex: Int?

    private var zhiShiContent: some View {
        VStack(spacing: 16) {
            // 月运选择器
            MonthlyFortuneSelector(
                fortunes: monthlyFortunes,
                riGan: viewModel.bazi.day.gan,
                selectedIndex: $selectedMonthIndex
            )

            // 月运详情
            if let index = selectedMonthIndex, index < monthlyFortunes.count {
                MonthlyFortuneDetailCard(fortune: monthlyFortunes[index])
            }

            // 周运（显示当前月份相关的周）
            WeeklyFortuneView(
                riGan: viewModel.bazi.day.gan,
                bazi: viewModel.bazi,
                selectedWeekIndex: $viewModel.selectedWeekIndex
            )
        }
        .onAppear {
            loadMonthlyFortunes()
        }
    }

    private func loadMonthlyFortunes() {
        monthlyFortunes = MonthlyFortuneCalculator.generateMonthlyFortunes(
            riGan: viewModel.bazi.day.gan,
            bazi: viewModel.bazi,
            monthsCount: 12
        )
        // 默认选中当前月
        if selectedMonthIndex == nil {
            selectedMonthIndex = monthlyFortunes.firstIndex { $0.isCurrentMonth } ?? 0
        }
    }
}

// MARK: - 月运选择器

struct MonthlyFortuneSelector: View {
    let fortunes: [MonthlyFortune]
    let riGan: String
    @Binding var selectedIndex: Int?

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("月运")
                    .font(.system(size: 15, weight: .light))
                    .foregroundColor(DesignSystem.textPrimary)
                    .tracking(2)

                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(fortunes.enumerated()), id: \.element.id) { index, fortune in
                                MonthlyFortuneItemView(
                                    fortune: fortune,
                                    isSelected: selectedIndex == index,
                                    onTap: { selectedIndex = index }
                                )
                                .id(index)
                            }
                        }
                        .padding(.vertical, 2)
                        .padding(.horizontal, 2)
                    }
                    .onAppear {
                        if let index = selectedIndex {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                proxy.scrollTo(index, anchor: .center)
                            }
                        }
                    }
                    .onChange(of: selectedIndex) { _, newIndex in
                        if let index = newIndex {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo(index, anchor: .center)
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
    }
}

// MARK: - 月运项视图

struct MonthlyFortuneItemView: View {
    let fortune: MonthlyFortune
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        let ganWx = BaziConstants.wuXing[fortune.gan] ?? "木"
        let zhiWx = BaziConstants.wuXing[fortune.zhi] ?? "木"
        let ganColors = WuXingColor.colors(for: ganWx)
        let zhiColors = WuXingColor.colors(for: zhiWx)

        VStack(spacing: 4) {
            VStack(spacing: 4) {
                // 月份
                Text("\(fortune.month)月")
                    .font(.system(size: 10, weight: isSelected ? .medium : .light))
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

                // 运势等级
                Text(fortune.fortuneLevel.rawValue)
                    .font(.system(size: 9, weight: .light))
                    .foregroundColor(Color(hex: fortune.fortuneLevel.color))
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

            // 当前月标记
            if fortune.isCurrentMonth && !isSelected {
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

// MARK: - 月运详情卡片

struct MonthlyFortuneDetailCard: View {
    let fortune: MonthlyFortune

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                // 标题行
                HStack {
                    Text("\(fortune.year)年\(fortune.month)月运势")
                        .font(.system(size: 15, weight: .light))
                        .foregroundColor(DesignSystem.textPrimary)
                        .tracking(2)

                    Spacer()

                    // 干支标签
                    HStack(spacing: 4) {
                        Text(fortune.gan)
                            .foregroundColor(WuXingColor.colors(for: BaziConstants.wuXing[fortune.gan] ?? "木").primary)
                        Text(fortune.zhi)
                            .foregroundColor(WuXingColor.colors(for: BaziConstants.wuXing[fortune.zhi] ?? "木").primary)
                    }
                    .font(.system(size: 16, weight: .medium))

                    if fortune.isCurrentMonth {
                        Text("本月")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(DesignSystem.primaryOrange)
                            .clipShape(Capsule())
                    }
                }

                // 运势概览
                HStack(alignment: .center, spacing: 16) {
                    // 运势分数环
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

                    // 十神信息
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

                    // 关键词
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

                Divider()

                // 建议
                VStack(alignment: .leading, spacing: 6) {
                    Text("本月建议")
                        .font(.system(size: 10, weight: .light))
                        .foregroundColor(DesignSystem.textTertiary)
                        .tracking(1)

                    Text(fortune.advice)
                        .font(.system(size: 13, weight: .light))
                        .foregroundColor(DesignSystem.textPrimary)
                        .lineSpacing(4)
                }
            }
            .padding(20)
        }
    }
}
