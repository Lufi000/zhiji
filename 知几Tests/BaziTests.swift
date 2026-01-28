import Testing
@testable import 知几

// MARK: - 八字计算核心算法测试

struct BaziCalculationTests {

    // MARK: - 日柱计算测试

    @Test("日柱计算 - 2000年1月1日应为戊午日")
    func testDayPillarBaseDate() {
        let pillar = getDayPillar(year: 2000, month: 1, day: 1)
        #expect(pillar.gan == "戊")
        #expect(pillar.zhi == "午")
    }

    @Test("日柱计算 - 已知日期验证")
    func testDayPillarKnownDates() {
        // 1992年8月28日 应为 辛未日
        let pillar1 = getDayPillar(year: 1992, month: 8, day: 28)
        #expect(pillar1.gan == "辛")
        #expect(pillar1.zhi == "未")

        // 2024年1月1日 应为 甲辰日
        let pillar2 = getDayPillar(year: 2024, month: 1, day: 1)
        #expect(pillar2.gan == "甲")
        #expect(pillar2.zhi == "辰")
    }

    // MARK: - 年柱计算测试

    @Test("年柱计算 - 立春前后判断")
    func testYearPillarLichun() {
        // 2024年立春前（2月4日立春）
        let lunar1 = getLunar(year: 2024, month: 2, day: 3)
        #expect(lunar1.yearGan == "癸")
        #expect(lunar1.yearZhi == "卯")
        #expect(lunar1.shengXiao == "兔")

        // 2024年立春后
        let lunar2 = getLunar(year: 2024, month: 2, day: 5)
        #expect(lunar2.yearGan == "甲")
        #expect(lunar2.yearZhi == "辰")
        #expect(lunar2.shengXiao == "龙")
    }

    // MARK: - 月支计算测试

    @Test("月支计算 - 节气边界")
    func testMonthZhiByJieqi() {
        // 寅月（立春后）
        let zhiIndex1 = getMonthZhiByJieqi(year: 2024, month: 2, day: 5)
        #expect(zhiIndex1 == 2)  // 寅

        // 卯月（惊蛰后）
        let zhiIndex2 = getMonthZhiByJieqi(year: 2024, month: 3, day: 6)
        #expect(zhiIndex2 == 3)  // 卯
    }

    // MARK: - 时柱计算测试

    @Test("时柱计算 - 五鼠遁时")
    func testHourPillar() {
        // 甲日子时
        let pillar1 = getHourPillar(hour: 0, dayGan: "甲")
        #expect(pillar1.gan == "甲")
        #expect(pillar1.zhi == "子")

        // 乙日午时
        let pillar2 = getHourPillar(hour: 12, dayGan: "乙")
        #expect(pillar2.gan == "壬")
        #expect(pillar2.zhi == "午")
    }

    // MARK: - 十神计算测试

    @Test("十神计算 - 基本关系")
    func testShiShen() {
        // 日干甲木
        #expect(getShiShen(riGan: "甲", targetGan: "甲") == "比肩")
        #expect(getShiShen(riGan: "甲", targetGan: "乙") == "劫财")
        #expect(getShiShen(riGan: "甲", targetGan: "丙") == "食神")
        #expect(getShiShen(riGan: "甲", targetGan: "丁") == "伤官")
        #expect(getShiShen(riGan: "甲", targetGan: "戊") == "偏财")
        #expect(getShiShen(riGan: "甲", targetGan: "己") == "正财")
        #expect(getShiShen(riGan: "甲", targetGan: "庚") == "七杀")
        #expect(getShiShen(riGan: "甲", targetGan: "辛") == "正官")
        #expect(getShiShen(riGan: "甲", targetGan: "壬") == "偏印")
        #expect(getShiShen(riGan: "甲", targetGan: "癸") == "正印")
    }
}

// MARK: - 身强身弱计算测试

struct StrengthCalculatorTests {

