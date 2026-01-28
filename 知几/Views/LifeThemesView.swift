import SwiftUI

// MARK: - 人生主题解读视图

/// 把专业的十神配置翻译成用户关心的人生主题
struct LifeThemesView: View {
    let bazi: Bazi
    let gender: String

    private var analyzer: LifeThemesAnalyzer {
        LifeThemesAnalyzer(bazi: bazi, gender: gender)
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                // 标题
                Text("人生主题")
                    .font(.system(size: 15, weight: .light))
                    .foregroundColor(DesignSystem.textPrimary)
                    .tracking(2)

                // 主题卡片列表
                VStack(spacing: 12) {
                    ForEach(analyzer.themes, id: \.title) { theme in
                        ThemeCard(theme: theme)
                    }
                }
            }
            .padding(20)
        }
    }
}

// MARK: - 主题卡片

private struct ThemeCard: View {
    let theme: LifeTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 标题行
            HStack(spacing: 8) {
                Text(theme.icon)
                    .font(.system(size: 16))

                Text(theme.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(DesignSystem.textPrimary)

                Spacer()

                // 强度标签
                Text(theme.strength)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(strengthColor(theme.strength))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(strengthColor(theme.strength).opacity(0.12))
                    .clipShape(Capsule())
            }

            // 解读内容
            Text(theme.description)
                .font(.system(size: 13, weight: .light))
                .foregroundColor(DesignSystem.textSecondary)
                .lineSpacing(4)

            // 关键词
            if !theme.keywords.isEmpty {
                HStack(spacing: 6) {
                    ForEach(theme.keywords, id: \.self) { keyword in
                        Text(keyword)
                            .font(.system(size: 10, weight: .light))
                            .foregroundColor(DesignSystem.textTertiary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.08))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(14)
        .background(Color.gray.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func strengthColor(_ strength: String) -> Color {
        switch strength {
        case "突出": return DesignSystem.primaryOrange
        case "明显": return WuXingColor.grassColor
        case "一般": return DesignSystem.textSecondary
        case "较弱": return WuXingColor.waveColor
        default: return DesignSystem.textTertiary
        }
    }
}

// MARK: - 人生主题数据模型

struct LifeTheme {
    let icon: String
    let title: String
    let description: String
    let keywords: [String]
    let strength: String  // 突出、明显、一般、较弱
}

// MARK: - 人生主题分析器

struct LifeThemesAnalyzer {
    let bazi: Bazi
    let gender: String

    private var shiShenResult: ShiShenResult {
        ShiShenAnalyzer(bazi: bazi).analyze()
    }

    private var riGan: String { bazi.day.gan }
    private var riZhi: String { bazi.day.zhi }

    /// 生成所有人生主题
    var themes: [LifeTheme] {
        [
            careerTheme,
            relationshipTheme,
            wealthTheme,
            learningTheme
        ]
    }

    // MARK: - 事业主题

    private var careerTheme: LifeTheme {
        let guanShaScore = getShiShenScore("正官") + getShiShenScore("七杀")
        let shiShangScore = getShiShenScore("食神") + getShiShenScore("伤官")
        let biJieScore = getShiShenScore("比肩") + getShiShenScore("劫财")

        var description = ""
        var keywords: [String] = []
        var strength = "一般"

        // 分析事业类型
        if guanShaScore > shiShangScore && guanShaScore > biJieScore {
            // 官杀旺：适合体制内、管理
            if getShiShenScore("正官") > getShiShenScore("七杀") {
                description = "你适合在规范的环境中发展，如企业管理、公务员、专业岗位。做事有责任心，容易得到上级认可。"
                keywords = ["稳定发展", "体制内", "管理岗"]
            } else {
                description = "你有很强的进取心和魄力，适合有挑战性的工作，如创业、销售、竞技类行业。压力越大越能激发潜力。"
                keywords = ["挑战型", "竞争环境", "领导力"]
            }
            strength = guanShaScore > 3 ? "突出" : "明显"
        } else if shiShangScore > guanShaScore && shiShangScore > biJieScore {
            // 食伤旺：适合创意、技术
            if getShiShenScore("食神") > getShiShenScore("伤官") {
                description = "你有天生的才华和艺术细胞，适合创意、教育、餐饮等行业。工作中追求内心满足感，不喜欢被约束。"
                keywords = ["创意型", "自由职业", "艺术"]
            } else {
                description = "你思维活跃、创新能力强，适合技术研发、内容创作、咨询等需要独特见解的工作。敢于挑战权威。"
                keywords = ["创新型", "技术流", "独立思考"]
            }
            strength = shiShangScore > 3 ? "突出" : "明显"
        } else if biJieScore > 2 {
            // 比劫旺：适合合伙、自主
            description = "你独立性强，不喜欢被人管，适合自己创业或与朋友合伙。竞争意识强，在同行中能脱颖而出。"
            keywords = ["创业型", "合伙人", "独立自主"]
            strength = biJieScore > 3 ? "突出" : "明显"
        } else {
            description = "你的事业发展比较均衡，没有特别突出的倾向。建议根据自己的兴趣和机遇选择方向。"
            keywords = ["均衡型", "灵活发展"]
        }

        return LifeTheme(
            icon: "💼",
            title: "事业特质",
            description: description,
            keywords: keywords,
            strength: strength
        )
    }

    // MARK: - 感情主题

    private var relationshipTheme: LifeTheme {
        // 日支十神代表配偶宫
        let riZhiShiShen = getZhiShiShen(riGan: riGan, zhi: riZhi)

        // 配偶星：男看财，女看官
        let spouseStarScore: Double
        let spouseStarName: String
        if gender == "男" {
            spouseStarScore = getShiShenScore("正财") + getShiShenScore("偏财")
            spouseStarName = "财星"
        } else {
            spouseStarScore = getShiShenScore("正官") + getShiShenScore("七杀")
            spouseStarName = "官星"
        }

        var description = ""
        var keywords: [String] = []
        var strength = "一般"

        // 根据日支十神分析
        switch riZhiShiShen {
        case "比肩":
            description = "你的另一半性格独立、有主见，你们是平等的伙伴关系。婚姻中各自保有独立空间，互不依附。"
            keywords = ["平等关系", "独立伴侣", "互相尊重"]
        case "劫财":
            description = "你的另一半花钱可能比较大方，有竞争意识。感情中需要在金钱观和生活方式上多沟通。"
            keywords = ["个性伴侣", "需要沟通", "互相包容"]
        case "食神":
            description = "你的另一半温柔体贴、懂生活情趣，会把家庭照顾得很好。婚姻生活和谐温馨，有口福。"
            keywords = ["温馨家庭", "生活情趣", "相处舒适"]
        case "伤官":
            description = "你的另一半聪明有个性、思想前卫，可能从事创意工作。感情中需要相互包容各自的独特想法。"
            keywords = ["个性伴侣", "思想碰撞", "创意生活"]
        case "正财":
            description = "你的另一半务实、会持家，家庭财务管理得当。婚姻关系稳定踏实，是可靠的人生伴侣。"
            keywords = ["稳定婚姻", "会持家", "踏实可靠"]
        case "偏财":
            description = "你的另一半善于社交、有商业头脑。感情生活丰富多彩，但需要注意感情的专一稳定。"
            keywords = ["社交能力", "多彩生活", "需要专一"]
        case "正官":
            description = "你的另一半正派可靠、有责任心，可能是公职人员或管理者。婚姻关系正式稳定。"
            keywords = ["正派可靠", "有责任心", "稳定关系"]
        case "七杀":
            description = "你的另一半性格强势、事业心重，很有魄力。婚姻中需要学会沟通和适当退让。"
            keywords = ["强势伴侣", "事业心重", "需要沟通"]
        case "正印":
            description = "你的另一半善良有文化、懂得关心人，像长辈一样照顾你。婚姻有精神上的默契。"
            keywords = ["贴心伴侣", "精神默契", "相互关爱"]
        case "偏印":
            description = "你的另一半思想独特、有特殊才能，可能从事研究或技术工作。婚姻注重精神层面的交流。"
            keywords = ["独特伴侣", "精神交流", "深度理解"]
        default:
            description = "你的感情生活需要综合其他因素来分析。"
            keywords = []
        }

        // 根据配偶星强弱补充
        if spouseStarScore > 3 {
            strength = "突出"
            description += "命中\(spouseStarName)较旺，感情机会较多。"
        } else if spouseStarScore > 1.5 {
            strength = "明显"
        } else if spouseStarScore < 0.5 {
            strength = "较弱"
            description += "命中\(spouseStarName)较弱，感情上可能需要更多主动。"
        }

        return LifeTheme(
            icon: "💕",
            title: "感情特质",
            description: description,
            keywords: keywords,
            strength: strength
        )
    }

    // MARK: - 财富主题

    private var wealthTheme: LifeTheme {
        let zhengCaiScore = getShiShenScore("正财")
        let pianCaiScore = getShiShenScore("偏财")
        let totalCaiScore = zhengCaiScore + pianCaiScore

        var description = ""
        var keywords: [String] = []
        var strength = "一般"

        if totalCaiScore > 3 {
            strength = "突出"
            if zhengCaiScore > pianCaiScore {
                description = "你的正财运较强，适合通过稳定工作、踏实经营来积累财富。理财能力强，善于管理钱财。"
                keywords = ["稳定收入", "善于理财", "踏实积累"]
            } else {
                description = "你的偏财运较强，有投资眼光和商业头脑。可能通过投资、生意获得意外收入，但需注意风险。"
                keywords = ["投资眼光", "商业头脑", "注意风险"]
            }
        } else if totalCaiScore > 1.5 {
            strength = "明显"
            description = "你有一定的求财能力，财运中等偏上。建议稳中求进，不宜过于冒险。"
            keywords = ["中上财运", "稳中求进"]
        } else {
            strength = "较弱"
            description = "命中财星较弱，不宜把赚钱作为人生第一目标。可以通过提升自身能力（印星）来间接改善财运。"
            keywords = ["能力为先", "间接求财", "重视积累"]
        }

        // 食伤生财
        let shiShangScore = getShiShenScore("食神") + getShiShenScore("伤官")
        if shiShangScore > 2 && totalCaiScore > 1 {
            description += "你有「食伤生财」的格局，可以通过才华、技能来赚钱。"
            keywords.append("才华变现")
        }

        return LifeTheme(
            icon: "💰",
            title: "财富特质",
            description: description,
            keywords: keywords,
            strength: strength
        )
    }

    // MARK: - 学习成长主题

    private var learningTheme: LifeTheme {
        let zhengYinScore = getShiShenScore("正印")
        let pianYinScore = getShiShenScore("偏印")
        let totalYinScore = zhengYinScore + pianYinScore

        var description = ""
        var keywords: [String] = []
        var strength = "一般"

        if totalYinScore > 3 {
            strength = "突出"
            if zhengYinScore > pianYinScore {
                description = "你学习能力很强，容易得到长辈和贵人的帮助。适合走学术路线，考试运不错，有文化修养。"
                keywords = ["学霸体质", "贵人运好", "文化修养"]
            } else {
                description = "你悟性高、思维独特，适合研究深奥的学问或从事专业技术。对神秘事物有天然的兴趣和理解力。"
                keywords = ["悟性高", "独立研究", "专业深耕"]
            }
        } else if totalYinScore > 1.5 {
            strength = "明显"
            description = "你有不错的学习能力，善于吸收知识。在学习和考试方面有一定优势，容易得到指点。"
            keywords = ["学习能力强", "善于吸收"]
        } else {
            strength = "较弱"
            description = "命中印星较弱，学习上可能需要更多的自我努力。建议通过实践来学习，而非死读书。"
            keywords = ["实践为主", "自我驱动"]
        }

        return LifeTheme(
            icon: "📚",
            title: "学习成长",
            description: description,
            keywords: keywords,
            strength: strength
        )
    }

    // MARK: - 辅助方法

    private func getShiShenScore(_ shiShen: String) -> Double {
        shiShenResult.items.first { $0.shiShen == shiShen }?.totalScore ?? 0
    }
}
