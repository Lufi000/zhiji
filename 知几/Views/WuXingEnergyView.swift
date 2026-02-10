import SwiftUI

/// 右侧灰色小字：将位置名转为「柱子」说明（年→年柱，大运/流年不变）
private func positionDisplayLabel(_ position: String) -> String {
    if position == "年" || position == "月" || position == "日" || position == "时" {
        return position + "柱"
    }
    return position
}

private func positionsDisplayLabel(_ positions: [String]) -> String {
    positions.map { positionDisplayLabel($0) }.joined(separator: " ")
}

// MARK: - 五行能量解读视图

struct WuXingEnergyView: View {
    let bazi: Bazi

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
                Text("能量互动")
                    .font(.system(size: 15, weight: .light))
                    .foregroundColor(DesignSystem.textPrimary)
                    .tracking(2)

                if hasWuXingRelations {
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

                                    // 位置（说明是哪个柱子）
                                    Text(positionsDisplayLabel(he.positions))
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

                                    // 位置（说明是哪个柱子）
                                    Text(positionDisplayLabel(ku.position))
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

                                    // 位置（说明是哪个柱子）
                                    Text(positionsDisplayLabel(chongResult.positions))
                                        .font(.system(size: 10, weight: .light))
                                        .foregroundColor(DesignSystem.textTertiary)
                                }
                            }
                        }
                    }
                } else {
                    Text("暂无")
                        .font(.system(size: 13, weight: .light))
                        .foregroundColor(DesignSystem.textTertiary)
                }
            }
            .padding(24)
        }
    }
}

// MARK: - 大运流年与命盘互动视图

/// 展示「选中的大运」与「选中的流年」与命盘的五行互动（合会、冲刑破害、库）
struct DaYunLiuNianEnergyView: View {
    let bazi: Bazi
    let daYunGan: String
    let daYunZhi: String
    /// 选中的流年公历年份；nil 时不显示流年与命盘互动
    let liuNianYear: Int?

    init(bazi: Bazi, daYunGan: String, daYunZhi: String, liuNianYear: Int? = nil) {
        self.bazi = bazi
        self.daYunGan = daYunGan
        self.daYunZhi = daYunZhi
        self.liuNianYear = liuNianYear
    }

    private var daYunAnalysis: WuXingAnalysis {
        analyzeBaziWithExtraPillar(bazi: bazi, extraGan: daYunGan, extraZhi: daYunZhi, extraPositionName: "大运")
    }

    private var daYunHasRelations: Bool {
        !daYunAnalysis.heResults.isEmpty ||
        !daYunAnalysis.chongXingHaiResults.isEmpty ||
        !daYunAnalysis.kuResults.isEmpty
    }

    private var liuNianAnalysis: WuXingAnalysis? {
        guard let year = liuNianYear else { return nil }
        let ln = getLiuNianGanZhi(year: year)
        return analyzeBaziWithExtraPillar(bazi: bazi, extraGan: ln.gan, extraZhi: ln.zhi, extraPositionName: "流年")
    }

