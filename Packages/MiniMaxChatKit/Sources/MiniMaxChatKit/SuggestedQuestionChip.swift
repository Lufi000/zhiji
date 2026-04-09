import SwiftUI

public struct SuggestedQuestionChip: View {
    let question: String
    let onTap: () -> Void
    var palette: MiniMaxChatPalette

    public init(question: String, palette: MiniMaxChatPalette = .warmParchment, onTap: @escaping () -> Void) {
        self.question = question
        self.palette = palette
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: onTap) {
            HStack {
                Text(question)
                    .font(.system(size: palette.bodySize + 1))
                    .foregroundStyle(palette.textPrimary)
                    .multilineTextAlignment(.leading)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(palette.textSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(palette.cardBackgroundSolid)
            .clipShape(RoundedRectangle(cornerRadius: MiniMaxChatLayout.bubbleCornerRadius))
            .shadow(
                color: palette.textPrimary.opacity(0.05),
                radius: 4,
                y: 2
            )
        }
        .buttonStyle(.plain)
    }
}
