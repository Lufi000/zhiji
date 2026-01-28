import Foundation

// MARK: - 天干枚举（类型安全）

/// 十天干枚举类型
/// 使用枚举代替字符串可以在编译期捕获无效值
enum TianGan: String, CaseIterable, Codable, Hashable {
    case 甲, 乙, 丙, 丁, 戊, 己, 庚, 辛, 壬, 癸

    /// 获取索引（0-9）
    var index: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }

    /// 从索引创建
    static func from(index: Int) -> TianGan {
        let normalizedIndex = ((index % 10) + 10) % 10
        return allCases[normalizedIndex]
    }

    /// 从字符串创建（兼容旧代码）
    static func from(string: String) -> TianGan? {
        TianGan(rawValue: string)
    }

    /// 五行属性
    var wuXing: WuXing {
        switch self {
        case .甲, .乙: return .木
        case .丙, .丁: return .火
        case .戊, .己: return .土
        case .庚, .辛: return .金
        case .壬, .癸: return .水
        }
    }

    /// 阴阳属性
    var yinYang: YinYang {
        switch self {
        case .甲, .丙, .戊, .庚, .壬: return .阳
        case .乙, .丁, .己, .辛, .癸: return .阴
        }
    }

    /// 获取下一个天干
    var next: TianGan {
        TianGan.from(index: index + 1)
    }

    /// 获取上一个天干
    var previous: TianGan {
        TianGan.from(index: index - 1)
    }
}

// MARK: - 地支枚举（类型安全）

/// 十二地支枚举类型
enum DiZhi: String, CaseIterable, Codable, Hashable {
    case 子, 丑, 寅, 卯, 辰, 巳, 午, 未, 申, 酉, 戌, 亥

    /// 获取索引（0-11）
    var index: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }

    /// 从索引创建
    static func from(index: Int) -> DiZhi {
        let normalizedIndex = ((index % 12) + 12) % 12
        return allCases[normalizedIndex]
    }

    /// 从字符串创建（兼容旧代码）
    static func from(string: String) -> DiZhi? {
        DiZhi(rawValue: string)
    }

    /// 五行属性
    var wuXing: WuXing {
        switch self {
        case .寅, .卯: return .木
        case .巳, .午: return .火
        case .辰, .戌, .丑, .未: return .土
        case .申, .酉: return .金
        case .子, .亥: return .水
        }
    }

    /// 阴阳属性
    var yinYang: YinYang {
        switch self {
        case .子, .寅, .辰, .午, .申, .戌: return .阳
        case .丑, .卯, .巳, .未, .酉, .亥: return .阴
        }
    }

    /// 藏干
    var cangGan: [TianGan] {
        switch self {
        case .子: return [.癸]
        case .丑: return [.己, .癸, .辛]
        case .寅: return [.甲, .丙, .戊]
        case .卯: return [.乙]
        case .辰: return [.戊, .乙, .癸]
        case .巳: return [.丙, .庚, .戊]
        case .午: return [.丁, .己]
        case .未: return [.己, .丁, .乙]
        case .申: return [.庚, .壬, .戊]
        case .酉: return [.辛]
        case .戌: return [.戊, .辛, .丁]
        case .亥: return [.壬, .甲]
        }
    }

    /// 对应的生肖
    var shengXiao: String {
        switch self {
        case .子: return "鼠"
        case .丑: return "牛"
        case .寅: return "虎"
        case .卯: return "兔"
        case .辰: return "龙"
        case .巳: return "蛇"
        case .午: return "马"
        case .未: return "羊"
        case .申: return "猴"
        case .酉: return "鸡"
        case .戌: return "狗"
        case .亥: return "猪"
        }
    }

    /// 是否为四库（辰戌丑未）
    var isSiKu: Bool {
        switch self {
        case .辰, .戌, .丑, .未: return true
        default: return false
        }
    }

    /// 获取下一个地支
    var next: DiZhi {
        DiZhi.from(index: index + 1)
    }

    /// 获取上一个地支
    var previous: DiZhi {
        DiZhi.from(index: index - 1)
    }
}

// MARK: - 五行枚举

/// 五行枚举类型
enum WuXing: String, CaseIterable, Codable, Hashable {
    case 木, 火, 土, 金, 水

    /// 生我者
    var shengWo: WuXing {
        switch self {
        case .木: return .水
        case .火: return .木
        case .土: return .火
        case .金: return .土
        case .水: return .金
        }
    }

    /// 我生者
    var woSheng: WuXing {
        switch self {
        case .木: return .火
        case .火: return .土
        case .土: return .金
        case .金: return .水
        case .水: return .木
        }
    }

    /// 克我者
    var keWo: WuXing {
        switch self {
        case .木: return .金
        case .火: return .水
        case .土: return .木
        case .金: return .火
        case .水: return .土
        }
    }

