import Foundation

public enum ThinkingMode: String, CaseIterable, Identifiable, Sendable {
    case fast = "fast"
    case deep = "deep"

    public var id: String { rawValue }

    public var modelName: String {
        switch self {
        case .fast: return "MiniMax-M2.5"
        case .deep: return "MiniMax-M2.7"
        }
    }
}