    @Test("身强身弱 - 身强命局")
    func testStrongBazi() {
        // 构造一个身强的八字（日主得令得势）
        let bazi = Bazi(
            year: Pillar(gan: "甲", zhi: "寅"),
            month: Pillar(gan: "乙", zhi: "卯"),  // 木月
            day: Pillar(gan: "甲", zhi: "寅"),
            hour: Pillar(gan: "甲", zhi: "寅"),
            shengXiao: "虎"
        )

        let calculator = StrengthCalculator(bazi: bazi)
        let result = calculator.calculate()

        #expect(result.strength == "极强" || result.strength == "身强")
        #expect(result.score >= 56)
    }

    @Test("身强身弱 - 身弱命局")
    func testWeakBazi() {
        // 构造一个身弱的八字（日主失令失势）
        let bazi = Bazi(
            year: Pillar(gan: "庚", zhi: "申"),
            month: Pillar(gan: "辛", zhi: "酉"),  // 金月
            day: Pillar(gan: "甲", zhi: "申"),
            hour: Pillar(gan: "庚", zhi: "申"),
            shengXiao: "猴"
        )

        let calculator = StrengthCalculator(bazi: bazi)
        let result = calculator.calculate()

        #expect(result.strength == "极弱" || result.strength == "身弱")
        #expect(result.score < 45)
    }

    @Test("喜用神计算 - 身强喜克泄耗")
    func testXiYongShenForStrong() {
        let bazi = Bazi(
            year: Pillar(gan: "甲", zhi: "寅"),
            month: Pillar(gan: "乙", zhi: "卯"),
            day: Pillar(gan: "甲", zhi: "寅"),
            hour: Pillar(gan: "甲", zhi: "寅"),
            shengXiao: "虎"
        )

        let calculator = StrengthCalculator(bazi: bazi)
        let result = calculator.calculateXiYongShen(strength: "身强")

        // 甲木身强，喜金（官杀）、火（食伤）、土（财星）
        #expect(result.xi.contains("金"))
        #expect(result.xi.contains("火"))
        #expect(result.xi.contains("土"))

        // 忌水（印星）、木（比劫）
        #expect(result.ji.contains("水"))
        #expect(result.ji.contains("木"))
    }

    @Test("喜用神计算 - 身弱喜生扶")
    func testXiYongShenForWeak() {
        let bazi = Bazi(
            year: Pillar(gan: "庚", zhi: "申"),
            month: Pillar(gan: "辛", zhi: "酉"),
            day: Pillar(gan: "甲", zhi: "申"),
            hour: Pillar(gan: "庚", zhi: "申"),
            shengXiao: "猴"
        )

        let calculator = StrengthCalculator(bazi: bazi)
        let result = calculator.calculateXiYongShen(strength: "身弱")

        // 甲木身弱，喜水（印星）、木（比劫）
        #expect(result.xi.contains("水"))
        #expect(result.xi.contains("木"))

        // 忌金（官杀）、火（食伤）、土（财星）
        #expect(result.ji.contains("金"))
    }
}

// MARK: - 五行关系分析测试

struct WuXingAnalysisTests {

    @Test("地支六合检测")
    func testDiZhiLiuHe() {
        // 子丑合
        let bazi = Bazi(
            year: Pillar(gan: "甲", zhi: "子"),
            month: Pillar(gan: "乙", zhi: "丑"),
            day: Pillar(gan: "丙", zhi: "寅"),
            hour: Pillar(gan: "丁", zhi: "卯"),
            shengXiao: "鼠"
        )

        let analysis = analyzeWuXingRelations(bazi: bazi)

        // 应该检测到子丑合
        let hasZiChouHe = analysis.heResults.contains { he in
            he.type == .diZhiLiuHe &&
            he.elements.contains("子") &&
            he.elements.contains("丑")
        }
        #expect(hasZiChouHe)
    }

