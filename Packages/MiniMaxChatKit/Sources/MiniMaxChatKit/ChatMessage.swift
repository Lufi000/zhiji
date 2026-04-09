import Foundation

public struct ChatMessage: Identifiable, Codable, Equatable, Sendable {
    public enum Role: String, Codable, Sendable { case user, assistant }

    public let id: UUID
    public let role: Role
    public var content: String
    public var isStreaming: Bool
    public var thinkingText: String?
    public var followUpQuestions: [String]?
    public let timestamp: Date
    public let sessionDate: Date

    public init(
        id: UUID = UUID(),
        role: Role,
        content: String,
        isStreaming: Bool = false,
        thinkingText: String? = nil,
        followUpQuestions: [String]? = nil,
        timestamp: Date = .now,
        sessionDate: Date = Calendar.current.startOfDay(for: .now)
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.isStreaming = isStreaming
        self.thinkingText = thinkingText
        self.followUpQuestions = followUpQuestions
        self.timestamp = timestamp
        self.sessionDate = sessionDate
    }
}
