import MiniMaxChatKit
import SwiftUI

/// 助手页顶部「当前命盘」区块用的展示数据（与 cycle 中单独列出周期信息类似）。
struct AssistantPanUIDisplay: Equatable {
    var isEmpty: Bool
    /// 副标题：已保存名称，或「最近一次排盘」
    var subtitle: String?
    /// 角标，如「我的」
    var badge: String?
    var birthLine: String?
    var pillarsLine: String?
    var dayMasterLine: String?
    var emptyHint: String?

    static let empty = AssistantPanUIDisplay(
        isEmpty: true,
        subtitle: nil,
        badge: nil,
        birthLine: nil,
        pillarsLine: nil,
        dayMasterLine: nil,
        emptyHint: "请先在「排盘」输入生辰并查看结果，或保存命盘后回到此处。"
    )
}

extension MingPanStore {
    /// 供助手顶部卡片展示：优先已保存的当前选用命盘，否则解析最近一次排盘摘要。
    func assistantPanUIDisplay() -> AssistantPanUIDisplay {
        if let id = resolvedAssistantMingPanId(),
           let r = records.first(where: { $0.id == id }) {
            let isSelf = (selfMingPanId == r.id)
            let badge: String? = isSelf ? "我的" : nil
            let wx = BaziConstants.wuXing[r.dayGan] ?? "木"
            let birthLine =
                "\(r.birthYear)年\(r.birthMonth)月\(r.birthDay)日 \(r.birthHour):\(String(format: "%02d", r.birthMinute)) \(r.gender == "female" ? "女" : "男")"
            let pillarsLine =
                "\(r.yearGan)\(r.yearZhi)　\(r.monthGan)\(r.monthZhi)　\(r.dayGan)\(r.dayZhi)　\(r.hourGan)\(r.hourZhi)"
            let dayMasterLine = "\(r.dayGan)（\(wx)）"
            return AssistantPanUIDisplay(
                isEmpty: false,
                subtitle: r.displayName,
                badge: badge,
                birthLine: birthLine,
                pillarsLine: pillarsLine,
                dayMasterLine: dayMasterLine,
                emptyHint: nil
            )
        }

        let raw = BaziAssistantContext.storedPanSummaryFromDefaults()
        if raw.isEmpty {
            return .empty
        }
        let parsed = Self.parseAssistantSummaryLines(raw)
        return AssistantPanUIDisplay(
            isEmpty: false,
            subtitle: "最近一次排盘",
            badge: nil,
            birthLine: parsed.birth,
            pillarsLine: parsed.pillars,
            dayMasterLine: parsed.dayMaster,
            emptyHint: nil
        )
    }

    private static func parseAssistantSummaryLines(_ summary: String) -> (birth: String?, pillars: String?, dayMaster: String?) {
        var birth: String?
        var pillars: String?
        var dayMaster: String?
        for line in summary.components(separatedBy: .newlines) {
            let t = line.trimmingCharacters(in: .whitespaces)
            if t.hasPrefix("出生：") {
                birth = String(t.dropFirst(3))
            } else if t.hasPrefix("四柱：") {
                pillars = String(t.dropFirst(3))
            } else if t.hasPrefix("日主：") {
                dayMaster = String(t.dropFirst(3))
            }
        }
        return (birth, pillars, dayMaster)
    }
}

// MARK: - 视图（与助手气泡同色底、可折叠；公历不含时辰，避免与时柱重复）

struct AssistantCurrentPanCard: View {
    let display: AssistantPanUIDisplay
    let palette: MiniMaxChatPalette
    @Binding var isExpanded: Bool

    private var dayMasterWuXing: String? {
        guard let line = display.dayMasterLine else { return nil }
        guard let open = line.range(of: "（"),
              let close = line.range(of: "）", range: open.upperBound..<line.endIndex)
        else { return nil }
        let inner = String(line[open.upperBound..<close.lowerBound])
        return ["木", "火", "土", "金", "水"].contains(inner) ? inner : nil
    }