    @Test("地支六冲检测")
    func testDiZhiChong() {
        // 子午冲
        let bazi = Bazi(
            year: Pillar(gan: "甲", zhi: "子"),
            month: Pillar(gan: "乙", zhi: "丑"),
            day: Pillar(gan: "丙", zhi: "午"),
            hour: Pillar(gan: "丁", zhi: "卯"),
            shengXiao: "鼠"
        )

        let analysis = analyzeWuXingRelations(bazi: bazi)

        // 应该检测到子午冲
        let hasZiWuChong = analysis.chongXingHaiResults.contains { result in
            result.type == "冲" &&
            result.elements.contains("子") &&
            result.elements.contains("午")
        }
        #expect(hasZiWuChong)
    }

    @Test("地支三合检测")
    func testDiZhiSanHe() {
        // 申子辰三合水局
        let bazi = Bazi(
            year: Pillar(gan: "甲", zhi: "申"),
            month: Pillar(gan: "乙", zhi: "子"),
            day: Pillar(gan: "丙", zhi: "辰"),
            hour: Pillar(gan: "丁", zhi: "卯"),
            shengXiao: "猴"
        )

        let analysis = analyzeWuXingRelations(bazi: bazi)

        // 应该检测到申子辰三合
        let hasSanHe = analysis.heResults.contains { he in
            he.type == .diZhiSanHe &&
            he.elements.contains("申") &&
            he.elements.contains("子") &&
            he.elements.contains("辰")
        }
        #expect(hasSanHe)
    }

    @Test("四库检测")
    func testSiKu() {
        // 戌遇丙丁成火库
        let bazi = Bazi(
            year: Pillar(gan: "丙", zhi: "午"),
            month: Pillar(gan: "丁", zhi: "戌"),  // 戌遇丁火天干
            day: Pillar(gan: "甲", zhi: "寅"),
            hour: Pillar(gan: "乙", zhi: "卯"),
            shengXiao: "马"
        )

        let analysis = analyzeWuXingRelations(bazi: bazi)

        // 应该检测到戌成火库
        let hasFireKu = analysis.kuResults.contains { ku in
            ku.zhi == "戌" && ku.isFormed && ku.kuWuXing == "火"
        }
        #expect(hasFireKu)
    }
}

// MARK: - 常量数据完整性测试

struct ConstantsTests {

    @Test("天干数量正确")
    func testTianGanCount() {
        #expect(BaziConstants.tianGan.count == 10)
    }

    @Test("地支数量正确")
    func testDiZhiCount() {
        #expect(BaziConstants.diZhi.count == 12)
    }

    @Test("生肖数量正确")
    func testShengXiaoCount() {
        #expect(BaziConstants.shengXiao.count == 12)
    }

    @Test("五行映射完整")
    func testWuXingMapping() {
        // 所有天干都有五行
        for gan in BaziConstants.tianGan {
            #expect(BaziConstants.wuXing[gan] != nil)
        }

        // 所有地支都有五行
        for zhi in BaziConstants.diZhi {
            #expect(BaziConstants.wuXing[zhi] != nil)
        }
    }

    @Test("阴阳映射完整")
    func testYinYangMapping() {
        // 所有天干都有阴阳
        for gan in BaziConstants.tianGan {
            #expect(BaziConstants.yinYang[gan] != nil)
        }

        // 所有地支都有阴阳
        for zhi in BaziConstants.diZhi {
            #expect(BaziConstants.yinYang[zhi] != nil)
        }
    }

    @Test("藏干映射完整")
    func testCangGanMapping() {
        for zhi in BaziConstants.diZhi {
            let cangGan = BaziConstants.cangGan[zhi]
            #expect(cangGan != nil)
            #expect(cangGan!.count >= 1)
            #expect(cangGan!.count <= 3)
        }
    }

    @Test("五行生克关系正确")
    func testWuXingRelations() {
        // 五行相生循环
        #expect(BaziConstants.wuXingSheng["木"] == "火")
        #expect(BaziConstants.wuXingSheng["火"] == "土")
        #expect(BaziConstants.wuXingSheng["土"] == "金")
        #expect(BaziConstants.wuXingSheng["金"] == "水")
        #expect(BaziConstants.wuXingSheng["水"] == "木")

        // 五行相克循环
        #expect(BaziConstants.wuXingKe["木"] == "土")
        #expect(BaziConstants.wuXingKe["土"] == "水")
        #expect(BaziConstants.wuXingKe["水"] == "火")
        #expect(BaziConstants.wuXingKe["火"] == "金")
        #expect(BaziConstants.wuXingKe["金"] == "木")
    }
}

