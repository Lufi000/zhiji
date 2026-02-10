import SwiftUI

// MARK: - 十神解读报告视图
// TODO: 本视图暂无展示入口。若产品需要「十神解读」全屏报告，需在命盘页增加入口（如按钮），构建 ShiShenReport 后 present 本视图。

struct ShiShenReportView: View {
    let report: ShiShenReport
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 日主概述
                    dayMasterSection

                    // 四柱解读
                    ForEach(report.pillarAnalysisList, id: \.pillarName) { pillar in
                        pillarSection(pillar)
                    }

                    // 格局总结
                    if let strongest = report.summary.strongestShiShen {
                        summarySection(strongest: strongest)
                    }

                    // 底部留白
                    Spacer()
                        .frame(height: 80)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
            }
            .background(Color(UIColor.systemBackground))
            .navigationTitle("十神解读")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                    .foregroundColor(DesignSystem.textPrimary)
                }
            }
        }
    }

    // MARK: - 日主概述

    private var dayMasterSection: some View {
        let colors = WuXingColor.colors(for: report.dayMaster.wuXing)

        return VStack(alignment: .leading, spacing: 16) {
            // 标题
            HStack(spacing: 12) {
                Text("日主")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(DesignSystem.textSecondary)

                HStack(spacing: 6) {
                    Text(report.dayMaster.gan)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(colors.secondary)

                    Text(report.dayMaster.wuXing)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(colors.secondary)
                        .clipShape(Capsule())
                }

                Spacer()
            }

            // 描述
            Text(report.dayMaster.description)
                .font(.system(size: 15))
                .foregroundColor(DesignSystem.textPrimary)
                .lineSpacing(6)

            // 喜用神
            if let xiYong = report.dayMaster.xiYong, !xiYong.xi.isEmpty {
                HStack(spacing: 16) {
                    HStack(spacing: 6) {
                        Text("喜")
                            .font(.system(size: 12))
                            .foregroundColor(DesignSystem.textSecondary)
                        ForEach(xiYong.xi, id: \.self) { wx in
                            wuXingBadge(wx, filled: true)
                        }
                    }

                    HStack(spacing: 6) {
                        Text("忌")
                            .font(.system(size: 12))
                            .foregroundColor(DesignSystem.textSecondary)
                        ForEach(xiYong.ji, id: \.self) { wx in
                            wuXingBadge(wx, filled: false)
                        }
                    }
                }
            }
            if let tiaoHou = report.dayMaster.tiaoHou,
               let th = tiaoHou.tiaoHou,
               let reason = tiaoHou.reason {
                HStack(spacing: 4) {
                    Text("调候")
                        .font(.system(size: 11))
                        .foregroundColor(DesignSystem.textTertiary)
                    wuXingBadge(th, filled: true)
                    Text(reason)
                        .font(.system(size: 10))
                        .foregroundColor(DesignSystem.textTertiary)
                }
            }
        }
        .padding(24)
        .background(colors.secondary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - 柱位分析

    private func pillarSection(_ pillar: PillarAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题
            HStack {
                Text(pillar.pillarName)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(DesignSystem.textPrimary)

                Text(pillar.ageRange)
                    .font(.system(size: 12))
                    .foregroundColor(DesignSystem.textTertiary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.gray.opacity(0.08))
                    .clipShape(Capsule())

                Spacer()
            }

            // 天干解读
            if let tianGan = pillar.tianGan {
                tianGanCard(tianGan, pillarPrefix: String(pillar.pillarName.prefix(1)))
            }

            // 地支藏干解读
            diZhiCard(pillar.diZhi, pillarPrefix: String(pillar.pillarName.prefix(1)))
        }
    }

    private func tianGanCard(_ tianGan: GanAnalysis, pillarPrefix: String) -> some View {
        let colors = WuXingColor.colors(for: tianGan.wuXing)

        return VStack(alignment: .leading, spacing: 10) {
            // 标题行
            HStack(spacing: 8) {
                Text("\(pillarPrefix)干")
                    .font(.system(size: 11))
                    .foregroundColor(DesignSystem.textTertiary)

                Text(tianGan.gan)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(colors.secondary)

                Text(tianGan.wuXing)
                    .font(.system(size: 11))
                    .foregroundColor(colors.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(colors.secondary.opacity(0.15))
                    .clipShape(Capsule())

                if let shiShen = tianGan.shiShen {
                    Text(shiShen)
                        .font(.system(size: 11))
                        .foregroundColor(colors.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(colors.secondary.opacity(0.15))
                        .clipShape(Capsule())

                    Text("透")
                        .font(.system(size: 9))
                        .foregroundColor(colors.secondary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(colors.secondary.opacity(0.1))
                        .clipShape(Capsule())
                }

                Spacer()
            }

            // 十神解读
            if let desc = tianGan.shiShenDescription {
                Text(desc)
                    .font(.system(size: 14))
                    .foregroundColor(DesignSystem.textPrimary)
                    .lineSpacing(5)
            }
        }
        .padding(12)
        .background(colors.secondary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func diZhiCard(_ diZhi: ZhiAnalysis, pillarPrefix: String) -> some View {
        let zhiColors = WuXingColor.colors(for: diZhi.wuXing)

        return VStack(alignment: .leading, spacing: 12) {
            // 地支标题
            HStack(spacing: 8) {
                Text("\(pillarPrefix)支")
                    .font(.system(size: 11))
                    .foregroundColor(DesignSystem.textTertiary)

                Text(diZhi.zhi)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(zhiColors.secondary)

                Text(diZhi.wuXing)
                    .font(.system(size: 11))
                    .foregroundColor(zhiColors.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(zhiColors.secondary.opacity(0.15))
                    .clipShape(Capsule())

                Spacer()
            }

            // 藏干列表
            ForEach(diZhi.cangGanList, id: \.gan) { cangGan in
                cangGanCard(cangGan)
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func cangGanCard(_ cangGan: CangGanAnalysis) -> some View {
        let colors = WuXingColor.colors(for: cangGan.wuXing)

        return VStack(alignment: .leading, spacing: 8) {
            // 藏干标题行
            HStack(spacing: 6) {
                Text(cangGan.gan)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(colors.secondary)

                Text(cangGan.wuXing)
                    .font(.system(size: 10))
                    .foregroundColor(colors.secondary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(colors.secondary.opacity(0.15))
                    .clipShape(Capsule())

                Text(cangGan.shiShen)
                    .font(.system(size: 10))
                    .foregroundColor(colors.secondary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(colors.secondary.opacity(0.15))
                    .clipShape(Capsule())

                Spacer()

                Text(cangGan.type)
                    .font(.system(size: 9))
                    .foregroundColor(cangGan.type == "本气" ? colors.secondary : DesignSystem.textTertiary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(cangGan.type == "本气" ? colors.secondary.opacity(0.1) : Color.gray.opacity(0.08))
                    .clipShape(Capsule())
            }

            // 解读内容
            if !cangGan.description.isEmpty {
                Text(cangGan.description)
                    .font(.system(size: 13))
                    .foregroundColor(DesignSystem.textSecondary)
                    .lineSpacing(4)
            }
        }
        .padding(10)
        .background(colors.secondary.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - 格局总结

    private func summarySection(strongest: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("格局特点")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(DesignSystem.textPrimary)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text("最旺十神")
                        .font(.system(size: 12))
                        .foregroundColor(DesignSystem.textTertiary)

                    Text(strongest)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(DesignSystem.primaryOrange)
                }

                if let desc = report.summary.strongestDescription {
                    Text(desc)
                        .font(.system(size: 14))
                        .foregroundColor(DesignSystem.textPrimary)
                        .lineSpacing(5)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DesignSystem.primaryOrange.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - 辅助组件

    private func wuXingBadge(_ wuXing: String, filled: Bool) -> some View {
        let colors = WuXingColor.colors(for: wuXing)

        return Group {
            if filled {
                Text(wuXing)
                    .font(.system(size: 12))
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(colors.secondary)
                    .clipShape(Circle())
            } else {
                Text(wuXing)
                    .font(.system(size: 12))
                    .foregroundColor(colors.secondary)
                    .frame(width: 24, height: 24)
                    .background(
                        Circle()
                            .stroke(colors.secondary, lineWidth: 1.5)
                    )
            }
        }
    }
}
