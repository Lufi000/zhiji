import StoreKit
import SwiftUI

// MARK: - 内购产品 ID
enum ProductID: String, CaseIterable {
    case liuNianAnalysis = "com.lufi.zhiji.liunian_analysis"
}

// MARK: - 命盘标识（用于记录已解锁的命盘）
struct BaziIdentifier: Codable, Hashable {
    let year: Int
    let month: Int
    let day: Int
    let hour: Int
    let gender: String

    var key: String {
        "\(year)-\(month)-\(day)-\(hour)-\(gender)"
    }
}

// MARK: - 内购管理器
@Observable
@MainActor
final class StoreManager {
    static let shared = StoreManager()

    private(set) var products: [Product] = []
    private(set) var isLoading = false

    // 已解锁的命盘列表（本地存储）
    private(set) var unlockedBaziList: Set<String> = []

    private var updateListenerTask: Task<Void, Error>?

    private let unlockedBaziKey = "unlockedBaziList"

    private init() {
        loadUnlockedBazi()
        updateListenerTask = listenForTransactions()

        Task {
            await loadProducts()
        }
    }

    nonisolated func cancelListener() {
        Task { @MainActor in
            updateListenerTask?.cancel()
        }
    }

    // MARK: - 检查命盘是否已解锁
    func isLiuNianUnlocked(for bazi: BaziIdentifier) -> Bool {
        unlockedBaziList.contains(bazi.key)
    }

    func isLiuNianUnlocked(year: Int, month: Int, day: Int, hour: Int, gender: String) -> Bool {
        let identifier = BaziIdentifier(year: year, month: month, day: day, hour: hour, gender: gender)
        return isLiuNianUnlocked(for: identifier)
    }

    // MARK: - 加载状态
    private(set) var loadError: StoreError?

    // MARK: - 加载产品
    func loadProducts() async {
        isLoading = true
        loadError = nil
        defer { isLoading = false }

        do {
            let productIDs = ProductID.allCases.map { $0.rawValue }
            products = try await Product.products(for: productIDs)

            if products.isEmpty {
                loadError = .productNotFound
                BaziLogger.shared.warning("未能加载任何产品")
            }
        } catch {
            loadError = .networkError
            BaziLogger.shared.error("加载产品失败", error: error)
        }
    }

    /// 重新加载产品
    func reloadProducts() async {
        await loadProducts()
    }

    // MARK: - 购买产品（消耗型）

    /// 购买流年解析功能
    /// - Parameter bazi: 命盘标识
    /// - Returns: 购买结果
    /// - Throws: `StoreError` 当购买失败时
    func purchaseLiuNianAnalysis(for bazi: BaziIdentifier) async throws -> PurchaseResult {
        guard let product = liuNianProduct else {
            throw StoreError.productNotFound
        }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)

                // 消耗型产品：购买成功后记录已解锁的命盘
                unlockBazi(bazi)

                await transaction.finish()
                return .success

            case .userCancelled:
                return .cancelled

            case .pending:
                return .pending

            @unknown default:
                throw StoreError.unknownError
            }
        } catch let error as StoreError {
            throw error
        } catch {
            throw StoreError.purchaseFailed(underlying: error)
        }
    }

    /// 购买结果枚举
    enum PurchaseResult {
        case success
        case cancelled
        case pending

        var isSuccess: Bool {
            self == .success
        }
    }

    // MARK: - 解锁命盘（本地存储）
    private func unlockBazi(_ bazi: BaziIdentifier) {
        unlockedBaziList.insert(bazi.key)
        saveUnlockedBazi()
    }

    // MARK: - 本地存储管理
    private func loadUnlockedBazi() {
        if let data = UserDefaults.standard.data(forKey: unlockedBaziKey),
           let list = try? JSONDecoder().decode(Set<String>.self, from: data) {
            unlockedBaziList = list
        }
    }

    private func saveUnlockedBazi() {
        if let data = try? JSONEncoder().encode(unlockedBaziList) {
            UserDefaults.standard.set(data, forKey: unlockedBaziKey)
        }
    }

    // MARK: - 监听交易
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                }
            }
        }
    }

    // MARK: - 验证交易
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - 获取流年解析产品
    var liuNianProduct: Product? {
        products.first { $0.id == ProductID.liuNianAnalysis.rawValue }
    }
}

// MARK: - 错误类型

enum StoreError: LocalizedError {
    case failedVerification
    case productNotFound
    case purchaseFailed(underlying: Error?)
    case networkError
    case unknownError

    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "交易验证失败，请重试"
        case .productNotFound:
            return "未找到商品，请检查网络连接后重试"
        case .purchaseFailed(let underlying):
            if let error = underlying {
                return "购买失败: \(error.localizedDescription)"
            }
            return "购买失败，请重试"
        case .networkError:
            return "网络错误，请检查网络连接"
        case .unknownError:
            return "发生未知错误，请重试"
        }
    }

    /// 是否应该显示给用户
    var isUserFacing: Bool {
        switch self {
        case .failedVerification, .productNotFound, .purchaseFailed, .networkError:
            return true
        case .unknownError:
            return false
        }
    }
}