// MARK: - 大运计算测试

struct DaYunTests {

    @Test("大运列表生成")
    func testDaYunGeneration() {
        let daYunList = getDaYun(
            gender: "male",
            yearGan: "甲",
            monthGan: "丙",
            monthZhi: "寅",
            qiYunAge: 5
        )

        #expect(daYunList.count == 11)
        #expect(daYunList[0].age == 5)
        #expect(daYunList[1].age == 15)
        #expect(daYunList[10].age == 105)
    }

    @Test("起运年龄计算")
    func testQiYunAge() {
        let age = calculateQiYunAge(
            birthYear: 1992,
            birthMonth: 8,
            birthDay: 28,
            gender: "male",
            yearGan: "壬",
            monthZhi: "申"
        )

        // 起运年龄应该在合理范围内
        #expect(age >= 1)
        #expect(age <= 10)
    }
}

// MARK: - 类型安全枚举测试

struct GanZhiTypesTests {

    @Test("天干枚举 - 基本属性")
    func testTianGanBasicProperties() {
        // 测试索引
        #expect(TianGan.甲.index == 0)
        #expect(TianGan.癸.index == 9)

        // 测试五行
        #expect(TianGan.甲.wuXing == .木)
        #expect(TianGan.丙.wuXing == .火)
        #expect(TianGan.戊.wuXing == .土)
        #expect(TianGan.庚.wuXing == .金)
        #expect(TianGan.壬.wuXing == .水)

        // 测试阴阳
        #expect(TianGan.甲.yinYang == .阳)
        #expect(TianGan.乙.yinYang == .阴)
    }

    @Test("天干枚举 - 循环导航")
    func testTianGanNavigation() {
        #expect(TianGan.甲.next == .乙)
        #expect(TianGan.癸.next == .甲)  // 循环
        #expect(TianGan.甲.previous == .癸)  // 循环
    }

    @Test("天干枚举 - 从索引创建")
    func testTianGanFromIndex() {
        #expect(TianGan.from(index: 0) == .甲)
        #expect(TianGan.from(index: 10) == .甲)  // 循环
        #expect(TianGan.from(index: -1) == .癸)  // 负数循环
    }

    @Test("地支枚举 - 基本属性")
    func testDiZhiBasicProperties() {
        // 测试索引
        #expect(DiZhi.子.index == 0)
        #expect(DiZhi.亥.index == 11)

        // 测试五行
        #expect(DiZhi.寅.wuXing == .木)
        #expect(DiZhi.巳.wuXing == .火)
        #expect(DiZhi.辰.wuXing == .土)
        #expect(DiZhi.申.wuXing == .金)
        #expect(DiZhi.子.wuXing == .水)

        // 测试生肖
        #expect(DiZhi.子.shengXiao == "鼠")
        #expect(DiZhi.辰.shengXiao == "龙")
    }

    @Test("地支枚举 - 藏干")
    func testDiZhiCangGan() {
        #expect(DiZhi.子.cangGan == [.癸])
        #expect(DiZhi.寅.cangGan == [.甲, .丙, .戊])
        #expect(DiZhi.丑.cangGan == [.己, .癸, .辛])
    }

    @Test("地支枚举 - 四库判断")
    func testDiZhiSiKu() {
        #expect(DiZhi.辰.isSiKu == true)
        #expect(DiZhi.戌.isSiKu == true)
        #expect(DiZhi.丑.isSiKu == true)
        #expect(DiZhi.未.isSiKu == true)
        #expect(DiZhi.子.isSiKu == false)
    }

