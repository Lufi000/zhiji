import Foundation

/// 本地「事实知识包」：类似 NotebookLM 的单一可信资料源。
struct AssistantKnowledgePack: Codable {
    let version: Int
    let generatedAt: Date
    let source: String
    let sourceRecordId: String?
    let riGan: String?
    let summary: String
    let chunks: [AssistantFactChunk]

    static let currentVersion = 1

    static func fromSummary(
        summary: String,
        riGan: String?,
        source: String,
        sourceRecordId: UUID?
    ) -> AssistantKnowledgePack {
        let trimmed = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        let chunks = AssistantKnowledgePackBuilder.splitToChunks(summary: trimmed)
        return AssistantKnowledgePack(
            version: currentVersion,
            generatedAt: Date(),
            source: source,
            sourceRecordId: sourceRecordId?.uuidString,
            riGan: riGan,
            summary: trimmed,
            chunks: chunks
        )
    }
}

struct AssistantFactChunk: Codable {
    let id: String
    let category: String
    let text: String
}

enum AssistantKnowledgePackBuilder {
    static func splitToChunks(summary: String) -> [AssistantFactChunk] {
        guard !summary.isEmpty else { return [] }
        let lines = summary.components(separatedBy: .newlines)
        var sections: [(title: String, body: [String])] = []
        var currentTitle = "总览"
        var currentBody: [String] = []

        for raw in lines {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if isHeadingLine(line) {
                if !currentBody.isEmpty {
                    sections.append((currentTitle, currentBody))
                }
                currentTitle = headingTitle(line)
                currentBody = [line]
            } else {
                currentBody.append(raw)
            }
        }
        if !currentBody.isEmpty {
            sections.append((currentTitle, currentBody))
        }

        var idx = 1
        return sections.compactMap { section in
            let text = section.body.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { return nil }
            defer { idx += 1 }
            return AssistantFactChunk(
                id: String(format: "F%02d", idx),
                category: section.title,
                text: text
            )
        }
    }

    private static func isHeadingLine(_ line: String) -> Bool {
        line.hasPrefix("【") && line.contains("】")
    }

    private static func headingTitle(_ line: String) -> String {
        guard let end = line.firstIndex(of: "】") else { return "分节" }
        return String(line[line.startIndex...end])
    }
}
