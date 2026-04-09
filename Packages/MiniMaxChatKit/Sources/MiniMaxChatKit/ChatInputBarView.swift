import SwiftUI

public struct ChatInputBarView: View {
    @Binding var text: String
    let isStreaming: Bool
    let onSend: () -> Void
    var palette: MiniMaxChatPalette

    public init(
        text: Binding<String>,
        isStreaming: Bool,
        palette: MiniMaxChatPalette = .warmParchment,
        onSend: @escaping () -> Void
    ) {
        _text = text
        self.isStreaming = isStreaming
        self.palette = palette
        self.onSend = onSend
    }

    public var body: some View {
        HStack(spacing: 10) {
            TextField(
                "输入你想问的…",
                text: $text,
                prompt: Text("输入你想问的…").foregroundStyle(palette.textSecondary),
                axis: .vertical
            )
            .font(.system(size: palette.bodySize + 2))
            .foregroundStyle(palette.textPrimary)
            .tint(palette.accent)
            .lineLimit(1...5)
            .padding(.horizontal, 12)
            .padding(.vertical, 14)
            .background(palette.cardBackgroundSolid)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(palette.accent.opacity(0.2), lineWidth: 1)
            )
            .onSubmit { if !isStreaming { onSend() } }

            Button {
                onSend()
            } label: {
                Image(systemName: isStreaming ? "stop.circle.fill" : "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        isStreaming
                            ? palette.textSecondary
                            : (text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                               ? palette.textSecondary.opacity(0.4)
                               : palette.accent)
                    )
                    .animation(.easeInOut(duration: 0.15), value: isStreaming)
            }
            .disabled(!isStreaming && text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            palette.background
                .ignoresSafeArea(edges: .bottom)
        )
        .overlay(alignment: .top) {
            Divider().opacity(0.4)
        }
    }
}
