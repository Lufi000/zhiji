import Foundation
import os.log

// MARK: - 八字计算错误类型

/// 八字计算过程中可能出现的错误
enum BaziCalculationError: LocalizedError {
    /// 日期无效
    case invalidDate(year: Int, month: Int, day: Int)
    /// 时辰无效
    case invalidHour(hour: Int)
    /// 天干无效
    case invalidTianGan(value: String)
    /// 地支无效
    case invalidDiZhi(value: String)
    /// 节气数据超出范围
    case jieqiOutOfRange(year: Int, supportedRange: ClosedRange<Int>)
    /// 计算失败
    case calculationFailed(reason: String)
    /// 数据缺失
    case missingData(field: String)

    var errorDescription: String? {
        switch self {
        case .invalidDate(let year, let month, let day):
            return "无效的日期: \(year)年\(month)月\(day)日"
        case .invalidHour(let hour):
            return "无效的时辰: \(hour)时"
        case .invalidTianGan(let value):
            return "无效的天干: \(value)"
        case .invalidDiZhi(let value):
            return "无效的地支: \(value)"
        case .jieqiOutOfRange(let year, let supportedRange):
            return "年份 \(year) 超出节气数据支持范围 (\(supportedRange.lowerBound)-\(supportedRange.upperBound))"
        case .calculationFailed(let reason):
            return "计算失败: \(reason)"
        case .missingData(let field):
            return "缺少必要数据: \(field)"
        }
    }

    /// 是否应该显示给用户
    var isUserFacing: Bool {
        switch self {
        case .jieqiOutOfRange:
            return true
        case .invalidDate, .invalidHour:
            return true
        default:
            return false
        }
    }
}

// MARK: - 日志管理器

/// 统一的日志管理器
final class BaziLogger {
    static let shared = BaziLogger()

    private let logger = Logger(subsystem: "com.zhiji.bazi", category: "calculation")

    private init() {}

    /// 记录调试信息
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        let filename = (file as NSString).lastPathComponent
        logger.debug("[\(filename):\(line)] \(function) - \(message)")
        #endif
    }

    /// 记录信息
    func info(_ message: String) {
        logger.info("\(message)")
    }

    /// 记录警告
    func warning(_ message: String, error: Error? = nil) {
        if let error = error {
            logger.warning("\(message) - Error: \(error.localizedDescription)")
        } else {
            logger.warning("\(message)")
        }
    }

    /// 记录错误
    func error(_ message: String, error: Error? = nil) {
        if let error = error {
            logger.error("\(message) - Error: \(error.localizedDescription)")
        } else {
            logger.error("\(message)")
        }
    }

    /// 记录八字计算错误
    func logCalculationError(_ error: BaziCalculationError, context: String = "") {
        let contextInfo = context.isEmpty ? "" : " [Context: \(context)]"
        logger.error("BaziCalculationError: \(error.localizedDescription)\(contextInfo)")
    }
}

// MARK: - Result 类型扩展

/// 八字计算结果类型
typealias BaziResult<T> = Result<T, BaziCalculationError>

extension Result where Failure == BaziCalculationError {
    /// 获取值，失败时记录日志并返回默认值
    func valueOrDefault(_ defaultValue: Success, logContext: String = "") -> Success {
        switch self {
        case .success(let value):
            return value
        case .failure(let error):
            BaziLogger.shared.logCalculationError(error, context: logContext)
            return defaultValue
        }
    }

    /// 获取值，失败时记录日志并执行回退逻辑
    func valueOrFallback(_ fallback: () -> Success, logContext: String = "") -> Success {
        switch self {
        case .success(let value):
            return value
        case .failure(let error):
            BaziLogger.shared.logCalculationError(error, context: logContext)
            return fallback()
        }
    }
}

// MARK: - 安全计算包装器

/// 安全执行计算并处理错误
struct SafeCalculator {
    /// 安全执行可能抛出错误的计算
    static func execute<T>(
        _ operation: () throws -> T,
        fallback: T,
        context: String = ""
    ) -> T {
        do {
            return try operation()
        } catch let error as BaziCalculationError {
            BaziLogger.shared.logCalculationError(error, context: context)
            return fallback
        } catch {
            BaziLogger.shared.error("Unexpected error in calculation", error: error)
            return fallback
        }
    }

    /// 安全执行并返回 Result
    static func executeToResult<T>(
        _ operation: () throws -> T
    ) -> BaziResult<T> {
        do {
            return .success(try operation())
        } catch let error as BaziCalculationError {
            return .failure(error)
        } catch {
            return .failure(.calculationFailed(reason: error.localizedDescription))
        }
    }
}

// MARK: - 验证器

/// 输入数据验证器
struct BaziValidator {
    /// 验证日期
    static func validateDate(year: Int, month: Int, day: Int) -> BaziResult<Void> {
        let calendar = Calendar.current
        let components = DateComponents(year: year, month: month, day: day)

        guard let date = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: date),
              range.contains(day) else {
            return .failure(.invalidDate(year: year, month: month, day: day))
        }

        return .success(())
    }

    /// 验证时辰
    static func validateHour(_ hour: Int) -> BaziResult<Void> {
        guard (0...23).contains(hour) else {
            return .failure(.invalidHour(hour: hour))
        }
        return .success(())
    }

    /// 验证年份是否在节气数据范围内
    static func validateYearForJieqi(_ year: Int) -> BaziResult<Void> {
        let supportedRange = 1940...2050
        guard supportedRange.contains(year) else {
            return .failure(.jieqiOutOfRange(year: year, supportedRange: supportedRange))
        }
        return .success(())
    }

    /// 验证天干字符串
    static func validateTianGan(_ value: String) -> BaziResult<TianGan> {
        guard let tianGan = TianGan.from(string: value) else {
            return .failure(.invalidTianGan(value: value))
        }
        return .success(tianGan)
    }

    /// 验证地支字符串
    static func validateDiZhi(_ value: String) -> BaziResult<DiZhi> {
        guard let diZhi = DiZhi.from(string: value) else {
            return .failure(.invalidDiZhi(value: value))
        }
        return .success(diZhi)
    }
}