    private func liuNianHasRelations(_ a: WuXingAnalysis) -> Bool {
        !a.heResults.isEmpty || !a.chongXingHaiResults.isEmpty || !a.kuResults.isEmpty
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 20) {
                // 大运
                pillarInteractionBlock(
                    title: "大运",
                    analysis: daYunAnalysis,
                    hasRelations: daYunHasRelations,
                    emptyMessage: "该大运与命盘暂无合会、冲刑破害或库的互动"
                )

                // 流年（仅当选中流年时显示）
                if liuNianYear != nil, let lnAnalysis = liuNianAnalysis {
                    pillarInteractionBlock(
                        title: "流年",
                        analysis: lnAnalysis,
                        hasRelations: liuNianHasRelations(lnAnalysis),
                        emptyMessage: "该流年与命盘暂无合会、冲刑破害或库的互动"
                    )
                }
            }
            .padding(24)
        }
    }

    /// 单块「某柱与命盘互动」展示：标题 + 合会/库/刑冲破害
    private func pillarInteractionBlock(
        title: String,
        analysis: WuXingAnalysis,
        hasRelations: Bool,
        emptyMessage: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 15, weight: .light))
                .foregroundColor(DesignSystem.textPrimary)
                .tracking(2)

            if hasRelations {
                if !analysis.heResults.isEmpty {
                    relationSection(title: "合会", items: analysis.heResults) { he in
                        HStack(spacing: 6) {
                            Text(he.type.rawValue)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(WuXingColor.waveColor)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                            Text(he.elements.joined(separator: ""))
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(DesignSystem.textPrimary)
                            if let huaWx = he.huaWuXing {
                                Text("→ 化\(huaWx)")
                                    .font(.system(size: 11, weight: .light))
                                    .foregroundColor(WuXingColor.colors(for: huaWx).secondary)
                            } else if he.type == .tianGanHe {
                                Text("(合绊)")
                                    .font(.system(size: 10, weight: .light))
                                    .foregroundColor(DesignSystem.textTertiary)
                            } else if let banHeWx = he.banHeWuXing {
                                Text("(半合\(banHeWx))")
                                    .font(.system(size: 10, weight: .light))
                                    .foregroundColor(WuXingColor.colors(for: banHeWx).secondary.opacity(0.7))
                            }
                            Spacer()
                            Text(positionsDisplayLabel(he.positions))
                                .font(.system(size: 10, weight: .light))
                                .foregroundColor(DesignSystem.textTertiary)
                        }
                    }
                }
                if !analysis.kuResults.isEmpty {
                    relationSection(title: "库", items: analysis.kuResults) { ku in
                        HStack(spacing: 6) {
                            if ku.isFormed, let kuWuXing = ku.kuWuXing {
                                Text("\(kuWuXing)库")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(WuXingColor.colors(for: kuWuXing).secondary)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            } else {
                                Text("土")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(WuXingColor.earthColor)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                            Text(ku.zhi)
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(DesignSystem.textPrimary)
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
                            Text(positionDisplayLabel(ku.position))
                                .font(.system(size: 10, weight: .light))
                                .foregroundColor(DesignSystem.textTertiary)
                        }
                    }
                }
                if !analysis.chongXingHaiResults.isEmpty {
                    relationSection(title: "刑冲破害", items: analysis.chongXingHaiResults) { chong in
                        HStack(spacing: 6) {
                            Text(chong.type)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(WuXingColor.stoneColor)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                            Text(chong.elements.joined(separator: ""))
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(DesignSystem.textPrimary)
                            Spacer()
                            Text(positionsDisplayLabel(chong.positions))
                                .font(.system(size: 10, weight: .light))
                                .foregroundColor(DesignSystem.textTertiary)
                        }
                    }
                }
            } else {
                Text(emptyMessage)
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(DesignSystem.textTertiary)
            }
        }
    }

    private func relationSection<Item>(
        title: String,
        items: [Item],
        @ViewBuilder rowContent: @escaping (Item) -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(DesignSystem.textSecondary)
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                rowContent(item)
            }
        }
    }
}

// MARK: - 嵌入式能量互动视图（无 GlassCard 外壳，用于折叠展开）

struct EmbeddedWuXingEnergyView: View {
    let bazi: Bazi

    private var analysis: WuXingAnalysis { analyzeWuXingRelations(bazi: bazi) }

    private var hasWuXingRelations: Bool {
        !analysis.heResults.isEmpty ||
        !analysis.chongXingHaiResults.isEmpty ||
        !analysis.kuResults.isEmpty ||
        !analysis.tanShengWangKeResults.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("能量互动")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(DesignSystem.textSecondary)

            if hasWuXingRelations {
                // 合会
                if !analysis.heResults.isEmpty {
                    embeddedRelationSection(title: "合会") {
                        ForEach(analysis.heResults.indices, id: \.self) { i in
                            let he = analysis.heResults[i]
                            HStack(spacing: 6) {
                                Text(he.type.rawValue)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(WuXingColor.waveColor)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))

                                Text(he.elements.joined(separator: ""))
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(DesignSystem.textPrimary)

                                if let huaWx = he.huaWuXing {
                                    Text("→ 化\(huaWx)")
                                        .font(.system(size: 10, weight: .light))
                                        .foregroundColor(WuXingColor.colors(for: huaWx).secondary)
                                } else if he.type == .tianGanHe {
                                    Text("(合绊)")
                                        .font(.system(size: 9, weight: .light))
                                        .foregroundColor(DesignSystem.textTertiary)
                                } else if let banHeWx = he.banHeWuXing {
                                    Text("(半合\(banHeWx))")
                                        .font(.system(size: 9, weight: .light))
                                        .foregroundColor(WuXingColor.colors(for: banHeWx).secondary.opacity(0.7))
                                }

                                Spacer()

                                Text(positionsDisplayLabel(he.positions))
                                    .font(.system(size: 9, weight: .light))
                                    .foregroundColor(DesignSystem.textTertiary)
                            }
                        }
                    }
                }

