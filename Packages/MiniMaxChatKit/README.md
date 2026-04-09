# MiniMaxChatKit

可复用的 **MiniMax（OpenAI 兼容 BFF）流式对话 + 聊天 UI**，供多个 iOS App 通过 Swift Package 引用。

## 公开能力概览

| 类型 | 说明 |
|------|------|
| `MiniMaxChatConfiguration` / `MiniMaxChatConfigurationValues` | BFF URL、`X-App-Token`、思考模式 UserDefaults key |
| `MiniMaxChatClient` | `streamChat`（SSE）、`fetchQuestionsJSON`（非流式 JSON 问题列表） |
| `ChatMessage`、`MiniMaxMessage`、`ThinkingMode`、`MiniMaxChatAPIError` | 模型与错误 |
| `MiniMaxChatPalette` | 聊天页配色（含默认 `warmParchment`） |
| `ChatBubbleView`、`ChatInputBarView`、`MarkdownTextView`、`SuggestedQuestionChip`、`GrainOverlay` | SwiftUI 组件 |

## 接入方式

1. 将本目录作为 **Local Swift Package** 加入 Xcode 工程（File → Add Package Dependencies → Add Local… → 选择 `Packages/MiniMaxChatKit`），或把整份 `Packages/MiniMaxChatKit` 复制到其他仓库根目录再添加。
2. 在 App Target 的 **Frameworks, Libraries, and Embedded Content** 中加入 `MiniMaxChatKit`。
3. 使用 `MiniMaxChatClient(configuration: MiniMaxChatConfigurationValues(baseURLString:appToken:thinkingModeUserDefaultsKey:))`。
4. **System / User 提示词、产品文案** 放在各 App 内（参考知几的 `BaziPrompts.swift`）；包内不包含业务领域逻辑。

## 与 cycle_advisor / 知几

- BFF 协议与 `cycle_advisor` 的 `MiniMaxService` 一致：`POST` + `X-App-Token` + SSE `data:` 行。
- 思考块使用与 cycle_advisor 相同的 XML 风格 `think` 标签。
