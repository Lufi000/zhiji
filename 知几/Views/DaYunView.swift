import SwiftUI

// MARK: - 大运视图

struct DaYunView: View {
    let daYunList: [DaYun]
    let riGan: String
    let currentAge: Int
    let birthYear: Int
    @Binding var selectedIndex: Int?

    var currentDaYunIndex: Int {
        daYunList.firstIndex { currentAge >= $0.age && currentAge < $0.age + 10 } ?? 0
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("大运")
                    .font(.system(size: 15, weight: .light))
                    .foregroundColor(DesignSystem.textPrimary)
                    .tracking(2)

                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(daYunList.indices, id: \.self) { i in
                                let dy = daYunList[i]
                                GanZhiItemView(
                                    topLabel: String(birthYear + dy.age),
                                    gan: dy.gan,
                                    zhi: dy.zhi,
                                    ganShiShen: getShiShen(riGan: riGan, targetGan: dy.gan),
                                    zhiShiShen: getZhiShiShen(riGan: riGan, zhi: dy.zhi),
                                    bottomLabel: "\(dy.age)岁",
                                    isSelected: selectedIndex == i,
                                    isCurrent: i == currentDaYunIndex,
                                    onTap: { selectedIndex = i }
                                )
                                .id(i)
                            }
                        }
                        .padding(.vertical, 2)
                        .padding(.horizontal, 2)
                    }
                    .onAppear {
                        if selectedIndex == nil { selectedIndex = currentDaYunIndex }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation { proxy.scrollTo(selectedIndex ?? currentDaYunIndex, anchor: .center) }
                        }
                    }
                    .onChange(of: selectedIndex) { _, newValue in
                        if let index = newValue {
                            withAnimation { proxy.scrollTo(index, anchor: .center) }
                        }
                    }
                }
            }
            .padding(20)
        }
    }
}
