import SwiftUI
import StoreKit

// MARK: - 流年解析视图

struct LiuNianAnalysisView: View {
    let year: Int
    let riGan: String
    let bazi: Bazi
    let birth: (year: Int, month: Int, day: Int, hour: Int)
    let gender: String

    init(year: Int, riGan: String, bazi: Bazi, birth: (year: Int, month: Int, day: Int, hour: Int), gender: String) {
        self.year = year
        self.riGan = riGan
        self.bazi = bazi
        self.birth = birth
        self.gender = gender
    }

    // 检查当前命盘是否已解锁
    private var isUnlocked: Bool {
        StoreManager.shared.isLiuNianUnlocked(
            year: birth.year,
            month: birth.month,
            day: birth.day,
            hour: birth.hour,
            gender: gender
        )
    }

    // 获取流年干支
    private var liuNianGanZhi: (gan: String, zhi: String) {
        let g = (year - 1984) % 10
        let z = (year - 1984) % 12
        return (BaziConstants.tianGan[(g + 10) % 10], BaziConstants.diZhi[(z + 12) % 12])
    }

    // 流年天干五行
    private var liuNianGanWuXing: String {
        BaziConstants.wuXing[liuNianGanZhi.gan] ?? "木"
    }

    // 流年地支五行
    private var liuNianZhiWuXing: String {
        BaziConstants.wuXing[liuNianGanZhi.zhi] ?? "木"
    }

    // 流年与日主的关系
    private var ganRelation: String {
        getShiShen(riGan: riGan, targetGan: liuNianGanZhi.gan)
    }

    // 分析流年与命局的关系
    private func analyzeRelations() -> [String] {
        var results: [String] = []
        let ganZhi = liuNianGanZhi

        // 检查天干合
        let tianGanHe: [String: String] = [
            "甲己": "土", "乙庚": "金", "丙辛": "水", "丁壬": "木", "戊癸": "火"
        ]

        // 检查与四柱天干的合
        let pillars = [
            ("年", bazi.year), ("月", bazi.month), ("日", bazi.day), ("时", bazi.hour)
        ]

        for (name, pillar) in pillars {
            let pair1 = "\(ganZhi.gan)\(pillar.gan)"
            let pair2 = "\(pillar.gan)\(ganZhi.gan)"

            if let heWuXing = tianGanHe[pair1] ?? tianGanHe[pair2] {
                results.append("流年\(ganZhi.gan)与\(name)柱\(pillar.gan)相合化\(heWuXing)")
            }
        }

        // 检查地支六冲
        let diZhiChong: [String: String] = [
            "子午": "水火相冲", "丑未": "土土相冲", "寅申": "木金相冲",
            "卯酉": "木金相冲", "辰戌": "土土相冲", "巳亥": "火水相冲"
        ]

        for (name, pillar) in pillars {
            let pair1 = "\(ganZhi.zhi)\(pillar.zhi)"
            let pair2 = "\(pillar.zhi)\(ganZhi.zhi)"

            if let chongDesc = diZhiChong[pair1] ?? diZhiChong[pair2] {
                results.append("流年\(ganZhi.zhi)与\(name)柱\(pillar.zhi)相冲（\(chongDesc)）")
            }
        }

        // 检查地支六合
        let diZhiHe: [String: String] = [
            "子丑": "土", "寅亥": "木", "卯戌": "火",
            "辰酉": "金", "巳申": "水", "午未": "火"
        ]

        for (name, pillar) in pillars {
            let pair1 = "\(ganZhi.zhi)\(pillar.zhi)"
            let pair2 = "\(pillar.zhi)\(ganZhi.zhi)"

            if let heWuXing = diZhiHe[pair1] ?? diZhiHe[pair2] {
                results.append("流年\(ganZhi.zhi)与\(name)柱\(pillar.zhi)六合化\(heWuXing)")
            }
        }

        return results
    }