    /// 公历只保留「年月日 + 性别」；时辰已在时柱体现，避免与四柱重复展示时间信息。
    private func birthLineSansTime(_ raw: String?) -> String? {
        guard let raw = raw, !raw.isEmpty else { return nil }
        let parts = raw.split(separator: " ").map(String.init)
        guard let last = parts.last, last == "男" || last == "女" else { return raw }
        guard parts.count >= 3 else { return raw }
        let timePart = parts[parts.count - 2]
        guard timePart.contains(":") else { return raw }
        return "\(parts[0]) \(last)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if display.isEmpty {
                header
                emptyContent
            } else {
                collapsibleHeader
                if isExpanded {
                    VStack(alignment: .leading, spacing: 8) {
                        infoRow(title: "出生", value: birthLineSansTime(display.birthLine))
                        infoRow(title: "四柱", value: display.pillarsLine)
                        dayMasterRow(value: display.dayMasterLine, wuxing: dayMasterWuXing)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .padding(12)
        .background(palette.cardBackgroundSolid)
        .clipShape(RoundedRectangle(cornerRadius: MiniMaxChatLayout.bubbleCornerRadius))
        .shadow(color: palette.textPrimary.opacity(0.06), radius: 4, x: 0, y: 2)
    }

    private var panTitleColumn: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("当前命盘")
                .font(.system(size: 11, weight: .light))
                .foregroundStyle(DesignSystem.textTertiary)
                .tracking(1)
            if let sub = display.subtitle, !sub.isEmpty {
                Text(sub)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(DesignSystem.textPrimary)
                    .lineLimit(1)
            }
        }
    }

    @ViewBuilder
    private var panBadge: some View {
        if let badge = display.badge {
            Text(badge)
                .font(.system(size: 12, weight: .medium))
                .tracking(0.5)
                .foregroundStyle(DesignSystem.primaryOrange)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(DesignSystem.primaryOrange.opacity(0.08))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(DesignSystem.primaryOrange.opacity(0.35), lineWidth: 1)
                )
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            AppLogo(size: 28)
            panTitleColumn
            Spacer(minLength: 8)
            panBadge
        }
    }

    private var collapsibleHeader: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.toggle()
            }
        } label: {
            HStack(alignment: .center, spacing: 10) {
                AppLogo(size: 26)
                panTitleColumn
                Spacer(minLength: 8)
                panBadge
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(palette.textSecondary)
                    .accessibilityLabel(isExpanded ? "收起" : "展开")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var emptyContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "circle.hexagongrid")
                    .font(.system(size: 18, weight: .light))
                    .foregroundStyle(DesignSystem.primaryOrange.opacity(0.85))
                Text("尚未同步命盘")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(DesignSystem.textSecondary)
            }

            Text(display.emptyHint ?? "")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(DesignSystem.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func infoRow(title: String, value: String?) -> some View {
        Group {
            if let value, !value.isEmpty {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(title)
                        .font(.system(size: 12, weight: .light))
                        .foregroundStyle(DesignSystem.textTertiary)
                        .tracking(1)
                        .frame(width: 40, alignment: .leading)
                    Text(value)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(DesignSystem.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func dayMasterRow(value: String?, wuxing: String?) -> some View {
        Group {
            if let value, !value.isEmpty {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text("日主")
                        .font(.system(size: 12, weight: .light))
                        .foregroundStyle(DesignSystem.textTertiary)
                        .tracking(1)
                        .frame(width: 40, alignment: .leading)

                    if let wx = wuxing {
                        let colors = WuXingColor.colors(for: wx)
                        Text(value)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(colors.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(colors.primary.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cornerRadiusSmall))
                    } else {
                        Text(value)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(DesignSystem.textPrimary)
                    }
                }
            }
        }
    }
}
