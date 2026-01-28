import SwiftUI

// MARK: - 流年视图

struct LiuNianView: View {
    let riGan: String
    let birthYear: Int
    let currentYear: Int
    let daYunList: [DaYun]
    let selectedDaYunIndex: Int?
    @Binding var selectedYear: Int?

    // 根据大运索引计算流年列表
    func getDisplayYears(for daYunIndex: Int?) -> [Int] {
        guard let index = daYunIndex, index < daYunList.count else { return [] }
        let startYear = birthYear + daYunList[index].age
        return Array(startYear...(startYear + 9))
    }

    var displayYears: [Int] {
        getDisplayYears(for: selectedDaYunIndex)
    }

    func getLiuNianGanZhi(year: Int) -> (gan: String, zhi: String) {
        let g = (year - 1984) % 10
        let z = (year - 1984) % 12
        return (BaziConstants.tianGan[(g + 10) % 10], BaziConstants.diZhi[(z + 12) % 12])
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("流年")
                    .font(.system(size: 15, weight: .light))
                    .foregroundColor(DesignSystem.textPrimary)
                    .tracking(2)

                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(displayYears, id: \.self) { year in
                                let ganZhi = getLiuNianGanZhi(year: year)
                                GanZhiItemView(
                                    topLabel: "\(String(year).suffix(2))年",
                                    gan: ganZhi.gan,
                                    zhi: ganZhi.zhi,
                                    ganShiShen: getShiShen(riGan: riGan, targetGan: ganZhi.gan),
                                    zhiShiShen: getZhiShiShen(riGan: riGan, zhi: ganZhi.zhi),
                                    bottomLabel: "\(year - birthYear + 1)岁",
                                    isSelected: selectedYear == year,
                                    isCurrent: year == currentYear,
                                    onTap: { selectedYear = year }
                                )
                                .id(year)
                            }
                        }
                        .padding(.vertical, 2)
                        .padding(.horizontal, 2)
                    }
                    .task(id: selectedDaYunIndex) {
                        // 当大运索引变化时（包括初始化），设置流年选中状态并滚动
                        guard selectedDaYunIndex != nil, !displayYears.isEmpty else { return }

                        // 计算目标年份
                        let targetYear = displayYears.contains(currentYear) ? currentYear : displayYears.first

                        // 判断是初始化还是切换大运
                        let isInitialization = selectedYear == nil

                        // 设置选中年份
                        if selectedYear != targetYear {
                            selectedYear = targetYear
                        }

                        // 等待视图更新
                        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒

                        // 滚动到目标位置
                        if let year = targetYear {
                            if isInitialization {
                                // 初始化时直接定位
                                proxy.scrollTo(year, anchor: .center)
                            } else {
                                // 切换大运时使用弹性动画
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    proxy.scrollTo(year, anchor: .center)
                                }
                            }
                        }
                    }
                    .onChange(of: selectedYear) { oldYear, newYear in
                        // 流年手动切换时，滚动到选中位置
                        if let year = newYear, oldYear != nil {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo(year, anchor: .center)
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
    }
}
