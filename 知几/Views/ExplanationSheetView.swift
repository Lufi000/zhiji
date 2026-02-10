import SwiftUI

// MARK: - 点击元素类型

/// 藏干信息（干支+十神）
struct CangGanInfo: Equatable {
    let gan: String
    let shiShen: String
    let type: String  // 本气、中气、余气
}

enum ExplanationType: Equatable, Identifiable {
    case tianGan(String, pillar: String, shiShen: String?)  // 天干，所在柱位，十神
    case diZhi(String, pillar: String, cangGanList: [CangGanInfo]) // 地支，所在柱位，所有藏干十神
    case cangGan(String, pillar: String, shiShen: String?)  // 藏干，所在柱位，十神
    case shiShen(String)                                     // 十神
    case pillar(String)                                      // 柱位

    var id: String {
        switch self {
        case .tianGan(let gan, let pillar, let shiShen):
            return "tianGan-\(gan)-\(pillar)-\(shiShen ?? "")"
        case .diZhi(let zhi, let pillar, _):
            return "diZhi-\(zhi)-\(pillar)"
        case .cangGan(let gan, let pillar, let shiShen):
            return "cangGan-\(gan)-\(pillar)-\(shiShen ?? "")"
        case .shiShen(let shiShen):
            return "shiShen-\(shiShen)"
        case .pillar(let pillar):
            return "pillar-\(pillar)"
        }
    }
}

// MARK: - 解释Sheet视图

