import SwiftUI

// MARK: - 滚动位置偏好键

struct SectionOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: [MingPanSection: CGFloat] = [:]
    
    static func reduce(value: inout [MingPanSection: CGFloat], nextValue: () -> [MingPanSection: CGFloat]) {
        value.merge(nextValue()) { $1 }
    }
}

// MARK: - 命盘区块枚举

enum MingPanSection: String, CaseIterable {
    case core = "核心解读"
    case guide = "生活指南"
    case detail = "专业详解"
    
    var icon: String {
        switch self {
        case .core: return "sparkles"
        case .guide: return "compass.drawing"
        case .detail: return "chart.bar.doc.horizontal"
        }
    }
    
    var subtitle: String {
        switch self {
        case .core: return "一眼看懂你是谁、适合什么"
        case .guide: return "把命理转化为实用建议"
        case .detail: return "深入了解命盘的底层逻辑"
        }
    }
    
    var scrollId: String {
        switch self {
        case .core: return "section_core"
        case .guide: return "section_guide"
        case .detail: return "section_detail"
        }
    }
}

// MARK: - 命盘视图

struct MingPanView: View {
    @Bindable var viewModel: ResultViewModel
    let onBack: () -> Void
    
    // MARK: - 导航状态
    @State private var activeSection: MingPanSection = .core
    @State private var isDetailExpanded: Bool = true
    @State private var isScrollingByTap: Bool = false  // 防止点击跳转时滚动联动干扰
    @State private var scrollProxy: ScrollViewProxy?   // 保存 proxy 引用