                // 库
                if !analysis.kuResults.isEmpty {
                    embeddedRelationSection(title: "库") {
                        ForEach(analysis.kuResults.indices, id: \.self) { i in
                            let ku = analysis.kuResults[i]
                            HStack(spacing: 6) {
                                if ku.isFormed, let kuWuXing = ku.kuWuXing {
                                    Text("\(kuWuXing)库")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(WuXingColor.colors(for: kuWuXing).secondary)
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                } else {
                                    Text("土")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(WuXingColor.earthColor)
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                }

                                Text(ku.zhi)
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(DesignSystem.textPrimary)

                                if ku.isFormed, let triggerGan = ku.triggerGan, let kuWuXing = ku.kuWuXing {
                                    Text("遇\(triggerGan)→\(kuWuXing)库")
                                        .font(.system(size: 9, weight: .light))
                                        .foregroundColor(WuXingColor.colors(for: kuWuXing).secondary)
                                } else {
                                    Text("未成库(属土)")
                                        .font(.system(size: 9, weight: .light))
                                        .foregroundColor(DesignSystem.textTertiary)
                                }

                                Spacer()

                                Text(positionDisplayLabel(ku.position))
                                    .font(.system(size: 9, weight: .light))
                                    .foregroundColor(DesignSystem.textTertiary)
                            }
                        }
                    }
                }

                // 贪生忘克
                if !analysis.tanShengWangKeResults.isEmpty {
                    embeddedRelationSection(title: "贪生忘克") {
                        ForEach(analysis.tanShengWangKeResults.indices, id: \.self) { i in
                            let tanShengResult = analysis.tanShengWangKeResults[i]
                            let keColors = WuXingColor.colors(for: tanShengResult.keWuXing)

                            HStack(spacing: 6) {
                                Text(tanShengResult.keWuXing)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(keColors.secondary)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))

                                Text(tanShengResult.description)
                                    .font(.system(size: 10, weight: .light))
                                    .foregroundColor(DesignSystem.textSecondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                }

                // 刑冲破害
                if !analysis.chongXingHaiResults.isEmpty {
                    embeddedRelationSection(title: "刑冲破害") {
                        ForEach(analysis.chongXingHaiResults.indices, id: \.self) { i in
                            let chongResult = analysis.chongXingHaiResults[i]
                            HStack(spacing: 6) {
                                Text(chongResult.type)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(WuXingColor.stoneColor)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))

                                Text(chongResult.elements.joined(separator: ""))
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(DesignSystem.textPrimary)

                                Spacer()

                                Text(positionsDisplayLabel(chongResult.positions))
                                    .font(.system(size: 9, weight: .light))
                                    .foregroundColor(DesignSystem.textTertiary)
                            }
                        }
                    }
                }
            } else {
                Text("暂无")
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(DesignSystem.textTertiary)
            }
        }
    }

    private func embeddedRelationSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(DesignSystem.textTertiary)
            content()
        }
    }
}

// MARK: - 嵌入式大运流年互动视图（无 GlassCard 外壳，用于折叠展开）

struct EmbeddedDaYunLiuNianEnergyView: View {
    let bazi: Bazi
    let daYunGan: String
    let daYunZhi: String
    let liuNianYear: Int?

    private var daYunAnalysis: WuXingAnalysis {
        analyzeBaziWithExtraPillar(bazi: bazi, extraGan: daYunGan, extraZhi: daYunZhi, extraPositionName: "大运")
    }

    private var daYunHasRelations: Bool {
        !daYunAnalysis.heResults.isEmpty ||
        !daYunAnalysis.chongXingHaiResults.isEmpty ||
        !daYunAnalysis.kuResults.isEmpty
    }

    private var liuNianAnalysis: WuXingAnalysis? {
        guard let year = liuNianYear else { return nil }
        let ln = getLiuNianGanZhi(year: year)
        return analyzeBaziWithExtraPillar(bazi: bazi, extraGan: ln.gan, extraZhi: ln.zhi, extraPositionName: "流年")
    }

