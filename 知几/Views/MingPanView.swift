import SwiftUI

// MARK: - 命盘视图

struct MingPanView: View {
    @Bindable var viewModel: ResultViewModel
    var mingPanStore: MingPanStore
    let onBack: () -> Void

    /// 当前选中大运步数（用于下方全宽显示流年）；nil 表示不显示流年
    @State private var selectedDaYunIndex: Int? = nil
    /// 当前选中流年（公历年份）；仅当属于当前选中大运的十年内时有效
    @State private var selectedLiuNianYear: Int? = nil
    /// 是否已初始化默认选中
    @State private var hasInitializedSelection = false
    
    /// 能量互动折叠状态（默认收起）
    @State private var isEnergyExpanded = false
    /// 大运流年互动折叠状态（默认收起）
    @State private var isDaYunEnergyExpanded = false

    /// 流月序号（0：正月寅 … 11：腊月丑），依赖当前选中的流年公历年
    @State private var selectedLiuYueIndex: Int = 0
    /// 流日选中（与流年格可选中一致）；nil 表示未初始化
    @State private var selectedLiuRiYMD: (year: Int, month: Int, day: Int)? = nil

    @State private var showSaveSheet = false
    @State private var saveToastMessage: String?

    var body: some View {
        ScrollViewReader { _ in
            ZStack(alignment: .top) {
                // 内容区域（可滚动到 tab 下方）
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        // 顶部占位，为 header 留出空间
                        Color.clear.frame(height: 60)
                        
                        dayMasterCard
                        fourPillarsCard

                        // MARK: - 大运与流年
                        daYunLiuNianSection

                        // MARK: - 流月与流日（节气为月界）
                        liuYueLiuRiSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 100)
                }
                .onAppear {
                    guard !hasInitializedSelection else { return }
                    hasInitializedSelection = true
                    // 默认选中当前大运
                    selectedDaYunIndex = viewModel.currentDaYunStepIndex
                    // 默认选中当前流年
                    let currentYear = gregorianLocalCalendar().component(.year, from: Date())
                    let yearsInCurrentDaYun = viewModel.yearsForDaYunStep(viewModel.currentDaYunStepIndex)
                    if yearsInCurrentDaYun.contains(currentYear) {
                        selectedLiuNianYear = currentYear
                    }
                    if let y = selectedLiuNianYear {
                        selectedLiuYueIndex = liuYueIndexContaining(solarYear: y, reference: Date())
                        syncLiuRiSelectionAfterLiuYueChange()
                    }
                }
                .onChange(of: selectedLiuNianYear) { _, newYear in
                    if let y = newYear {
                        selectedLiuYueIndex = liuYueIndexContaining(solarYear: y, reference: Date())
                        syncLiuRiSelectionAfterLiuYueChange()
                    } else {
                        selectedLiuRiYMD = nil
                    }
                }
                .onChange(of: selectedLiuYueIndex) { _, _ in
                    syncLiuRiSelectionAfterLiuYueChange()
                }
                
                // 顶部整体区域（状态栏 + headerBar）
                headerBar
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
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
            .sheet(isPresented: $showSaveSheet) {
                SaveMingPanSheet(
                    mingPanStore: mingPanStore,
                    viewModel: viewModel,
                    onSaved: { message in
                        saveToastMessage = message
                        Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 2_000_000_000)
                            saveToastMessage = nil
                        }
                    }
                )
            }
        }
        .overlay(alignment: .top) {
            if let message = saveToastMessage {
                Text(message)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.75))
                    .clipShape(Capsule())
                    .padding(.top, 60)
                    .transition(.move(edge: .top).combined(with: .opacity))
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

            Button(action: { showSaveSheet = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 13, weight: .semibold))
                    Text("保存")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(DesignSystem.primaryOrange)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
                )
                .overlay(
                    Capsule()
                        .strokeBorder(DesignSystem.primaryOrange.opacity(0.35), lineWidth: 0.5)
                )
            }
            .buttonStyle(.plain)

            // Logo + 复制命盘按钮（毛玻璃质感）
            Button(action: { viewModel.copyMingPanForDeepSeek() }) {
                HStack(spacing: 6) {
                    AppLogo(size: 24)
                    Text("复制到 AI")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(DesignSystem.textSecondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
                )
                .overlay(
                    Capsule()
                        .strokeBorder(Color.white.opacity(0.5), lineWidth: 0.5)
                )
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - 四柱卡片（含能量互动折叠）
    
    private var fourPillarsCard: some View {
        GlassCard {
            VStack(spacing: 0) {
                // 四柱主体
                HStack(spacing: 0) {
                    ForEach(Array(zip(["年", "月", "日", "时"], [viewModel.bazi.year, viewModel.bazi.month, viewModel.bazi.day, viewModel.bazi.hour]).enumerated()), id: \.0) { i, item in
                        PillarView(
                            title: item.0,
                            gan: item.1.gan,
                            zhi: item.1.zhi,
                            shiShen: viewModel.getGanShiShen(position: item.0, gan: item.1.gan),
                            zhiShiShen: viewModel.getZhiShiShenDisplay(item.1.zhi),
                            isDay: i == 2,
                            riGan: viewModel.bazi.day.gan
                        )
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, 24)
                .padding(.horizontal, 24)
                
                // 展开/收起按钮
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isEnergyExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 6) {
                        if isEnergyExpanded {
                            Text("能量互动")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(DesignSystem.textTertiary)
                        }
                        Image(systemName: isEnergyExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(DesignSystem.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                // 展开内容：能量互动
                if isEnergyExpanded {
                    Divider()
                        .padding(.horizontal, 24)
                    
                    EmbeddedWuXingEnergyView(bazi: viewModel.bazi)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 24)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }

    // MARK: - 日主卡片（Risograph 艺术风格）

    private var dayMasterCard: some View {
        let dayGan = viewModel.bazi.day.gan
        let dayWx = BaziConstants.wuXing[dayGan] ?? "木"
        let colors = WuXingColor.colors(for: dayWx)
        let ganExplanation = BaziExplanations.getGanExplanation(dayGan)
        
        // 柔和的底色（基于五行色的极浅版本）
        let backgroundColor = colors.secondary.opacity(0.12)

        return GlassCard(tintColor: colors.primary) {
            // 艺术图形区域
            ZStack(alignment: .top) {
                // 底层：信息条背景（带渐变过渡到透明）
                ZStack {
                    // 渐变背景：从五行色到透明（从波浪处开始）
                    LinearGradient(
                        stops: [
                            .init(color: colors.secondary.opacity(0.06), location: 0),
                            .init(color: colors.secondary.opacity(0.06), location: 0.8),
                            .init(color: .clear, location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    
                    // 信息条背景肌理
                    BackgroundTexture()
                        .opacity(0.5)
                        .mask(
                            LinearGradient(
                                stops: [
                                    .init(color: .white, location: 0),
                                    .init(color: .white, location: 0.8),
                                    .init(color: .clear, location: 1.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                
                // 上层：图形区域（波浪底部形状）
                ZStack {
                    // 图形区域底色
                    backgroundColor
                    
                    // 背景肌理
                    BackgroundTexture()
                        .opacity(0.6)
                    
                    // 左侧竖排简短描述 + 中间有机图形
                    ZStack {
                        // 中间：有机几何图形（居中）
                        DayMasterShape(tianGan: dayGan, size: 110)
                        
                        // 左侧：竖排简短描述
                        if let explanation = ganExplanation, !explanation.shortMetaphor.isEmpty {
                            HStack {
                                VerticalText(text: explanation.shortMetaphor, color: colors.primary)
                                    .padding(.leading, 16)
                                Spacer()
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 150)
                .clipShape(WaveBottomShape(waveHeight: 16))
                
                // 文字信息条
                HStack(alignment: .center) {
                    // 左侧：出生日期
                    Text(verbatim: "\(viewModel.birth.year)年\(viewModel.birth.month)月\(viewModel.birth.day)日 \(viewModel.birth.hour)时\(viewModel.birth.minute)分")
                        .font(.system(size: 12, weight: .light))
                        .foregroundColor(colors.secondary.opacity(0.8))
                    
                    Spacer()
                    
                    // 右侧：日主五行
                    HStack(spacing: 2) {
                        Text(dayGan)
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(colors.secondary)
                        Text(dayWx)
                            .font(.system(size: 22, weight: .light))
                            .foregroundColor(colors.primary)
                    }
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 12)
            }
            .frame(height: 195)
        }
    }

    // MARK: - 大运与流年（四柱风格：天干/地支块，含互动折叠）

    private var daYunLiuNianSection: some View {
        GlassCard {
            VStack(spacing: 0) {
                // 大运流年主体
                VStack(alignment: .leading, spacing: 16) {
                    Text("大运与流年")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(DesignSystem.textPrimary)

                    Text("起运 \(viewModel.qiYunAge) 岁 · 每步大运十年")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(DesignSystem.textSecondary)

                    // 大运：横向一排（可横向滚动），选中项滑动到屏幕中间
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(Array(viewModel.daYunList.enumerated()), id: \.offset) { index, daYun in
                                    let yearRange = viewModel.yearsForDaYunStep(index)
                                    let rangeStr = yearRange.isEmpty ? "" : "\(yearRange.first!)"
                                    let isSelected = index == selectedDaYunIndex

                                    Button {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedDaYunIndex = selectedDaYunIndex == index ? nil : index
                                        }
                                    } label: {
                                        daYunPillar(gan: daYun.gan, zhi: daYun.zhi, age: daYun.age, yearRange: rangeStr, isSelected: isSelected)
                                    }
                                    .buttonStyle(.plain)
                                    .frame(width: 80)
                                    .id(index)
                                }
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 2) // 避免首尾大运的描边被裁切
                        }
                        .onChange(of: selectedDaYunIndex) { oldValue, newValue in
                            // 仅在用户手动切换大运时清空流年（非初始化阶段）
                            if oldValue != nil {
                                selectedLiuNianYear = nil
                            }
                            guard let idx = newValue else { return }
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo(idx, anchor: .center)
                            }
                        }
                    }

                    // 流年：全宽横向一排（可选中），显示当前选中大运的十年
                    if let idx = selectedDaYunIndex, idx < viewModel.daYunList.count {
                        let years = viewModel.yearsForDaYunStep(idx)
                        if !years.isEmpty {
                            liuNianOneRow(years: years, selectedYear: selectedLiuNianYear) { year in
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedLiuNianYear = selectedLiuNianYear == year ? nil : year
                                }
                            }
                            .padding(.top, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(.vertical, 24)
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 展开/收起按钮（仅当选中了大运时显示）
                if let idx = selectedDaYunIndex, idx < viewModel.daYunList.count {
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isDaYunEnergyExpanded.toggle()
                        }
                    } label: {
                        HStack(spacing: 6) {
                            if isDaYunEnergyExpanded {
                                Text("与命盘互动")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(DesignSystem.textTertiary)
                            }
                            Image(systemName: isDaYunEnergyExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(DesignSystem.textTertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    
                    // 展开内容：大运流年与命盘互动
                    if isDaYunEnergyExpanded {
                        let daYun = viewModel.daYunList[idx]
                        
                        Divider()
                            .padding(.horizontal, 24)
                        
                        EmbeddedDaYunLiuNianEnergyView(
                            bazi: viewModel.bazi,
                            daYunGan: daYun.gan,
                            daYunZhi: daYun.zhi,
                            liuNianYear: selectedLiuNianYear
                        )
                        .padding(.horizontal, 24)
                        .padding(.vertical, 24)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
        }
    }

    // MARK: - 流月与流日

    /// 选中流月后，默认选「今日」若落在该流月内，否则该段第一日
    private func syncLiuRiSelectionAfterLiuYueChange() {
        guard let solarYear = selectedLiuNianYear else {
            selectedLiuRiYMD = nil
            return
        }
        let days = solarDaysInLiuYueSegment(solarYear: solarYear, liuYueIndex: selectedLiuYueIndex)
        let cal = gregorianLocalCalendar()
        let now = Date()
        let cy = cal.component(.year, from: now)
        let cm = cal.component(.month, from: now)
        let cd = cal.component(.day, from: now)
        if solarYear == cy, let hit = days.first(where: { $0.0 == cy && $0.1 == cm && $0.2 == cd }) {
            selectedLiuRiYMD = (hit.0, hit.1, hit.2)
        } else if let first = days.first {
            selectedLiuRiYMD = (first.0, first.1, first.2)
        } else {
            selectedLiuRiYMD = nil
        }
    }

    private var liuYueLiuRiSection: some View {
        let liuNianFont: CGFloat = 16
        let liuNianWx: CGFloat = 8

        return GlassCard {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("流月与流日")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(DesignSystem.textPrimary)

                    Text("以十二节为月界；流月，流日干支与流年格同一套样式")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(DesignSystem.textSecondary)

                    if let year = selectedLiuNianYear {
                        let ln = getLiuNianGanZhi(year: year)
                        Text(verbatim: "流年 \(year)（\(ln.gan)\(ln.zhi)年）")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(DesignSystem.textSecondary)

                        Text("流月")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(DesignSystem.textPrimary)
                            .padding(.top, 12)

                        ScrollViewReader { proxy in
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(0..<12, id: \.self) { idx in
                                        let isSelected = idx == selectedLiuYueIndex
                                        let ly = getLiuYueGanZhi(solarYear: year, liuYueIndex: idx)
                                        let label = LiuYueIndex(rawValue: idx)?.monthLabel ?? "\(idx)"

                                        Button {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                selectedLiuYueIndex = idx
                                            }
                                        } label: {
                                            liuNianStyleGanZhiBlock(
                                                topLine: label,
                                                gan: ly.gan,
                                                zhi: ly.zhi,
                                                isSelected: isSelected,
                                                fontSize: liuNianFont,
                                                wxFontSize: liuNianWx
                                            )
                                        }
                                        .buttonStyle(.plain)
                                        .id(idx)
                                    }
                                }
                                .padding(.vertical, 4)
                                .padding(.horizontal, 2)
                            }
                            .onAppear {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    proxy.scrollTo(selectedLiuYueIndex, anchor: .center)
                                }
                            }
                            .onChange(of: selectedLiuYueIndex) { _, newValue in
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    proxy.scrollTo(newValue, anchor: .center)
                                }
                            }
                        }

                        let days = solarDaysInLiuYueSegment(solarYear: year, liuYueIndex: selectedLiuYueIndex)
                        if !days.isEmpty {
                            Text("流日")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(DesignSystem.textPrimary)
                                .padding(.top, 12)

                            ScrollViewReader { proxy in
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 6) {
                                        ForEach(Array(days.enumerated()), id: \.offset) { _, ymd in
                                            let p = PillarCalculator.getDayPillar(year: ymd.0, month: ymd.1, day: ymd.2)
                                            let sel = selectedLiuRiYMD.map { $0.year == ymd.0 && $0.month == ymd.1 && $0.day == ymd.2 } ?? false
                                            Button {
                                                withAnimation(.easeInOut(duration: 0.2)) {
                                                    selectedLiuRiYMD = (ymd.0, ymd.1, ymd.2)
                                                }
                                            } label: {
                                                liuNianStyleGanZhiBlock(
                                                    topLine: "\(ymd.1)月\(ymd.2)日",
                                                    gan: p.gan,
                                                    zhi: p.zhi,
                                                    isSelected: sel,
                                                    fontSize: liuNianFont,
                                                    wxFontSize: liuNianWx
                                                )
                                            }
                                            .buttonStyle(.plain)
                                            .id(liuRiScrollID(year: ymd.0, month: ymd.1, day: ymd.2))
                                        }
                                    }
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 2)
                                }
                                .onAppear {
                                    guard let selected = selectedLiuRiYMD else { return }
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        proxy.scrollTo(
                                            liuRiScrollID(year: selected.year, month: selected.month, day: selected.day),
                                            anchor: .center
                                        )
                                    }
                                }
                                .onChange(of: selectedLiuRiYMD) { _, newValue in
                                    guard let selected = newValue else { return }
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        proxy.scrollTo(
                                            liuRiScrollID(year: selected.year, month: selected.month, day: selected.day),
                                            anchor: .center
                                        )
                                    }
                                }
                            }
                        }
                    } else {
                        Text("请在大运与流年中点选一年流年，即可查看该年流月与各月流日。")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(DesignSystem.textTertiary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.vertical, 24)
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    /// 与「流年」单格同一布局：顶行小字 + 天干地支五行（用于流年 / 流月 / 流日）
    private func liuNianStyleGanZhiBlock(
        topLine: String,
        gan: String,
        zhi: String,
        isSelected: Bool,
        fontSize: CGFloat,
        wxFontSize: CGFloat
    ) -> some View {
        let ganWx = BaziConstants.wuXing[gan] ?? "木"
        let zhiWx = BaziConstants.wuXing[zhi] ?? "木"
        let ganColors = WuXingColor.colors(for: ganWx)
        let zhiColors = WuXingColor.colors(for: zhiWx)
        let cellWidth: CGFloat = 56

        return VStack(spacing: 4) {
            Text(topLine)
                .font(.system(size: 10, weight: .regular))
                .foregroundColor(DesignSystem.textTertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            VStack(spacing: 2) {
                Text(gan)
                    .font(.system(size: fontSize, weight: .light))
                    .foregroundColor(ganColors.secondary)
                Text(ganWx)
                    .font(.system(size: wxFontSize, weight: .light))
                    .foregroundColor(ganColors.primary)
            }
            VStack(spacing: 2) {
                Text(zhi)
                    .font(.system(size: fontSize, weight: .light))
                    .foregroundColor(zhiColors.secondary)
                Text(zhiWx)
                    .font(.system(size: wxFontSize, weight: .light))
                    .foregroundColor(zhiColors.primary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 6)
        .frame(width: cellWidth)
        .background(isSelected ? Color(hex: "FFF9F5") : Color(hex: "FAFAFA"))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cornerRadiusSmall))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.cornerRadiusSmall)
                .strokeBorder(isSelected ? DesignSystem.primaryOrange : Color.clear, lineWidth: isSelected ? 1.5 : 0)
        )
    }

    /// 单步大运柱：一个白底容器内排天干+地支；仅用选中状态做视觉区分
    private func daYunPillar(gan: String, zhi: String, age: Int, yearRange: String, isSelected: Bool = false) -> some View {
        let ganWx = BaziConstants.wuXing[gan] ?? "木"
        let zhiWx = BaziConstants.wuXing[zhi] ?? "木"
        let ganColors = WuXingColor.colors(for: ganWx)
        let zhiColors = WuXingColor.colors(for: zhiWx)
        let fontSize: CGFloat = 24
        let wxFontSize: CGFloat = 9

        // 白底与选择框同一尺寸：一个 80pt 宽容器，背景为白/选中色，描边在外
        return VStack(spacing: 6) {
            if !yearRange.isEmpty {
                Text(yearRange)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(DesignSystem.textTertiary)
            }
            VStack(spacing: 6) {
                VStack(spacing: 2) {
                    Text(gan)
                        .font(.system(size: fontSize, weight: .light))
                        .foregroundColor(ganColors.secondary)
                    Text(ganWx)
                        .font(.system(size: wxFontSize, weight: .light))
                        .foregroundColor(ganColors.primary)
                }
                VStack(spacing: 2) {
                    Text(zhi)
                        .font(.system(size: fontSize, weight: .light))
                        .foregroundColor(zhiColors.secondary)
                    Text(zhiWx)
                        .font(.system(size: wxFontSize, weight: .light))
                        .foregroundColor(zhiColors.primary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .frame(width: 80)
        .background(isSelected ? Color(hex: "FFF9F5") : Color(hex: "FAFAFA"))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cornerRadiusSmall))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.cornerRadiusSmall)
                .strokeBorder(isSelected ? DesignSystem.primaryOrange : Color.clear, lineWidth: isSelected ? 1.5 : 0)
        )
    }

    /// 流年：横向一排显示（十年，可横向滚动），可选中
    private func liuNianOneRow(years: [Int], selectedYear: Int?, onSelect: @escaping (Int) -> Void) -> some View {
        let fontSize: CGFloat = 16
        let wxFontSize: CGFloat = 8

        return ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(years, id: \.self) { y in
                        Button {
                            onSelect(y)
                        } label: {
                            liuNianCell(year: y, fontSize: fontSize, wxFontSize: wxFontSize, isSelected: selectedYear == y)
                        }
                        .buttonStyle(.plain)
                        .id(y)
                    }
                }
                .padding(.vertical, 4)
            }
            .onAppear {
                guard let y = selectedYear else { return }
                withAnimation(.easeInOut(duration: 0.3)) {
                    proxy.scrollTo(y, anchor: .center)
                }
            }
            .onChange(of: selectedYear) { _, newYear in
                guard let y = newYear else { return }
                withAnimation(.easeInOut(duration: 0.3)) {
                    proxy.scrollTo(y, anchor: .center)
                }
            }
        }
    }

    private func liuRiScrollID(year: Int, month: Int, day: Int) -> String {
        "\(year)-\(month)-\(day)"
    }

    /// 单格流年：与流月、流日共用 `liuNianStyleGanZhiBlock`
    private func liuNianCell(year: Int, fontSize: CGFloat, wxFontSize: CGFloat, isSelected: Bool = false) -> some View {
        let ln = getLiuNianGanZhi(year: year)
        return liuNianStyleGanZhiBlock(
            topLine: "\(year)",
            gan: ln.gan,
            zhi: ln.zhi,
            isSelected: isSelected,
            fontSize: fontSize,
            wxFontSize: wxFontSize
        )
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

// MARK: - 保存命盘 Sheet

private struct SaveMingPanSheet: View {
    @Bindable var mingPanStore: MingPanStore
    let viewModel: ResultViewModel
    let onSaved: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var displayName: String
    @State private var setAsSelf: Bool

    init(mingPanStore: MingPanStore, viewModel: ResultViewModel, onSaved: @escaping (String) -> Void) {
        self.mingPanStore = mingPanStore
        self.viewModel = viewModel
        self.onSaved = onSaved
        let defaultName = "\(viewModel.birth.year)年\(viewModel.birth.month)月\(viewModel.birth.day)日"
        _displayName = State(initialValue: defaultName)
        _setAsSelf = State(initialValue: mingPanStore.selfMingPanId == nil)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("名称", text: $displayName)
                    Toggle("设为我的命盘", isOn: $setAsSelf)
                } footer: {
                    Text("设为我的命盘后，AI 助手会默认使用这份命盘；也可在助手内切换到其他已保存命盘。")
                        .font(.footnote)
                }
            }
            .navigationTitle("保存命盘")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                }
            }
        }
    }

    private func save() {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = trimmed.isEmpty ? "\(viewModel.birth.year)年\(viewModel.birth.month)月\(viewModel.birth.day)日" : trimmed
        let record = SavedMingPanRecord(displayName: name, birth: viewModel.birth, gender: viewModel.gender, bazi: viewModel.bazi)
        mingPanStore.add(record: record, setAsSelf: setAsSelf)
        onSaved(setAsSelf ? "已保存，并设为我的命盘" : "已保存")
        dismiss()
    }
}

// MARK: - 竖排文字（两列，过滤标点）

private struct VerticalText: View {
    let text: String
    let color: Color
    
    private let maxCharsPerColumn = 5
    
    // 过滤掉标点符号
    private static let punctuations: Set<Character> = ["，", "。", "、", "；", "：", "\"", "'", ",", ".", ";", ":", "!", "?", "！", "？"]
    
    private var filteredChars: [Character] {
        text.filter { char in
            !char.isPunctuation && !Self.punctuations.contains(char)
        }.prefix(maxCharsPerColumn * 2).map { $0 }
    }
    
    var body: some View {
        let chars = filteredChars
        let firstColumn = Array(chars.prefix(maxCharsPerColumn))
        let secondColumn = Array(chars.dropFirst(maxCharsPerColumn))
        
        HStack(alignment: .top, spacing: 6) {
            // 第一列
            VStack(spacing: 3) {
                ForEach(Array(firstColumn.enumerated()), id: \.offset) { _, char in
                    Text(String(char))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(color)
                }
            }
            
            // 第二列
            if !secondColumn.isEmpty {
                VStack(spacing: 3) {
                    ForEach(Array(secondColumn.enumerated()), id: \.offset) { _, char in
                        Text(String(char))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(color)
                    }
                }
            }
        }
    }
}

// MARK: - 波浪底部形状（用于图形区域裁剪）

private struct WaveBottomShape: Shape {
    let waveHeight: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let midY = h - waveHeight / 2
        
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: w, y: 0))
        path.addLine(to: CGPoint(x: w, y: midY))
        
        // 平滑正弦波浪（从右到左）
        path.addCurve(
            to: CGPoint(x: 0, y: midY),
            control1: CGPoint(x: w * 0.75, y: midY + waveHeight),
            control2: CGPoint(x: w * 0.25, y: midY - waveHeight)
        )
        
        path.closeSubpath()
        return path
    }
}