    // 生成流年运势总结
    private func generateSummary() -> String {
        let ganShiShen = ganRelation

        switch ganShiShen {
        case "比肩", "劫财":
            return "此年人际关系活跃，易有竞争或合作机会。注意理财，避免冲动消费。"
        case "食神":
            return "此年思维活跃，创意丰富，适合学习新技能或发展兴趣爱好。"
        case "伤官":
            return "此年表现欲强，宜发挥才华。但需注意言行，避免与人冲突。"
        case "偏财":
            return "此年财运活跃，可能有意外收入。适合投资但需谨慎。"
        case "正财":
            return "此年正财运稳定，工作收入有保障。适合稳健理财。"
        case "七杀":
            return "此年压力较大，需注意健康和人际关系。宜积极面对挑战。"
        case "正官":
            return "此年贵人运佳，事业有上升机会。宜守规矩、重诚信。"
        case "偏印":
            return "此年学习运佳，适合进修或研究。但需注意身体健康。"
        case "正印":
            return "此年有长辈或贵人相助，学业事业皆顺。宜感恩回报。"
        default:
            return "此年运势平稳，宜稳中求进。"
        }
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                // 标题
                HStack {
                    Text("\(year)年流年解析")
                        .font(.system(size: 15, weight: .light))
                        .foregroundColor(DesignSystem.textPrimary)
                        .tracking(2)

                    Spacer()

                    // 流年干支标签
                    HStack(spacing: 4) {
                        Text(liuNianGanZhi.gan)
                            .foregroundColor(WuXingColor.colors(for: liuNianGanWuXing).primary)
                        Text(liuNianGanZhi.zhi)
                            .foregroundColor(WuXingColor.colors(for: liuNianZhiWuXing).primary)
                    }
                    .font(.system(size: 16, weight: .medium))
                }

                if isUnlocked {
                    // 已解锁：显示完整解析
                    unlockedContent
                } else {
                    // 未解锁：显示付费提示
                    paywallContent
                }
            }
            .padding(20)
        }
    }

    // MARK: - 已解锁内容
    private var unlockedContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 十神关系
            HStack(spacing: 8) {
                Text("十神")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(DesignSystem.textSecondary)

                Text(ganRelation)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(DesignSystem.primaryOrange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(DesignSystem.primaryOrange.opacity(0.1))
                    )
            }

            Divider()

            // 命局关系分析
            let relations = analyzeRelations()
            if !relations.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("命局互动")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(DesignSystem.textSecondary)

                    ForEach(relations, id: \.self) { relation in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(DesignSystem.primaryOrange)
                                .frame(width: 4, height: 4)
                            Text(relation)
                                .font(.system(size: 13, weight: .light))
                                .foregroundColor(DesignSystem.textPrimary)
                        }
                    }
                }

                Divider()
            }

            // 运势总结
            VStack(alignment: .leading, spacing: 6) {
                Text("运势提示")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(DesignSystem.textSecondary)

                Text(generateSummary())
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(DesignSystem.textPrimary)
                    .lineSpacing(4)
            }
        }
    }

    // MARK: - 付费墙内容
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""

    private var baziIdentifier: BaziIdentifier {
        BaziIdentifier(
            year: birth.year,
            month: birth.month,
            day: birth.day,
            hour: birth.hour,
            gender: gender
        )
    }

    private var paywallContent: some View {
        VStack(spacing: 16) {
            // 锁定提示
            HStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 18))
                    .foregroundColor(DesignSystem.primaryOrange)

                VStack(alignment: .leading, spacing: 4) {
                    Text("解锁此命盘流年解析")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(DesignSystem.textPrimary)

                    Text("查看十神关系、命局互动、运势提示")
                        .font(.system(size: 12, weight: .light))
                        .foregroundColor(DesignSystem.textSecondary)
                }

                Spacer()
            }

            // 购买按钮
            HStack(spacing: 12) {
                if let product = StoreManager.shared.liuNianProduct {
                    Button(action: {
                        Task {
                            await purchase()
                        }
                    }) {
                        HStack {
                            if isPurchasing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.7)
                            } else {
                                Text("解锁 · \(product.displayPrice)")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(height: 36)
                        .padding(.horizontal, 20)
                        .background(
                            LinearGradient(
                                colors: [DesignSystem.primaryOrange, DesignSystem.primaryOrange.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .disabled(isPurchasing)
                } else if StoreManager.shared.isLoading {
                    ProgressView()
                        .frame(height: 36)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(DesignSystem.primaryOrange.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(DesignSystem.primaryOrange.opacity(0.2), lineWidth: 1)
                )
        )
        .alert("购买失败", isPresented: $showError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private func purchase() async {
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await StoreManager.shared.purchaseLiuNianAnalysis(for: baziIdentifier)
            if !result.isSuccess {
                // 用户取消或等待中，不显示错误
            }
        } catch {
            errorMessage = "购买过程中出现错误，请稍后重试"
            showError = true
        }
    }
}