    private func liuNianHasRelations(_ a: WuXingAnalysis) -> Bool {
        !a.heResults.isEmpty || !a.chongXingHaiResults.isEmpty || !a.kuResults.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 大运
            embeddedPillarBlock(
                title: "大运与命盘",
                analysis: daYunAnalysis,
                hasRelations: daYunHasRelations,
                emptyMessage: "暂无合会、冲刑破害或库的互动"
            )

            // 流年（仅当选中流年时显示）
            if liuNianYear != nil, let lnAnalysis = liuNianAnalysis {
                embeddedPillarBlock(
                    title: "流年与命盘",
                    analysis: lnAnalysis,
                    hasRelations: liuNianHasRelations(lnAnalysis),
                    emptyMessage: "暂无合会、冲刑破害或库的互动"
                )
            }
        }
    }

    private func embeddedPillarBlock(
        title: String,
        analysis: WuXingAnalysis,
        hasRelations: Bool,
        emptyMessage: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(DesignSystem.textSecondary)

            if hasRelations {
                if !analysis.heResults.isEmpty {
                    embeddedRelationSection(title: "合会") {
                        ForEach(Array(analysis.heResults.enumerated()), id: \.offset) { _, he in
                            HStack(spacing: 6) {
                                Text(he.type.rawValue)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(WuXingColor.waveColor)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                                Text(he.elements.joined(separator: ""))
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(DesignSystem.textPrimary)
                                if let huaWx = he.huaWuXing {
                                    Text("→ 化\(huaWx)")
                                        .font(.system(size: 10, weight: .light))
                                        .foregroundColor(WuXingColor.colors(for: huaWx).secondary)
                                } else if he.type == .tianGanHe {
                                    Text("(合绊)")
                                        .font(.system(size: 9, weight: .light))
                                        .foregroundColor(DesignSystem.textTertiary)
                                } else if let banHeWx = he.banHeWuXing {
                                    Text("(半合\(banHeWx))")
                                        .font(.system(size: 9, weight: .light))
                                        .foregroundColor(WuXingColor.colors(for: banHeWx).secondary.opacity(0.7))
                                }
                                Spacer()
                                Text(positionsDisplayLabel(he.positions))
                                    .font(.system(size: 9, weight: .light))
                                    .foregroundColor(DesignSystem.textTertiary)
                            }
                        }
                    }
                }
                if !analysis.kuResults.isEmpty {
                    embeddedRelationSection(title: "库") {
                        ForEach(Array(analysis.kuResults.enumerated()), id: \.offset) { _, ku in
                            HStack(spacing: 6) {
                                if ku.isFormed, let kuWuXing = ku.kuWuXing {
                                    Text("\(kuWuXing)库")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(WuXingColor.colors(for: kuWuXing).secondary)
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                } else {
                                    Text("土")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(WuXingColor.earthColor)
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                }
                                Text(ku.zhi)
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(DesignSystem.textPrimary)
                                if ku.isFormed, let triggerGan = ku.triggerGan, let kuWuXing = ku.kuWuXing {
                                    Text("遇\(triggerGan)→\(kuWuXing)库")
                                        .font(.system(size: 9, weight: .light))
                                        .foregroundColor(WuXingColor.colors(for: kuWuXing).secondary)
                                } else {
                                    Text("未成库(属土)")
                                        .font(.system(size: 9, weight: .light))
                                        .foregroundColor(DesignSystem.textTertiary)
                                }
                                Spacer()
                                Text(positionDisplayLabel(ku.position))
                                    .font(.system(size: 9, weight: .light))
                                    .foregroundColor(DesignSystem.textTertiary)
                            }
                        }
                    }
                }
                if !analysis.chongXingHaiResults.isEmpty {
                    embeddedRelationSection(title: "刑冲破害") {
                        ForEach(Array(analysis.chongXingHaiResults.enumerated()), id: \.offset) { _, chong in
                            HStack(spacing: 6) {
                                Text(chong.type)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(WuXingColor.stoneColor)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                                Text(chong.elements.joined(separator: ""))
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(DesignSystem.textPrimary)
                                Spacer()
                                Text(positionsDisplayLabel(chong.positions))
                                    .font(.system(size: 9, weight: .light))
                                    .foregroundColor(DesignSystem.textTertiary)
                            }
                        }
                    }
                }
            } else {
                Text(emptyMessage)
                    .font(.system(size: 11, weight: .light))
                    .foregroundColor(DesignSystem.textTertiary)
            }
        }
    }

    private func embeddedRelationSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(DesignSystem.textTertiary)
            content()
        }
    }
}

// MARK: - 五行能量条（已不在主视图使用，保留供复用）

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
            // 五行标签（不显示「主」）
            Text(item.wuXing)
                .font(.system(size: 14, weight: isDayMaster ? .medium : .light))
                .foregroundColor(colors.secondary)
                .frame(width: 24, alignment: .leading)

            // 能量条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 8)

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

            // 仅显示百分比（不显示极旺/偏旺等强度标签）
            Text(String(format: "%.0f%%", item.percentage))
                .font(.system(size: 11, weight: .light, design: .monospaced))
                .foregroundColor(DesignSystem.textSecondary)
                .frame(width: 36, alignment: .trailing)
        }
    }
}
