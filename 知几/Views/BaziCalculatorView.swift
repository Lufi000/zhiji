import SwiftUI

// MARK: - 静态数据（避免重复创建）

private enum PickerData {
    static let years = Array(1900...2100)
    static let months = Array(1...12)
    static let hours = Array(0...23)
    static let minutes = Array(0...59)

    /// 预计算的时辰显示文本（整点）
    static let hourTexts: [String] = hours.map { h in
        "\(h):00 (\(BaziConstants.diZhi[((h + 1) / 2) % 12])时)"
    }
}

// MARK: - 主视图

struct BaziCalculatorView: View {
    var mingPanStore: MingPanStore

    @State private var selectedYear = 1995
    @State private var selectedMonth = 10
    @State private var selectedDay = 5
    @State private var selectedHour = 2
    @State private var selectedMinute = 10
    @State private var gender = "female"
    @State private var showResult = false
    @State private var bazi: Bazi?
    @State private var resultViewId = UUID()  // 用于强制 ResultView 重建
    @State private var validationError: BaziCalculationError?

    // 根据年月计算当月天数
    var daysInMonth: Int {
        let calendar = Calendar.current
        let components = DateComponents(year: selectedYear, month: selectedMonth)
        if let date = calendar.date(from: components),
           let range = calendar.range(of: .day, in: .month, for: date) {
            return range.count
        }
        return 31
    }

    var days: [Int] {
        Array(1...daysInMonth)
    }