    @Test("五行枚举 - 生克关系")
    func testWuXingRelations() {
        // 五行相生
        #expect(WuXing.木.woSheng == .火)
        #expect(WuXing.火.woSheng == .土)
        #expect(WuXing.土.woSheng == .金)
        #expect(WuXing.金.woSheng == .水)
        #expect(WuXing.水.woSheng == .木)

        // 五行相克
        #expect(WuXing.木.woKe == .土)
        #expect(WuXing.土.woKe == .水)
        #expect(WuXing.水.woKe == .火)
        #expect(WuXing.火.woKe == .金)
        #expect(WuXing.金.woKe == .木)

        // 生我、克我
        #expect(WuXing.木.shengWo == .水)
        #expect(WuXing.木.keWo == .金)
    }

    @Test("十神枚举 - 计算")
    func testShiShenCalculation() {
        // 日干甲木
        #expect(ShiShenType.calculate(riGan: .甲, targetGan: .甲) == .比肩)
        #expect(ShiShenType.calculate(riGan: .甲, targetGan: .乙) == .劫财)
        #expect(ShiShenType.calculate(riGan: .甲, targetGan: .丙) == .食神)
        #expect(ShiShenType.calculate(riGan: .甲, targetGan: .丁) == .伤官)
        #expect(ShiShenType.calculate(riGan: .甲, targetGan: .戊) == .偏财)
        #expect(ShiShenType.calculate(riGan: .甲, targetGan: .己) == .正财)
        #expect(ShiShenType.calculate(riGan: .甲, targetGan: .庚) == .七杀)
        #expect(ShiShenType.calculate(riGan: .甲, targetGan: .辛) == .正官)
        #expect(ShiShenType.calculate(riGan: .甲, targetGan: .壬) == .偏印)
        #expect(ShiShenType.calculate(riGan: .甲, targetGan: .癸) == .正印)
    }

    @Test("GanZhiPillar - 类型转换")
    func testGanZhiPillarConversion() {
        // 从字符串创建
        let pillar = GanZhiPillar(ganString: "甲", zhiString: "子")
        #expect(pillar != nil)
        #expect(pillar?.gan == .甲)
        #expect(pillar?.zhi == .子)

        // 转换为旧格式
        let oldPillar = pillar?.toPillar
        #expect(oldPillar?.gan == "甲")
        #expect(oldPillar?.zhi == "子")

        // 无效字符串
        let invalidPillar = GanZhiPillar(ganString: "无效", zhiString: "子")
        #expect(invalidPillar == nil)
    }
}

// MARK: - 错误处理测试

struct BaziErrorTests {

    @Test("日期验证")
    func testDateValidation() {
        // 有效日期
        let validResult = BaziValidator.validateDate(year: 2024, month: 2, day: 29)
        switch validResult {
        case .success: break  // 闰年2月29日有效
        case .failure: Issue.record("2024年2月29日应该是有效日期")
        }

        // 无效日期
        let invalidResult = BaziValidator.validateDate(year: 2023, month: 2, day: 29)
        switch invalidResult {
        case .success: Issue.record("2023年2月29日应该是无效日期")
        case .failure: break
        }
    }

    @Test("时辰验证")
    func testHourValidation() {
        // 有效时辰
        let validResult = BaziValidator.validateHour(12)
        switch validResult {
        case .success: break
        case .failure: Issue.record("12时应该是有效时辰")
        }

        // 无效时辰
        let invalidResult = BaziValidator.validateHour(25)
        switch invalidResult {
        case .success: Issue.record("25时应该是无效时辰")
        case .failure: break
        }
    }

    @Test("节气年份验证")
    func testJieqiYearValidation() {
        // 支持范围内
        let validResult = BaziValidator.validateYearForJieqi(2000)
        switch validResult {
        case .success: break
        case .failure: Issue.record("2000年应该在支持范围内")
        }

        // 超出范围
        let outOfRangeResult = BaziValidator.validateYearForJieqi(1800)
        switch outOfRangeResult {
        case .success: Issue.record("1800年应该超出支持范围")
        case .failure(let error):
            if case .jieqiOutOfRange = error {
                // 正确
            } else {
                Issue.record("应该返回 jieqiOutOfRange 错误")
            }
        }
    }
}