    var body: some View {
        ScrollViewReader { proxy in
            ZStack(alignment: .top) {
                // 内容区域（可滚动到 tab 下方）
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        // 顶部占位，为 header + tab 留出初始空间
                        Color.clear.frame(height: 100)
                        
                        // MARK: - 第一层：核心解读
                        VStack(spacing: 16) {
                            sectionHeader(for: .core)
                            dayMasterCard
                            
                            // 四柱
                            fourPillarsCard
                            
                            LifeThemesView(bazi: viewModel.bazi, gender: viewModel.gender)
                        }
                        .id("section_core")
                        
                        // MARK: - 第二层：生活指南
                        VStack(spacing: 16) {
                            sectionHeader(for: .guide)
                            yongShenCard
                            healthCard
                            luckyNumberCard
                            homeEnvironmentCard
                        }
                        .id("section_guide")
                        
                        // MARK: - 第三层：专业详解（可折叠）
                        VStack(spacing: 16) {
                            detailSectionHeader
                            
                            if isDetailExpanded {
                                // 五行能量
                                WuXingEnergyView(bazi: viewModel.bazi)
                                
                                // 十神分布
                                ShiShenView(bazi: viewModel.bazi)
                            }
                        }
                        .id("section_detail")
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
                .onPreferenceChange(SectionOffsetPreferenceKey.self) { offsets in
                    updateActiveSection(from: offsets)
                }
                
                // 顶部整体区域（状态栏 + headerBar + tab 统一背景）
                VStack(spacing: 0) {
                    // 顶部导航栏
                    headerBar
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 8)
                    
                    // tab 导航
                    sectionNavigator(proxy: proxy)
                        .padding(.horizontal, 20)
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
            .onAppear {
                scrollProxy = proxy
            }
        }
    }
    
    // MARK: - 更新当前活跃区块
    
    private func updateActiveSection(from offsets: [MingPanSection: CGFloat]) {
        // 如果是点击触发的滚动，不更新
        guard !isScrollingByTap else { return }
        
        // 使用全局坐标
        // 当标题滚动到导航栏底部附近时（约 y=160），切换 tab
        // 选择已滚动到阈值以上、且 y 值最大的标题（即刚滚过去的）
        let threshold: CGFloat = 160
        
        var newSection: MingPanSection = .core
        var maxOffset: CGFloat = -.infinity
        
        for section in MingPanSection.allCases {
            if let offset = offsets[section] {
                if offset <= threshold && offset > maxOffset {
                    maxOffset = offset
                    newSection = section
                }
            }
        }
        
        if activeSection != newSection {
            withAnimation(.easeInOut(duration: 0.2)) {
                activeSection = newSection
            }
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
    
    // MARK: - 导航栏（与底部tab一致的设计语言）
    
    private func sectionNavigator(proxy: ScrollViewProxy) -> some View {
        HStack(spacing: 4) {
            ForEach(MingPanSection.allCases, id: \.self) { section in
                sectionTabButton(for: section, proxy: proxy)
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
        .shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: 4)
    }
    
    private func sectionTabButton(for section: MingPanSection, proxy: ScrollViewProxy) -> some View {
        let isSelected = activeSection == section
        
        return Button(action: {
            // 标记为点击触发的滚动，防止滚动联动干扰
            isScrollingByTap = true
            
            // 如果是专业详解且未展开，先展开
            if section == .detail && !isDetailExpanded {
                isDetailExpanded = true
            }
            
            // 更新选中状态
            withAnimation(.easeInOut(duration: 0.2)) {
                activeSection = section
            }
            
            // 延迟执行滚动，确保展开动画完成
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    proxy.scrollTo(section.scrollId, anchor: .top)
                }
                
                // 滚动完成后恢复滚动联动
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isScrollingByTap = false
                }
            }
        }) {
            HStack(spacing: 4) {
                Image(systemName: section.icon)
                    .font(.system(size: 12, weight: isSelected ? .medium : .light))
                
                Text(section.rawValue)
                    .font(.system(size: 11, weight: isSelected ? .medium : .light))
            }
            .foregroundColor(isSelected ? DesignSystem.textPrimary : DesignSystem.textTertiary)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? Color.gray.opacity(0.15) : Color.clear)
            )
        }
    }
    
    // MARK: - 区块标题（带位置检测）
    
    private func sectionHeader(for section: MingPanSection) -> some View {
        HStack(spacing: 8) {
            Image(systemName: section.icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(DesignSystem.primaryOrange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(section.rawValue)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(DesignSystem.textPrimary)
                
                Text(section.subtitle)
                    .font(.system(size: 11, weight: .light))
                    .foregroundColor(DesignSystem.textTertiary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
        .overlay(alignment: .top) {
            GeometryReader { geometry in
                Color.clear
                    .preference(
                        key: SectionOffsetPreferenceKey.self,
                        value: [section: geometry.frame(in: .global).minY]
                    )
            }
            .frame(height: 1)
        }
    }
    
    // MARK: - 专业详解标题（带折叠按钮和位置检测）
    
    private var detailSectionHeader: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                isDetailExpanded.toggle()
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: MingPanSection.detail.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(DesignSystem.primaryOrange)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(MingPanSection.detail.rawValue)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(DesignSystem.textPrimary)
                    
                    Text(MingPanSection.detail.subtitle)
                        .font(.system(size: 11, weight: .light))
                        .foregroundColor(DesignSystem.textTertiary)
                }
                
                Spacer()
                
                // 折叠指示器
                HStack(spacing: 4) {
                    Text(isDetailExpanded ? "收起" : "展开")
                        .font(.system(size: 11, weight: .light))
                        .foregroundColor(DesignSystem.textTertiary)
                    
                    Image(systemName: isDetailExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(DesignSystem.textTertiary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.gray.opacity(0.08))
                .clipShape(Capsule())
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .overlay(alignment: .top) {
            GeometryReader { geometry in
                Color.clear
                    .preference(
                        key: SectionOffsetPreferenceKey.self,
                        value: [.detail: geometry.frame(in: .global).minY]
                    )
            }
            .frame(height: 1)
        }
    }

    // MARK: - 四柱卡片
    
    private var fourPillarsCard: some View {
        GlassCard {
            HStack(spacing: 0) {
                ForEach(Array(zip(["年", "月", "日", "时"], [viewModel.bazi.year, viewModel.bazi.month, viewModel.bazi.day, viewModel.bazi.hour]).enumerated()), id: \.0) { i, item in
                    PillarView(
                        title: item.0,
                        gan: item.1.gan,
                        zhi: item.1.zhi,
                        shiShen: viewModel.getGanShiShen(position: item.0, gan: item.1.gan),
                        zhiShiShen: viewModel.getZhiShiShenDisplay(item.1.zhi),
                        isDay: i == 2,
                        riGan: viewModel.bazi.day.gan,
                        onTapExplanation: { explanationType in
                            viewModel.selectedExplanationType = explanationType
                        }
                    )
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 16)
        }
    }

    // MARK: - 日主卡片

    private var dayMasterCard: some View {
        let dayGan = viewModel.bazi.day.gan
        let dayWx = BaziConstants.wuXing[dayGan] ?? "木"
        let colors = WuXingColor.colors(for: dayWx)
        let ganExplanation = BaziExplanations.getGanExplanation(dayGan)

        return VStack(spacing: 12) {
            // 生日日期时间
            HStack {
                Text("\(viewModel.birth.year)年\(viewModel.birth.month)月\(viewModel.birth.day)日 \(viewModel.birth.hour)时")
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(.white.opacity(0.7))
                Spacer()

                Button(action: { viewModel.copyFullBaziInfo() }) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                }
            }

            HStack(spacing: 8) {
                Text("日主")
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(.white.opacity(0.8))

                HStack(spacing: 4) {
                    Text(dayGan)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.white)
                    Text(dayWx)
                        .font(.system(size: 22, weight: .light))
                        .foregroundColor(.white.opacity(0.9))
                }

                Text("·")
                    .foregroundColor(.white.opacity(0.6))

                // 身强身弱标签
                Button(action: {
                    viewModel.toggleStrengthPicker()
                }) {
                    HStack(spacing: 4) {
                        Text(viewModel.effectiveStrength)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)

                        if viewModel.customStrength == nil {
                            Text("(\(viewModel.strengthResult.score))")
                                .font(.system(size: 12, weight: .light))
                                .foregroundColor(.white.opacity(0.7))
                        } else {
                            Text("(自定义)")
                                .font(.system(size: 12, weight: .light))
                                .foregroundColor(.white.opacity(0.7))
                        }

                        Image(systemName: viewModel.showStrengthPicker ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.15))
                    )
                }

                // 科普按钮
                Button(action: {
                    viewModel.selectedExplanationType = .strength(viewModel.effectiveStrength)
                }) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()
            }

            // 人话描述：你是什么样的人
            if let explanation = ganExplanation {
                VStack(alignment: .leading, spacing: 8) {
                    // 简短比喻
                    Text(getDayMasterMetaphor(dayGan))
                        .font(.system(size: 13, weight: .light))
                        .foregroundColor(.white.opacity(0.9))

                    // 核心关键词
                    HStack(spacing: 6) {
                        ForEach(explanation.keywords.prefix(4), id: \.self) { keyword in
                            Text(keyword)
                                .font(.system(size: 11, weight: .light))
                                .foregroundColor(.white.opacity(0.85))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)
            }

            // 身强身弱选择器（包含计算详情）
            if viewModel.showStrengthPicker {
                strengthPickerView
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(
            LinearGradient(
                colors: [colors.secondary, colors.primary.opacity(0.8)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cornerRadiusLarge))
        .shadow(color: colors.secondary.opacity(0.3), radius: 16, x: 0, y: 8)
    }

    private var strengthPickerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
                .background(Color.white.opacity(0.3))

            HStack(spacing: 6) {
                ForEach(ResultViewModel.strengthOptions, id: \.self) { option in
                    let isSystemValue = option == viewModel.strengthResult.strength
                    Button(action: {
                        viewModel.selectStrength(option)
                    }) {
                        VStack(spacing: 2) {
                            Text(option)
                                .font(.system(size: 11, weight: viewModel.effectiveStrength == option ? .medium : .light))
                                .foregroundColor(viewModel.effectiveStrength == option ? .white : .white.opacity(0.6))

                            if isSystemValue {
                                Text("推荐")
                                    .font(.system(size: 8, weight: .light))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, isSystemValue ? 4 : 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(viewModel.effectiveStrength == option ? Color.white.opacity(0.25) : Color.white.opacity(0.1))
                        )
                    }
                }
            }

            // 计算详情
            VStack(alignment: .leading, spacing: 6) {
                Divider()
                    .background(Color.white.opacity(0.2))
                    .padding(.top, 4)

                Text("计算详情：")
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(.white.opacity(0.8))

                Text(viewModel.strengthResult.details)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(maxWidth: .infinity, alignment: .leading)

                // 极强/极弱时显示从格提示
                if viewModel.strengthResult.strength == "极强" || viewModel.strengthResult.strength == "极弱" {
                    Text("此命局可能为从格，如需精确判断建议结合人工分析")
                        .font(.system(size: 11, weight: .light))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.top, 4)
        }
    }

    // MARK: - 喜忌卡片

    private var yongShenCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                // 标题行：喜忌 + 调候（如有）
                HStack(alignment: .center) {
                    Text("喜忌")
                        .font(.system(size: 15, weight: .light))
                        .foregroundColor(DesignSystem.textPrimary)
                        .tracking(2)

                    Spacer()

                    // 调候标签（如有）
                    if let tiaoHou = viewModel.tiaoHouResult.tiaoHou,
                       let reason = viewModel.tiaoHouResult.reason {
                        HStack(spacing: 6) {
                            Text("调候")
                                .font(.system(size: 11, weight: .light))
                                .foregroundColor(DesignSystem.textTertiary)
                            wuXingCircle(wx: tiaoHou, isFilled: true, size: 24)
                            Text(reason)
                                .font(.system(size: 10, weight: .light))
                                .foregroundColor(DesignSystem.textTertiary)
                        }
                    }
                }

                // 喜忌五行
                HStack(spacing: 0) {
                    // 喜神
                    VStack(alignment: .leading, spacing: 8) {
                        Text("喜")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(DesignSystem.textSecondary)

                        HStack(spacing: 6) {
                            ForEach(viewModel.xiYongShenResult.xi, id: \.self) { wx in
                                wuXingCircle(wx: wx, isFilled: true)
                            }
                        }
                    }

                    Spacer()

                    Divider()
                        .frame(height: 50)

                    Spacer()

                    // 忌神
                    VStack(alignment: .leading, spacing: 8) {
                        Text("忌")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(DesignSystem.textSecondary)

                        HStack(spacing: 6) {
                            ForEach(viewModel.xiYongShenResult.ji, id: \.self) { wx in
                                wuXingCircle(wx: wx, isFilled: false)
                            }
                        }
                    }

                    Spacer()
                }

                // 人话解读：实际生活建议
                xiJiAdviceSection
            }
            .padding(20)
        }
    }

    // MARK: - 喜忌人话解读

    private var xiJiAdviceSection: some View {
        let xiList = viewModel.xiYongShenResult.xi

        return VStack(alignment: .leading, spacing: 12) {
            Divider()
                .background(Color.gray.opacity(0.2))

            // 方位建议
            adviceRow(
                icon: "🧭",
                title: "有利方位",
                content: xiList.map { getDirection($0) }.joined(separator: "、")
            )

            // 颜色建议
            adviceRow(
                icon: "🎨",
                title: "幸运颜色",
                content: xiList.map { getColor($0) }.joined(separator: "、")
            )

            // 行业建议
            adviceRow(
                icon: "💼",
                title: "适合行业",
                content: xiList.flatMap { getIndustries($0) }.prefix(4).joined(separator: "、")
            )
        }
    }

    // MARK: - 健康养生卡片

    private var healthCard: some View {
        let xiList = viewModel.xiYongShenResult.xi
        let jiList = viewModel.xiYongShenResult.ji

        return GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("健康养生")
                    .font(.system(size: 15, weight: .light))
                    .foregroundColor(DesignSystem.textPrimary)
                    .tracking(2)

                VStack(alignment: .leading, spacing: 12) {
                    // 饮食宜
                    adviceRow(
                        icon: "🥗",
                        title: "饮食宜",
                        content: xiList.flatMap { getFoodBenefit($0) }.prefix(4).joined(separator: "、")
                    )

                    // 饮食忌
                    adviceRow(
                        icon: "🚫",
                        title: "饮食忌",
                        content: jiList.flatMap { getFoodAvoid($0) }.prefix(3).joined(separator: "、")
                    )

                    // 运动建议
                    adviceRow(
                        icon: "🏃",
                        title: "运动建议",
                        content: xiList.flatMap { getExercise($0) }.prefix(3).joined(separator: "、")
                    )

                    // 易发问题
                    adviceRow(
                        icon: "⚠️",
                        title: "注意部位",
                        content: jiList.map { getHealthConcern($0) }.joined(separator: "、")
                    )
                }
            }
            .padding(20)
        }
    }

    // MARK: - 幸运数字时辰卡片

    private var luckyNumberCard: some View {
        let xiList = viewModel.xiYongShenResult.xi

        return GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("数字与时辰")
                    .font(.system(size: 15, weight: .light))
                    .foregroundColor(DesignSystem.textPrimary)
                    .tracking(2)

                VStack(alignment: .leading, spacing: 12) {
                    // 幸运数字
                    adviceRow(
                        icon: "🔢",
                        title: "幸运数字",
                        content: xiList.flatMap { getLuckyNumbers($0) }.map { String($0) }.joined(separator: "、")
                    )

                    // 有利时辰
                    adviceRow(
                        icon: "🕐",
                        title: "有利时辰",
                        content: xiList.map { getLuckyHours($0) }.joined(separator: "、")
                    )

                    // 有利季节
                    adviceRow(
                        icon: "🍃",
                        title: "有利季节",
                        content: xiList.map { getLuckySeason($0) }.joined(separator: "、")
                    )
                }
            }
            .padding(20)
        }
    }

    // MARK: - 居家环境卡片

    private var homeEnvironmentCard: some View {
        let xiList = viewModel.xiYongShenResult.xi

        return GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("居家环境")
                    .font(.system(size: 15, weight: .light))
                    .foregroundColor(DesignSystem.textPrimary)
                    .tracking(2)

                VStack(alignment: .leading, spacing: 12) {
                    // 装饰材质
                    adviceRow(
                        icon: "🏠",
                        title: "适宜材质",
                        content: xiList.flatMap { getMaterials($0) }.prefix(4).joined(separator: "、")
                    )

                    // 适合植物
                    adviceRow(
                        icon: "🌿",
                        title: "适合植物",
                        content: xiList.flatMap { getPlants($0) }.prefix(3).joined(separator: "、")
                    )

                    // 饰品建议
                    adviceRow(
                        icon: "💎",
                        title: "饰品材质",
                        content: xiList.flatMap { getAccessories($0) }.prefix(3).joined(separator: "、")
                    )
                }
            }
            .padding(20)
        }
    }


    private func adviceRow(icon: String, title: String, content: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(icon)
                .font(.system(size: 12))

            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(DesignSystem.textSecondary)
                .frame(width: 56, alignment: .leading)

            Text(content)
                .font(.system(size: 12, weight: .light))
                .foregroundColor(DesignSystem.textPrimary)
                .lineLimit(2)

            Spacer()
        }
    }

    // MARK: - 五行对应的生活建议

    private func getDirection(_ wuXing: String) -> String {
        switch wuXing {
        case "木": return "东方"
        case "火": return "南方"
        case "土": return "本地/中部"
        case "金": return "西方"
        case "水": return "北方"
        default: return ""
        }
    }

    private func getColor(_ wuXing: String) -> String {
        switch wuXing {
        case "木": return "绿色、青色"
        case "火": return "红色、紫色"
        case "土": return "黄色、棕色"
        case "金": return "白色、金色"
        case "水": return "黑色、蓝色"
        default: return ""
        }
    }

    private func getIndustries(_ wuXing: String) -> [String] {
        switch wuXing {
        case "木": return ["教育", "出版", "医疗", "环保"]
        case "火": return ["互联网", "餐饮", "能源", "娱乐"]
        case "土": return ["房地产", "建筑", "农业", "矿业"]
        case "金": return ["金融", "机械", "汽车", "法律"]
        case "水": return ["物流", "旅游", "贸易", "传媒"]
        default: return []
        }
    }

    private func getPartnerTrait(_ wuXing: String) -> String {
        switch wuXing {
        case "木": return "高个、温和"
        case "火": return "热情、开朗"
        case "土": return "稳重、厚道"
        case "金": return "果断、干练"
        case "水": return "聪明、灵活"
        default: return ""
        }
    }

    // MARK: - 健康养生数据

    private func getFoodBenefit(_ wuXing: String) -> [String] {
        switch wuXing {
        case "木": return ["绿色蔬菜", "酸味食物", "柠檬", "醋"]
        case "火": return ["红色食物", "苦味适量", "红枣", "番茄"]
        case "土": return ["黄色食物", "甘味", "南瓜", "小米"]
        case "金": return ["白色食物", "辛味适量", "萝卜", "梨"]
        case "水": return ["黑色食物", "咸味适量", "黑豆", "海带"]
        default: return []
        }
    }

    private func getFoodAvoid(_ wuXing: String) -> [String] {
        switch wuXing {
        case "木": return ["过酸", "肝胆负担重的食物"]
        case "火": return ["过辣", "刺激性食物"]
        case "土": return ["过甜", "生冷食物"]
        case "金": return ["过辛", "油炸食物"]
        case "水": return ["过咸", "寒凉食物"]
        default: return []
        }
    }

    private func getExercise(_ wuXing: String) -> [String] {
        switch wuXing {
        case "木": return ["户外徒步", "瑜伽", "太极"]
        case "火": return ["有氧运动", "跑步", "舞蹈"]
        case "土": return ["散步", "八段锦", "园艺"]
        case "金": return ["器械健身", "武术", "攀岩"]
        case "水": return ["游泳", "冥想", "普拉提"]
        default: return []
        }
    }

    private func getHealthConcern(_ wuXing: String) -> String {
        switch wuXing {
        case "木": return "肝胆、眼睛"
        case "火": return "心脏、血压"
        case "土": return "脾胃、消化"
        case "金": return "肺部、呼吸"
        case "水": return "肾脏、泌尿"
        default: return ""
        }
    }

    // MARK: - 数字时辰数据

    private func getLuckyNumbers(_ wuXing: String) -> [Int] {
        switch wuXing {
        case "木": return [3, 8]
        case "火": return [2, 7]
        case "土": return [5, 10]
        case "金": return [4, 9]
        case "水": return [1, 6]
        default: return []
        }
    }

    private func getLuckyHours(_ wuXing: String) -> String {
        switch wuXing {
        case "木": return "寅卯时(3-7点)"
        case "火": return "巳午时(9-13点)"
        case "土": return "辰戌丑未时"
        case "金": return "申酉时(15-19点)"
        case "水": return "亥子时(21-1点)"
        default: return ""
        }
    }

    private func getLuckySeason(_ wuXing: String) -> String {
        switch wuXing {
        case "木": return "春季"
        case "火": return "夏季"
        case "土": return "四季交替"
        case "金": return "秋季"
        case "水": return "冬季"
        default: return ""
        }
    }

    // MARK: - 居家环境数据

    private func getMaterials(_ wuXing: String) -> [String] {
        switch wuXing {
        case "木": return ["实木家具", "竹制品", "藤编"]
        case "火": return ["皮革", "羊毛", "灯饰"]
        case "土": return ["陶瓷", "石材", "砖瓦"]
        case "金": return ["金属制品", "不锈钢", "铜器"]
        case "水": return ["玻璃", "水晶", "镜面"]
        default: return []
        }
    }

    private func getPlants(_ wuXing: String) -> [String] {
        switch wuXing {
        case "木": return ["发财树", "绿萝", "龟背竹"]
        case "火": return ["红掌", "朱顶红", "三角梅"]
        case "土": return ["多肉", "仙人掌", "虎皮兰"]
        case "金": return ["白掌", "栀子花", "茉莉"]
        case "水": return ["富贵竹", "铜钱草", "碗莲"]
        default: return []
        }
    }

    private func getAccessories(_ wuXing: String) -> [String] {
        switch wuXing {
        case "木": return ["檀木", "小叶紫檀", "绿松石"]
        case "火": return ["红玛瑙", "石榴石", "紫水晶"]
        case "土": return ["黄水晶", "蜜蜡", "玉石"]
        case "金": return ["银饰", "白水晶", "珍珠"]
        case "水": return ["黑曜石", "海蓝宝", "月光石"]
        default: return []
        }
    }

    // MARK: - 日主比喻（简短人话）

    private func getDayMasterMetaphor(_ gan: String) -> String {
        switch gan {
        case "甲": return "像参天大树，正直有担当，喜欢当领头羊"
        case "乙": return "像花草藤蔓，温和善变通，懂得借力使力"
        case "丙": return "像太阳光芒，热情又大方，天生感染力"
        case "丁": return "像烛火温暖，细腻有洞察，内热外含蓄"
        case "戊": return "像高山大地，稳重又可靠，给人安全感"
        case "己": return "像田园沃土，温厚又细心，善于照顾人"
        case "庚": return "像刀剑斧钺，刚毅又果断，做事雷厉风行"
        case "辛": return "像珠宝首饰，精致有品味，追求完美主义"
        case "壬": return "像江河大海，聪慧又宽广，善于谋略变通"
        case "癸": return "像雨露溪流，敏感又灵动，直觉力很强"
        default: return ""
        }
    }

    private func wuXingCircle(wx: String, isFilled: Bool, size: CGFloat = 32) -> some View {
        let colors = WuXingColor.colors(for: wx)
        let fontSize: CGFloat = size * 0.44

        return Group {
            if isFilled {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [colors.primary, colors.secondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size, height: size)
                    .overlay(
                        Text(wx)
                            .font(.system(size: fontSize, weight: .medium))
                            .foregroundColor(.white)
                    )
            } else {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [colors.primary.opacity(0.5), colors.secondary.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: size, height: size)
                    .overlay(
                        Text(wx)
                            .font(.system(size: fontSize, weight: .light))
                            .foregroundColor(colors.primary.opacity(0.7))
                    )
            }
        }
    }

}
