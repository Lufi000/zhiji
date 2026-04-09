import CoreGraphics

/// 聊天区统一尺寸，避免气泡、推荐条、思考块等各用各的圆角。
public enum MiniMaxChatLayout {
    public static let bubbleCornerRadius: CGFloat = 16
    /// 气泡内嵌区域（如思考正文区），略小于外层以保持层次。
    public static let nestedCornerRadius: CGFloat = 12
}
