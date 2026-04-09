import Foundation

/// 本地解盘原则：优先从 `Assistant/AssistantPrinciples.md` 读取，缺失时使用内置回退。
enum AssistantPrinciplesProvider {
    static func load() -> String {
        if let text = loadFromBundle(), !text.isEmpty {
            return text
        }
        return fallbackPrinciples
    }

    private static func loadFromBundle() -> String? {
        guard let url = Bundle.main.url(
            forResource: "AssistantPrinciples",
            withExtension: "md",
            subdirectory: "Assistant"
        ) else {
            return nil
        }
        return try? String(contentsOf: url, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static let fallbackPrinciples = """
    # 解盘原则（默认）

    - 先引用命盘事实，再做文化性解释。
    - 涉及时间、年份、大运流年与十神时，以 App 注入内容为准。
    - 不做绝对化吉凶断语，不给诊疗或投资指令。
    """
}
