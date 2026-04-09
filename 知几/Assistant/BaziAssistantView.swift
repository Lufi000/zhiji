import Combine
import MiniMaxChatKit
import SwiftUI

/// 布局与交互对齐 cycle_advisor `AssistantView`（对话仍经 BFF）；顶部为八字场景问候（无周期 Header）。
struct BaziAssistantView: View {
    @Bindable var viewModel: BaziAssistantViewModel
    @Bindable var mingPanStore: MingPanStore
    @Binding var selectedTab: Int

    @Environment(\.scenePhase) private var scenePhase
    /// 用于定时刷新「是否已过可显示时间」的阈值；与 `scenePhase` / 系统时间变更一并更新。
    @State private var timeTick = Date()
    @State private var showManageMingPans = false
    /// 仅在用户主动发送后强制跟底一次，避免被流式 token 高频更新抢焦点。
    @State private var pendingForceScrollToBottom = false
    @AppStorage("zhiji.assistantPanCardExpanded") private var assistantPanCardExpanded = false

    private var palette: MiniMaxChatPalette { .zhiji }

    /// 距发送超过该时长后，在气泡下显示时间（与微信「刚发不标时间」接近）。
    private static let messageCaptionFadeInDelay: TimeInterval = 180

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                AssistantCurrentPanCard(
                    display: mingPanStore.assistantPanUIDisplay(),
                    palette: palette,
                    isExpanded: $assistantPanCardExpanded
                )
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 8)

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if viewModel.messages.isEmpty {
                                emptyStateView
                            } else {
                                messageList
                            }

                            Color.clear
                                .frame(height: 1)
                                .id("chat-bottom-anchor")
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                    }
                    .onTapGesture {
                        UIApplication.shared.sendAction(
                            #selector(UIResponder.resignFirstResponder),
                            to: nil, from: nil, for: nil
                        )
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onAppear {
                        guard !viewModel.messages.isEmpty else { return }
                        DispatchQueue.main.async {
                            scrollToBottom(proxy: proxy, animated: false)
                        }
                    }
                    .onChange(of: viewModel.messages.count) {
                        autoScrollIfNeeded(proxy: proxy)
                    }
                }

                ChatInputBarView(
                    text: $viewModel.inputText,
                    isStreaming: viewModel.isStreaming,
                    palette: palette
                ) {
                    sendCurrentInput()
                }
            }
            .background(
                palette.background
                    .grainTexture(intensity: .subtle, seed: 99)
                    .ignoresSafeArea()
            )
            .overlay(alignment: .leading) {
                Color.clear
                    .frame(width: 24)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 20, coordinateSpace: .global)
                            .onEnded { value in
                                let rightward = value.translation.width > 60
                                let notVertical = abs(value.translation.height) < 80
                                if rightward && notVertical {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        selectedTab = 0
                                    }
                                }
                            }
                    )
            }
            .navigationTitle("AI 助手")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 4) {
                        mingPanMenu
                        if !viewModel.messages.isEmpty {
                            Menu {
                                Button(role: .destructive) {
                                    viewModel.clearHistory()
                                } label: {
                                    Label("清除所有对话", systemImage: "trash")
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .foregroundStyle(palette.textSecondary)
                            }
                        }
                    }
                }
            }
            .toolbarBackground(palette.background, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .task {
                timeTick = Date()
                await viewModel.loadSuggestedQuestionsIfNeeded()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active { timeTick = Date() }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
                timeTick = Date()
            }
            .onReceive(Timer.publish(every: 15, on: .main, in: .common).autoconnect()) { timeTick = $0 }
            .onReceive(NotificationCenter.default.publisher(for: BaziAssistantContext.panContextDidUpdateNotification)) { _ in
                Task { await viewModel.reloadSuggestedQuestionsAfterPanSync() }
            }
            .sheet(isPresented: $showManageMingPans) {
                ManageSavedMingPansSheet(mingPanStore: mingPanStore)
            }
            .overlay(alignment: .top) {
                if let tip = viewModel.apiErrorToast {
                    Text(tip)
                        .font(.system(size: 12))
                        .foregroundStyle(palette.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(palette.cardBackgroundSolid)
                        .clipShape(RoundedRectangle(cornerRadius: MiniMaxChatLayout.bubbleCornerRadius))
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
    }

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(alignment: .leading, spacing: 20) {
            greetingBubble

            if viewModel.isLoadingSuggestedQuestions && viewModel.suggestedQuestions.isEmpty {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.9)
                    Text("正在生成推荐话题…")
                        .font(.system(size: palette.bodySize + 1))
                        .foregroundStyle(palette.textSecondary)
                }
                .padding(.leading, 4)
            } else if !viewModel.suggestedQuestions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("你可能想问：")
                        .font(.system(size: palette.bodySize + 1))
                        .foregroundStyle(palette.textSecondary)
                        .padding(.leading, 4)

                    ForEach(viewModel.suggestedQuestions, id: \.self) { q in
                        SuggestedQuestionChip(question: q, palette: palette) {
                            viewModel.inputText = q
                            sendCurrentInput()
                        }
                    }
                }
            }

            AssistantDisclaimerView()
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var greetingBubble: some View {
        HStack(alignment: .bottom, spacing: 8) {
            Text(greetingText())
                .font(.system(size: palette.bodySize + 2))
                .foregroundStyle(palette.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(palette.cardBackgroundSolid)
                .clipShape(RoundedRectangle(cornerRadius: MiniMaxChatLayout.bubbleCornerRadius))
                .shadow(color: palette.textPrimary.opacity(0.06), radius: 4, y: 2)
            Spacer(minLength: 48)
        }
    }

    @ViewBuilder
    private var messageList: some View {
        let lastUserId = viewModel.messages.last(where: { $0.role == .user })?.id
        let now = timeTick
        ForEach(viewModel.messages) { msg in
            ChatBubbleView(
                message: msg,
                palette: palette,
                captionBelow: messageCaptionBelow(msg, now: now),
                onFollowUpTap: { question in
                    pendingForceScrollToBottom = true
                    Task { await viewModel.sendMessage(question) }
                },
                onCopyTap: { message in
                    UIPasteboard.general.string = message.content
                },
                onDeleteTap: { message in
                    viewModel.deleteMessage(message.id)
                },
                onRefreshTap: { message in
                    Task { await viewModel.refreshUserMessage(message.id) }
                },
                showsRefreshAction: msg.role == .user &&
                    !msg.isStreaming &&
                    msg.id == lastUserId
            )
            .id(msg.id)
        }
    }

    private func sendCurrentInput() {
        let text = viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        pendingForceScrollToBottom = true
        viewModel.inputText = ""
        Task { await viewModel.sendMessage(text) }
    }

    private func autoScrollIfNeeded(proxy: ScrollViewProxy) {
        guard pendingForceScrollToBottom else { return }
        scrollToBottom(proxy: proxy)
        pendingForceScrollToBottom = false
    }

    private func scrollToBottom(proxy: ScrollViewProxy, animated: Bool = true) {
        if animated {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo("chat-bottom-anchor", anchor: .bottom)
            }
        } else {
            proxy.scrollTo("chat-bottom-anchor", anchor: .bottom)
        }
    }

    /// 刚发出的消息不显示；超过约 3 分钟后在气泡下显示。当天仅 `HH:mm`，更早先写「昨天/前天/…」再写时间。
    private func messageCaptionBelow(_ message: ChatMessage, now: Date) -> String? {
        if message.isStreaming { return nil }
        if now.timeIntervalSince(message.timestamp) < Self.messageCaptionFadeInDelay { return nil }
        let cal = gregorianLocalCalendar()
        let hm = formatHourMinute(message.timestamp, cal: cal)
        if cal.isDate(message.timestamp, inSameDayAs: now) {
            return hm
        }
        let dayPrefix = formatRelativeDayPrefixForCaption(message.timestamp, referenceNow: now, cal: cal)
        return "\(dayPrefix) \(hm)"
    }

    private func formatHourMinute(_ date: Date, cal: Calendar) -> String {
        let h = cal.component(.hour, from: date)
        let m = cal.component(.minute, from: date)
        return String(format: "%02d:%02d", h, m)
    }

    private func formatRelativeDayPrefixForCaption(_ date: Date, referenceNow: Date, cal: Calendar) -> String {
        let startDate = cal.startOfDay(for: date)
        let startNow = cal.startOfDay(for: referenceNow)
        if startDate > startNow {
            let y = cal.component(.year, from: date)
            let ry = cal.component(.year, from: referenceNow)
            if y != ry { return formatYearMonthDay(date, cal: cal) }
            return formatMonthDay(date, cal: cal)
        }
        let daysAgo = cal.dateComponents([.day], from: startDate, to: startNow).day ?? 0
        switch daysAgo {
        case 1: return "昨天"
        case 2: return "前天"
        default: break
        }
        let yMsg = cal.component(.year, from: date)
        let yNow = cal.component(.year, from: referenceNow)
        if yMsg != yNow {
            return formatYearMonthDay(date, cal: cal)
        }
        if daysAgo >= 3, daysAgo <= 7 {
            return chineseWeekdayLabel(for: date, cal: cal)
        }
        return formatMonthDay(date, cal: cal)
    }

    /// 公历「星期几」（星期一…星期日），与 `date` 当天一致。
    private func chineseWeekdayLabel(for date: Date, cal: Calendar) -> String {
        let weekdayIndex = cal.component(.weekday, from: date)
        let names = ["日", "一", "二", "三", "四", "五", "六"]
        let i = (weekdayIndex - 1 + 7) % 7
        return "星期\(names[i])"
    }

    private func formatMonthDay(_ date: Date, cal: Calendar) -> String {
        let m = cal.component(.month, from: date)
        let d = cal.component(.day, from: date)
        return "\(m)月\(d)日"
    }

    private func formatYearMonthDay(_ date: Date, cal: Calendar) -> String {
        let y = cal.component(.year, from: date)
        let m = cal.component(.month, from: date)
        let d = cal.component(.day, from: date)
        return "\(y)年\(m)月\(d)日"
    }

    private func greetingText() -> String {
        let hasPan = !mingPanStore.currentAssistantPanSummary().isEmpty
        if hasPan {
            return "你好！上方已列出当前带入的命盘要点，想聊什么都可以～"
        }
        return "你好！我是知几助手。在排盘结果页保存命盘后，命盘会显示在上方并带入对话；也可用「复制到 AI」或右上角选择命盘。随时在下面输入问题即可。"
    }

    @ViewBuilder
    private var mingPanMenu: some View {
        Menu {
            if mingPanStore.records.isEmpty {
                Text("暂无已保存命盘")
                    .foregroundStyle(palette.textSecondary)
            } else {
                if mingPanStore.selfMingPanId != nil && mingPanStore.assistantOverrideMingPanId != nil {
                    Button {
                        mingPanStore.useSelfMingPanForAssistant()
                    } label: {
                        Label("使用我的命盘", systemImage: "person.fill")
                    }
                }
                ForEach(mingPanStore.records) { record in
                    Button {
                        mingPanStore.setAssistantMingPan(id: record.id)
                    } label: {
                        HStack {
                            Text(record.displayName)
                            if mingPanStore.selfMingPanId == record.id {
                                Text("我的")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 8)
                            if mingPanStore.resolvedAssistantMingPanId() == record.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
                Divider()
                Button {
                    showManageMingPans = true
                } label: {
                    Label("管理已保存命盘", systemImage: "slider.horizontal.3")
                }
            }
        } label: {
            Image(systemName: "rectangle.stack")
                .foregroundStyle(palette.textSecondary)
        }
    }
}

// MARK: - 管理已保存命盘

private struct ManageSavedMingPansSheet: View {
    @Bindable var mingPanStore: MingPanStore
    @Environment(\.dismiss) private var dismiss
    @State private var renameTarget: SavedMingPanRecord?
    @State private var renameText = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(mingPanStore.records) { record in
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(record.displayName)
                                .font(.body)
                            Text(verbatim: "\(record.birthYear)年\(record.birthMonth)月\(record.birthDay)日 · \(record.gender == "female" ? "女" : "男")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if mingPanStore.selfMingPanId == record.id {
                            Text("我的")
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.orange.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        mingPanStore.setAssistantMingPan(id: record.id)
                        dismiss()
                    }
                    .contextMenu {
                        Button("设为我的命盘") {
                            mingPanStore.setSelfMingPan(id: record.id)
                        }
                        Button("重命名") {
                            renameTarget = record
                            renameText = record.displayName
                        }
                        Button("删除", role: .destructive) {
                            mingPanStore.delete(id: record.id)
                        }
                    }
                }
                .onDelete { indexSet in
                    for i in indexSet {
                        mingPanStore.delete(id: mingPanStore.records[i].id)
                    }
                }
            }
            .navigationTitle("已保存命盘")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") { dismiss() }
                }
            }
            .alert("重命名", isPresented: Binding(
                get: { renameTarget != nil },
                set: { if !$0 { renameTarget = nil } }
            )) {
                TextField("名称", text: $renameText)
                Button("取消", role: .cancel) { renameTarget = nil }
                Button("保存") {
                    if let t = renameTarget {
                        let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            mingPanStore.rename(id: t.id, displayName: trimmed)
                        }
                    }
                    renameTarget = nil
                }
            } message: {
                Text("为命盘起一个便于识别的名称。")
            }
        }
    }
}
