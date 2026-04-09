import SwiftUI
import UIKit

public struct ChatBubbleView: View {
    let message: ChatMessage
    /// 气泡与追问芯片下方的灰色小字（如时间）；`nil` 不显示。
    var captionBelow: String?
    var onFollowUpTap: ((String) -> Void)?
    var onCopyTap: ((ChatMessage) -> Void)?
    var onDeleteTap: ((ChatMessage) -> Void)?
    var onRefreshTap: ((ChatMessage) -> Void)?
    var showsRefreshAction: Bool
    var palette: MiniMaxChatPalette

    public init(
        message: ChatMessage,
        palette: MiniMaxChatPalette = .warmParchment,
        captionBelow: String? = nil,
        onFollowUpTap: ((String) -> Void)? = nil,
        onCopyTap: ((ChatMessage) -> Void)? = nil,
        onDeleteTap: ((ChatMessage) -> Void)? = nil,
        onRefreshTap: ((ChatMessage) -> Void)? = nil,
        showsRefreshAction: Bool = false
    ) {
        self.message = message
        self.captionBelow = captionBelow
        self.palette = palette
        self.onFollowUpTap = onFollowUpTap
        self.onCopyTap = onCopyTap
        self.onDeleteTap = onDeleteTap
        self.onRefreshTap = onRefreshTap
        self.showsRefreshAction = showsRefreshAction
    }

    @State private var thinkingExpanded = false

    private var isThinking: Bool {
        message.isStreaming && !(message.thinkingText ?? "").isEmpty && message.content.isEmpty
    }

    public var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.role == .user { Spacer(minLength: 48) }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 6) {
                if let thinking = message.thinkingText, !thinking.isEmpty, message.role == .assistant {
                    thinkingAccordion(text: thinking)
                }

                if !isThinking {
                    bubbleContent
                }

                if message.role == .assistant,
                   !message.isStreaming,
                   let follow = message.followUpQuestions,
                   !follow.isEmpty {
                    followUpSuggestions(follow)
                }

                if let cap = captionBelow, !cap.isEmpty {
                    Text(cap)
                        .font(.system(size: palette.captionSize))
                        .foregroundStyle(palette.textSecondary.opacity(0.92))
                        .padding(.top, 2)
                }
            }

            if message.role == .assistant { Spacer(minLength: 48) }
        }
        .onChange(of: message.thinkingText) { _, newVal in
            if let t = newVal, !t.isEmpty, !thinkingExpanded {
                withAnimation(.easeOut(duration: 0.2)) { thinkingExpanded = true }
            }
        }
    }

    @ViewBuilder
    private var bubbleContent: some View {
        let bubble = Group {
            if message.isStreaming && message.content.isEmpty {
                TypingIndicatorView(palette: palette)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 18)
            } else if message.role == .assistant {
                MarkdownTextView(content: message.content, isStreaming: message.isStreaming, palette: palette)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 18)
            } else {
                Text(message.content)
                    .font(.system(size: palette.bodySize + 2))
                    .foregroundStyle(Color.white)
                    .multilineTextAlignment(.leading)
                    .textSelection(.enabled)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 18)
            }
        }
        .background(
            message.role == .user
                ? AnyView(palette.accent)
                : AnyView(palette.cardBackgroundSolid.shadow(color: palette.textPrimary.opacity(0.06), radius: 4, y: 2))
        )
        .clipShape(RoundedRectangle(cornerRadius: MiniMaxChatLayout.bubbleCornerRadius))

        if !message.content.isEmpty {
            bubble.contextMenu {
                Button {
                    if let onCopyTap {
                        onCopyTap(message)
                    } else {
                        UIPasteboard.general.string = message.content
                    }
                } label: {
                    Label("复制", systemImage: "doc.on.doc")
                }

                if showsRefreshAction {
                    Button {
                        onRefreshTap?(message)
                    } label: {
                        Label("刷新", systemImage: "arrow.clockwise")
                    }
                }

                Button(role: .destructive) {
                    onDeleteTap?(message)
                } label: {
                    Label("删除", systemImage: "trash")
                }
            }
        } else {
            bubble
        }
    }

    @ViewBuilder
    private func followUpSuggestions(_ questions: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("还可以问问：")
                .font(.system(size: palette.bodySize + 1))
                .foregroundStyle(palette.textSecondary)
                .padding(.leading, 4)

            ForEach(questions, id: \.self) { q in
                SuggestedQuestionChip(question: q, palette: palette) {
                    onFollowUpTap?(q)
                }
            }
        }
        .padding(.top, 4)
    }

    @ViewBuilder
    private func thinkingAccordion(text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { thinkingExpanded.toggle() }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 10))
                    if message.isStreaming && message.content.isEmpty {
                        Text("思考中…")
                            .font(.system(size: palette.captionSize + 1, weight: .medium))
                        ThinkingPulse(palette: palette)
                    } else {
                        Text("思考过程")
                            .font(.system(size: palette.captionSize + 1, weight: .medium))
                    }
                    Image(systemName: thinkingExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 9))
                }
                .foregroundStyle(palette.accent.opacity(0.8))
            }
            .buttonStyle(.plain)

            if thinkingExpanded {
                ScrollView {
                    Text(text)
                        .font(.system(size: palette.captionSize + 1))
                        .foregroundStyle(palette.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                }
                .frame(maxHeight: 160)
                .background(palette.accentLight.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: MiniMaxChatLayout.nestedCornerRadius))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(10)
        .background(palette.cardBackgroundSolid.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: MiniMaxChatLayout.bubbleCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: MiniMaxChatLayout.bubbleCornerRadius)
                .stroke(palette.accent.opacity(0.15), lineWidth: 1)
        )
    }
}

private struct ThinkingPulse: View {
    var palette: MiniMaxChatPalette
    @State private var animate = false

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(palette.accent.opacity(0.6))
                    .frame(width: 4, height: 4)
                    .scaleEffect(animate ? 1.0 : 0.5)
                    .opacity(animate ? 1.0 : 0.3)
                    .animation(
                        .easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.2),
                        value: animate
                    )
            }
        }
        .onAppear { animate = true }
    }
}

private struct TypingIndicatorView: View {
    var palette: MiniMaxChatPalette
    @State private var phase = 0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(palette.textSecondary)
                    .frame(width: 6, height: 6)
                    .scaleEffect(phase == i ? 1.3 : 0.8)
                    .animation(
                        .easeInOut(duration: 0.4).repeatForever().delay(Double(i) * 0.13),
                        value: phase
                    )
            }
        }
        .onAppear {
            withAnimation { phase = (phase + 1) % 3 }
        }
    }
}