struct ExplanationSheetView: View {
    let explanationType: ExplanationType

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 天干/地支类型：标题和内容合并，不需要分割线
                switch explanationType {
                case .tianGan, .diZhi, .cangGan:
                    contentSection
                default:
                    // 其他类型：标题 + 分割线 + 内容
                    headerSection

                    Divider()
                        .background(Color.gray.opacity(0.3))

                    contentSection
                }

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)
        }
        .background(Color(UIColor.systemBackground))
    }

    // MARK: - 标题区

    @ViewBuilder
    private var headerSection: some View {
        switch explanationType {
        case .tianGan, .cangGan, .diZhi:
            // 天干/地支/藏干：标题和含义合并在 contentSection 中显示
            EmptyView()

        case .shiShen(let shiShen):
            shiShenHeader(name: shiShen)

        case .pillar(let pillar):
            pillarHeader(name: pillar)
        }
    }

    // 十神标题
    private func shiShenHeader(name: String) -> some View {
        HStack(alignment: .center, spacing: 16) {
            Text(name)
                .font(.system(size: 36, weight: .medium))
                .foregroundColor(DesignSystem.textPrimary)

            Text("十神")
                .font(.system(size: 14))
                .foregroundColor(DesignSystem.textTertiary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.gray.opacity(0.1))
                .clipShape(Capsule())

            Spacer()
        }
    }

    // 柱位标题
    private func pillarHeader(name: String) -> some View {
        HStack(alignment: .center, spacing: 16) {
            Text(name)
                .font(.system(size: 36, weight: .medium))
                .foregroundColor(DesignSystem.textPrimary)

            Text("四柱")
                .font(.system(size: 14))
                .foregroundColor(DesignSystem.textTertiary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.gray.opacity(0.1))
                .clipShape(Capsule())

            Spacer()
        }
    }

    // MARK: - 内容区

    @ViewBuilder
    private var contentSection: some View {
        switch explanationType {
        case .tianGan(let gan, let pillar, let shiShen):
            if let explanation = BaziExplanations.getGanExplanation(gan) {
                ganZhiContent(explanation: explanation, pillar: pillar, shiShen: shiShen, isCangGan: false)
            }

        case .cangGan(let gan, let pillar, let shiShen):
            if let explanation = BaziExplanations.getGanExplanation(gan) {
                ganZhiContent(explanation: explanation, pillar: pillar, shiShen: shiShen, isCangGan: true)
            }

        case .diZhi(let zhi, let pillar, let cangGanList):
            if let explanation = BaziExplanations.getZhiExplanation(zhi) {
                diZhiContent(explanation: explanation, pillar: pillar, cangGanList: cangGanList)
            }

        case .shiShen(let shiShen):
            if let explanation = BaziExplanations.getShiShenExplanation(shiShen) {
                shiShenContent(explanation: explanation)
            }

        case .pillar(let pillar):
            if let explanation = BaziExplanations.getPillarExplanation(pillar) {
                pillarContent(explanation: explanation)
            }
        }
    }

    // 天干内容（与地支结构一致）
    private func ganZhiContent(explanation: GanZhiExplanation, pillar: String, shiShen: String?, isCangGan: Bool) -> some View {
        let colors = WuXingColor.colors(for: explanation.wuXing)

        return VStack(alignment: .leading, spacing: 24) {
            // ──────────────────────────────
            // 一、天干标题 + 含义（合并在一个卡片里）
            // ──────────────────────────────
            VStack(alignment: .leading, spacing: 16) {
                // 标题行：大字 + 五行
                HStack(alignment: .top, spacing: 12) {
                    Text(explanation.name)
                        .font(.system(size: 48, weight: .light))
                        .foregroundColor(colors.secondary)

                    wuXingBadge(explanation.wuXing)
                        .padding(.top, 6)

                    Spacer()

                    // 藏干标识（如果是藏干）
                    if isCangGan {
                        Text("藏干")
                            .font(.system(size: 11))
                            .foregroundColor(DesignSystem.textTertiary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Capsule())
                            .padding(.top, 6)
                    }
                }

                // 含义描述
                Text(explanation.description)
                    .font(.system(size: 14))
                    .foregroundColor(DesignSystem.textPrimary)
                    .lineSpacing(5)

                // 关键词
                FlowLayout(spacing: 6) {
                    ForEach(explanation.keywords, id: \.self) { keyword in
                        Text(keyword)
                            .font(.system(size: 12))
                            .foregroundColor(DesignSystem.textSecondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.gray.opacity(0.08))
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(colors.secondary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // ──────────────────────────────
            // 二、在你命盘中的意义（天干用forYouTianGan，藏干用forYou）
            // ──────────────────────────────
            if let pillarExp = BaziExplanations.getPillarExplanation(pillar) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("在\(pillar)的意义")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(DesignSystem.textSecondary)

                    // 天干（透干）用天干解释，藏干用地支解释
                    Text(isCangGan ? pillarExp.forYou : pillarExp.forYouTianGan)
                        .font(.system(size: 14))
                        .foregroundColor(DesignSystem.textPrimary)
                        .lineSpacing(5)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DesignSystem.primaryOrange.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // ──────────────────────────────
            // 三、透干/藏干 + 十神含义（如果有十神）
            // ──────────────────────────────
            if let shiShen = shiShen {
                tianGanShiShenSection(
                    gan: explanation.name,
                    ganWuXing: explanation.wuXing,
                    shiShen: shiShen,
                    pillar: pillar,
                    isCangGan: isCangGan
                )
            }
        }
    }

    // 天干十神区块（简洁版，只显示十神详情卡片）
    private func tianGanShiShenSection(gan: String, ganWuXing: String, shiShen: String, pillar: String, isCangGan: Bool) -> some View {
        let colors = WuXingColor.colors(for: ganWuXing)

        // 根据是透干还是藏干，获取对应的解释
        let description: String? = {
            if isCangGan {
                // 藏干用地支位置的解释
                return BaziExplanations.getShiShenInPillarExplanation(shiShen: shiShen, pillar: pillar)
            } else {
                // 透干用天干位置的解释
                return BaziExplanations.getShiShenInTianGanExplanation(shiShen: shiShen, pillar: pillar)
            }
        }()

        return VStack(alignment: .leading, spacing: 10) {
            // 标题行
            HStack(spacing: 8) {
                Text(shiShen)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(colors.secondary)

                // 十神类型标签
                Text("十神")
                    .font(.system(size: 11))
                    .foregroundColor(colors.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(colors.secondary.opacity(0.15))
                    .clipShape(Capsule())

                Spacer()

                // 透干/藏干标识
                Text(isCangGan ? "藏" : "透")
                    .font(.system(size: 10))
                    .foregroundColor(isCangGan ? DesignSystem.textTertiary : colors.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(isCangGan ? Color.gray.opacity(0.08) : colors.secondary.opacity(0.1))
                    .clipShape(Capsule())
            }

            if let description = description {
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(DesignSystem.textSecondary)
                    .lineSpacing(4)
            }

            // 反面：结合柱位（透干用天干反面，藏干用柱位反面）
            let fanMianDesc: String? = isCangGan
                ? BaziExplanations.getShiShenInPillarFanMianExplanation(shiShen: shiShen, pillar: pillar)
                : BaziExplanations.getShiShenInTianGanFanMianExplanation(shiShen: shiShen, pillar: pillar)
            if let fanMianDesc = fanMianDesc {
                Text(fanMianDesc)
                    .font(.system(size: 13))
                    .foregroundColor(DesignSystem.textSecondary)
                    .lineSpacing(4)
            }
        }
        .padding(12)
        .background(colors.secondary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // 地支内容（简洁清晰的结构）
    private func diZhiContent(explanation: GanZhiExplanation, pillar: String, cangGanList: [CangGanInfo]) -> some View {
        let colors = WuXingColor.colors(for: explanation.wuXing)

        return VStack(alignment: .leading, spacing: 24) {
            // ──────────────────────────────
            // 一、地支标题 + 含义（合并在一个卡片里）
            // ──────────────────────────────
            VStack(alignment: .leading, spacing: 16) {
                // 标题行：大字 + 五行
                HStack(alignment: .top, spacing: 12) {
                    Text(explanation.name)
                        .font(.system(size: 48, weight: .light))
                        .foregroundColor(colors.secondary)

                    wuXingBadge(explanation.wuXing)
                        .padding(.top, 6)

                    Spacer()
                }

                // 含义描述
                Text(explanation.description)
                    .font(.system(size: 14))
                    .foregroundColor(DesignSystem.textPrimary)
                    .lineSpacing(5)

                // 关键词
                FlowLayout(spacing: 6) {
                    ForEach(explanation.keywords, id: \.self) { keyword in
                        Text(keyword)
                            .font(.system(size: 12))
                            .foregroundColor(DesignSystem.textSecondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.gray.opacity(0.08))
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(colors.secondary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // ──────────────────────────────
            // 二、在你命盘中的意义
            // ──────────────────────────────
            if let pillarExp = BaziExplanations.getPillarExplanation(pillar) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("在\(pillar)的意义")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(DesignSystem.textSecondary)

                    Text(pillarExp.forYou)
                        .font(.system(size: 14))
                        .foregroundColor(DesignSystem.textPrimary)
                        .lineSpacing(5)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DesignSystem.primaryOrange.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // ──────────────────────────────
            // 三、藏干（内在特质）- 用图形表达关系
            // ──────────────────────────────
            if !cangGanList.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    // 视觉化：地支包含藏干的关系图
                    diZhiCangGanDiagram(zhi: explanation.name, zhiWuXing: explanation.wuXing, cangGanList: cangGanList)

                    // 藏干详情列表
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(cangGanList, id: \.gan) { info in
                            simpleCangGanItem(info: info, pillar: pillar)
                        }
                    }
                    .padding(.top, 16)
                }
            }
        }
    }

    // 地支与藏干的关系图（视觉化表达）
    private func diZhiCangGanDiagram(zhi: String, zhiWuXing: String, cangGanList: [CangGanInfo]) -> some View {
        let zhiColors = WuXingColor.colors(for: zhiWuXing)

        return HStack(spacing: 0) {
            // 左侧：地支（外层容器）
            VStack(spacing: 4) {
                Text(zhi)
                    .font(.system(size: 28, weight: .light))
                    .foregroundColor(zhiColors.secondary)

                Text("外")
                    .font(.system(size: 10))
                    .foregroundColor(zhiColors.secondary.opacity(0.6))
            }
            .frame(width: 56, height: 56)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(zhiColors.secondary.opacity(0.3), lineWidth: 2)
                    .background(zhiColors.secondary.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            )

            // 中间：箭头
            HStack(spacing: 2) {
                Rectangle()
                    .fill(DesignSystem.textTertiary.opacity(0.3))
                    .frame(width: 20, height: 2)

                Image(systemName: "chevron.right")
                    .font(.system(size: 10))
                    .foregroundColor(DesignSystem.textTertiary.opacity(0.5))

                Text("藏")
                    .font(.system(size: 10))
                    .foregroundColor(DesignSystem.textTertiary)

                Image(systemName: "chevron.right")
                    .font(.system(size: 10))
                    .foregroundColor(DesignSystem.textTertiary.opacity(0.5))

                Rectangle()
                    .fill(DesignSystem.textTertiary.opacity(0.3))
                    .frame(width: 20, height: 2)
            }
            .padding(.horizontal, 8)

            // 右侧：藏干们（内层能量）
            HStack(spacing: 6) {
                ForEach(cangGanList, id: \.gan) { info in
                    let ganWuXing = BaziConstants.wuXing[info.gan] ?? "木"
                    let ganColors = WuXingColor.colors(for: ganWuXing)

                    VStack(spacing: 2) {
                        Text(info.gan)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(ganColors.secondary)

                        Text(info.type == "本气" ? "主" : info.type == "中气" ? "次" : "余")
                            .font(.system(size: 9))
                            .foregroundColor(ganColors.secondary.opacity(0.6))
                    }
                    .frame(width: 40, height: 40)
                    .background(ganColors.secondary.opacity(0.1))
                    .clipShape(Circle())
                }
            }

            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.gray.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // 简洁版藏干项
    private func simpleCangGanItem(info: CangGanInfo, pillar: String) -> some View {
        let ganWuXing = BaziConstants.wuXing[info.gan] ?? "木"
        let colors = WuXingColor.colors(for: ganWuXing)

        return VStack(alignment: .leading, spacing: 10) {
            // 标题行
            HStack(spacing: 8) {
                // 藏干字
                Text(info.gan)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(colors.secondary)

                // 五行标签
                Text(ganWuXing)
                    .font(.system(size: 11))
                    .foregroundColor(colors.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(colors.secondary.opacity(0.15))
                    .clipShape(Capsule())

                // 十神标签（使用五行颜色）
                Text(info.shiShen)
                    .font(.system(size: 11))
                    .foregroundColor(colors.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(colors.secondary.opacity(0.15))
                    .clipShape(Capsule())

                Spacer()

                // 气类型标签
                Text(info.type)
                    .font(.system(size: 10))
                    .foregroundColor(info.type == "本气" ? colors.secondary : DesignSystem.textTertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(info.type == "本气" ? colors.secondary.opacity(0.1) : Color.gray.opacity(0.08))
                    .clipShape(Capsule())
            }

            if let description = BaziExplanations.getShiShenInPillarExplanation(shiShen: info.shiShen, pillar: pillar) {
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(DesignSystem.textSecondary)
                    .lineSpacing(4)
            }

            if let fanMianDesc = BaziExplanations.getShiShenInPillarFanMianExplanation(shiShen: info.shiShen, pillar: pillar) {
                Text(fanMianDesc)
                    .font(.system(size: 13))
                    .foregroundColor(DesignSystem.textSecondary)
                    .lineSpacing(4)
            }
        }
        .padding(12)
        .background(colors.secondary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // 十神内容（正反两面同逻辑、同字号同样式，无「正面/反面」标题，无灰底）
    private func shiShenContent(explanation: ShiShenExplanation) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(explanation.description)
                .font(.system(size: 16))
                .foregroundColor(DesignSystem.textPrimary)
                .lineSpacing(6)

            keywordsSection(keywords: explanation.keywords)

            if let fanMianDesc = BaziExplanations.getShiShenFanMianDescription(explanation.name) {
                Text(fanMianDesc)
                    .font(.system(size: 16))
                    .foregroundColor(DesignSystem.textPrimary)
                    .lineSpacing(6)

                if let fanMianBrief = BaziExplanations.getShiShenFanMian(explanation.name) {
                    keywordsSection(keywords: fanMianBrief.split(separator: "、").map { String($0) })
                }
            }
        }
    }

    // 柱位内容
    private func pillarContent(explanation: PillarExplanation) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // 描述
            Text(explanation.description)
                .font(.system(size: 16))
                .foregroundColor(DesignSystem.textPrimary)
                .lineSpacing(6)

            // 代表事物
            VStack(alignment: .leading, spacing: 12) {
                Text("代表人事")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(DesignSystem.textSecondary)

                FlowLayout(spacing: 8) {
                    ForEach(explanation.represents, id: \.self) { item in
                        Text(item)
                            .font(.system(size: 14))
                            .foregroundColor(DesignSystem.textPrimary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.gray.opacity(0.08))
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    // MARK: - 辅助组件

    private func wuXingBadge(_ wuXing: String) -> some View {
        let colors = WuXingColor.colors(for: wuXing)
        return Text(wuXing)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(colors.secondary)
            .clipShape(Capsule())
    }

    private func keywordsSection(keywords: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("特点")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(DesignSystem.textSecondary)

            FlowLayout(spacing: 8) {
                ForEach(keywords, id: \.self) { keyword in
                    Text(keyword)
                        .font(.system(size: 14))
                        .foregroundColor(DesignSystem.textPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.08))
                        .clipShape(Capsule())
                }
            }
        }
    }

}

// MARK: - 辅助扩展

extension ExplanationType {
    var isCangGan: Bool {
        if case .cangGan = self { return true }
        return false
    }
}


// MARK: - FlowLayout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            totalWidth = max(totalWidth, currentX - spacing)
            totalHeight = currentY + lineHeight
        }

        return (CGSize(width: totalWidth, height: totalHeight), positions)
    }
}