    var body: some View {
        ZStack {
            DiffuseBackground()

            if showResult, let bazi = bazi {
                // 结果页面：不包在 ScrollView 里，让 ResultView 自己管理滚动
                ResultView(
                    bazi: bazi,
                    birth: getBirthComponents(),
                    gender: gender,
                    mingPanStore: mingPanStore,
                    onBack: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showResult = false
                    }
                })
                .id(resultViewId)
            } else {
                // 输入页面
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // 标题栏
                        VStack(spacing: 16) {
                            HStack(spacing: 16) {
                                Spacer()

                                Text("知几")
                                    .font(.system(size: 36, weight: .medium))
                                    .foregroundColor(DesignSystem.textPrimary)
                                    .tracking(4)

                                AppLogo(size: 60)

                                Spacer()
                            }

                            Text("静时厚积，风起乘势")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(DesignSystem.textPrimary)
                                .tracking(3)
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 16)

                        // 输入表单
                        inputForm
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 24)
                }
            }
        }
        .alert(item: $validationError) { error in
            Alert(
                title: Text("无法排盘"),
                message: Text(error.errorDescription ?? ""),
                dismissButton: .default(Text("确定"))
            )
        }
    }

    private var inputForm: some View {
        VStack(spacing: 16) {
            // 日期选择（年月日wheel选择器）
            Text("出生日期")
                .formLabel()

            HStack(spacing: 0) {
                // 年选择
                Picker("年", selection: $selectedYear) {
                    ForEach(PickerData.years, id: \.self) { year in
                        Text("\(year)年").tag(year)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .clipped()

                // 月选择
                Picker("月", selection: $selectedMonth) {
                    ForEach(PickerData.months, id: \.self) { month in
                        Text("\(month)月").tag(month)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .clipped()

                // 日选择
                Picker("日", selection: $selectedDay) {
                    ForEach(days, id: \.self) { day in
                        Text("\(day)日").tag(day)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .clipped()
            }
            .frame(height: 120)
            .onChange(of: selectedMonth) { _, _ in
                // 当月份改变时，确保日期不超过当月天数
                if selectedDay > daysInMonth {
                    selectedDay = daysInMonth
                }
            }
            .onChange(of: selectedYear) { _, _ in
                // 当年份改变时（闰年），确保日期不超过当月天数
                if selectedDay > daysInMonth {
                    selectedDay = daysInMonth
                }
            }

            // 出生时间（几点几分）
            Text("出生时间")
                .formLabel()

            HStack(spacing: 0) {
                Picker("时", selection: $selectedHour) {
                    ForEach(PickerData.hours, id: \.self) { h in
                        Text(PickerData.hourTexts[h]).tag(h)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .clipped()

                Picker("分", selection: $selectedMinute) {
                    ForEach(PickerData.minutes, id: \.self) { m in
                        Text(String(format: "%02d分", m)).tag(m)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .clipped()
            }
            .frame(height: 120)

            // 性别选择
            Text("性别")
                .formLabel()

            HStack(spacing: 10) {
                genderButton("male", "👨 男")
                genderButton("female", "👩 女")
            }

            // 生成按钮 - 黑色文字 + 白色为主的彩色渐变背景 + 无边框
            Button(action: calculate) {
                HStack(spacing: 8) {
                    Text("开始排盘")
                        .font(.system(size: 15, weight: .medium))
                        .tracking(2)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(DesignSystem.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(18)
                .background(
                    LinearGradient(
                        colors: [
                            Color(hex: "E8F5E9"),       // 淡绿
                            Color.white,
                            Color(hex: "E3F2FD"),       // 淡蓝
                            Color.white,
                            Color(hex: "FBE9E7")        // 淡橙
                        ],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cornerRadiusMedium))
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
            }
        }
        .padding(24)
        .background(.ultraThinMaterial.opacity(0.8))
        .background(Color.white.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cornerRadiusLarge))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.cornerRadiusLarge)
                .stroke(Color.white.opacity(0.6), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 24, x: 0, y: 12)
    }

    private func genderButton(_ value: String, _ label: String) -> some View {
        Button(action: { gender = value }) {
            Text(label)
                .font(.system(size: 14, weight: .light))
                .tracking(1)
                .frame(maxWidth: .infinity)
                .padding(14)
                .background(gender == value ? DesignSystem.primaryOrange.opacity(0.08) : Color.white.opacity(0.6))
                .foregroundColor(gender == value ? DesignSystem.primaryOrange : DesignSystem.textSecondary)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cornerRadiusSmall))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.cornerRadiusSmall)
                        .stroke(gender == value ? DesignSystem.primaryOrange.opacity(0.5) : Color.white.opacity(0.3), lineWidth: 1)
                )
        }
    }

    func getBirthComponents() -> (year: Int, month: Int, day: Int, hour: Int, minute: Int) {
        return (selectedYear, selectedMonth, selectedDay, selectedHour, selectedMinute)
    }

    func calculate() {
        // 入口校验：日期与时辰
        switch BaziValidator.validateDate(year: selectedYear, month: selectedMonth, day: selectedDay) {
        case .failure(let error):
            BaziLogger.shared.logCalculationError(error, context: "排盘入口")
            if error.isUserFacing { validationError = error }
            return
        case .success:
            break
        }
        switch BaziValidator.validateHour(selectedHour) {
        case .failure(let error):
            BaziLogger.shared.logCalculationError(error, context: "排盘入口")
            if error.isUserFacing { validationError = error }
            return
        case .success:
            break
        }
        switch BaziValidator.validateYearForJieqi(selectedYear) {
        case .failure(let error):
            BaziLogger.shared.logCalculationError(error, context: "排盘入口")
            if error.isUserFacing { validationError = error }
            return
        case .success:
            break
        }
        validationError = nil

        let lunar = PillarCalculator.getYearPillar(year: selectedYear, month: selectedMonth, day: selectedDay)
        let dayPillar = PillarCalculator.getDayPillar(year: selectedYear, month: selectedMonth, day: selectedDay)

        // 夜子时处理：使用统一的辅助方法
        let hourDayGan = PillarCalculator.getHourDayGan(
            year: selectedYear,
            month: selectedMonth,
            day: selectedDay,
            hour: selectedHour,
            currentDayPillar: dayPillar
        )

        bazi = Bazi(
            year: Pillar(gan: lunar.yearGan, zhi: lunar.yearZhi),
            month: PillarCalculator.getMonthPillar(year: selectedYear, month: selectedMonth, day: selectedDay, yearGan: lunar.yearGan),
            day: dayPillar,
            hour: PillarCalculator.getHourPillar(hour: selectedHour, dayGan: hourDayGan),
            shengXiao: lunar.shengXiao
        )

        // 每次计算时更新 resultViewId，确保 ResultView 完全重建
        resultViewId = UUID()

        withAnimation(.easeInOut(duration: 0.3)) {
            showResult = true
        }
    }
}