    /// 我克者
    var woKe: WuXing {
        switch self {
        case .木: return .土
        case .火: return .金
        case .土: return .水
        case .金: return .木
        case .水: return .火
        }
    }

    /// 从字符串创建（兼容旧代码）
    static func from(string: String) -> WuXing? {
        WuXing(rawValue: string)
    }
}

// MARK: - 阴阳枚举

/// 阴阳枚举类型
enum YinYang: String, Codable, Hashable {
    case 阴, 阳

    var isYang: Bool { self == .阳 }
    var isYin: Bool { self == .阴 }
}

// MARK: - 十神枚举

/// 十神枚举类型
enum ShiShenType: String, CaseIterable, Codable, Hashable {
    case 比肩, 劫财, 食神, 伤官, 偏财, 正财, 七杀, 正官, 偏印, 正印

    /// 十神类别
    var category: ShiShenCategory {
        switch self {
        case .比肩, .劫财: return .biJie
        case .偏印, .正印: return .yinXing
        case .食神, .伤官: return .shiShang
        case .偏财, .正财: return .caiXing
        case .七杀, .正官: return .guanSha
        }
    }

    /// 是否为正神（正官、正印、正财、食神）
    var isZhengShen: Bool {
        switch self {
        case .正官, .正印, .正财, .食神: return true
        default: return false
        }
    }

    /// 计算十神
    static func calculate(riGan: TianGan, targetGan: TianGan) -> ShiShenType {
        let riWx = riGan.wuXing
        let targetWx = targetGan.wuXing
        let sameYinYang = riGan.yinYang == targetGan.yinYang

        if riWx == targetWx {
            return sameYinYang ? .比肩 : .劫财
        }
        if riWx.woSheng == targetWx {
            return sameYinYang ? .食神 : .伤官
        }
        if riWx.woKe == targetWx {
            return sameYinYang ? .偏财 : .正财
        }
        if targetWx.woKe == riWx {
            return sameYinYang ? .七杀 : .正官
        }
        // riWx.shengWo == targetWx
        return sameYinYang ? .偏印 : .正印
    }
}

// MARK: - 类型安全的柱子结构

/// 类型安全的柱子结构
struct GanZhiPillar: Codable, Hashable {
    let gan: TianGan
    let zhi: DiZhi

    /// 从旧的 Pillar 转换
    init(gan: TianGan, zhi: DiZhi) {
        self.gan = gan
        self.zhi = zhi
    }

    /// 从字符串创建（兼容旧代码）
    init?(ganString: String, zhiString: String) {
        guard let gan = TianGan.from(string: ganString),
              let zhi = DiZhi.from(string: zhiString) else {
            return nil
        }
        self.gan = gan
        self.zhi = zhi
    }

    /// 转换为旧的 Pillar 格式（兼容旧代码）
    var toPillar: Pillar {
        Pillar(gan: gan.rawValue, zhi: zhi.rawValue)
    }
}

// MARK: - 扩展 Pillar 支持类型转换

extension Pillar {
    /// 转换为类型安全的 GanZhiPillar
    var toGanZhiPillar: GanZhiPillar? {
        GanZhiPillar(ganString: gan, zhiString: zhi)
    }
}

// MARK: - 字符串便捷扩展（桥接旧代码）

/// 为字符串提供便捷的干支属性访问
/// 用于逐步迁移现有代码到类型安全系统
extension String {
    /// 获取天干/地支的五行（字符串版本）
    /// - Returns: 五行字符串，无效输入返回 nil
    var ganZhiWuXing: String? {
        if let gan = TianGan(rawValue: self) {
            return gan.wuXing.rawValue
        }
        if let zhi = DiZhi(rawValue: self) {
            return zhi.wuXing.rawValue
        }
        return nil
    }

    /// 获取天干/地支的阴阳（字符串版本）
    /// - Returns: "阴" 或 "阳"，无效输入返回 nil
    var ganZhiYinYang: String? {
        if let gan = TianGan(rawValue: self) {
            return gan.yinYang.rawValue
        }
        if let zhi = DiZhi(rawValue: self) {
            return zhi.yinYang.rawValue
        }
        return nil
    }

    /// 获取地支的藏干（字符串版本）
    /// - Returns: 藏干字符串数组，无效输入返回 nil
    var zhiCangGan: [String]? {
        guard let zhi = DiZhi(rawValue: self) else { return nil }
        return zhi.cangGan.map { $0.rawValue }
    }

    /// 转换为天干枚举
    var asTianGan: TianGan? { TianGan(rawValue: self) }

    /// 转换为地支枚举
    var asDiZhi: DiZhi? { DiZhi(rawValue: self) }

    /// 转换为五行枚举
    var asWuXing: WuXing? { WuXing(rawValue: self) }
}
