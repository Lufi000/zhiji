# App Review 回复说明

针对 2026-02-11 审核反馈（Submission ID: bfe2cdb6-cbe3-45a2-a513-7287dae7c667）的逐项说明与建议回复。

---

## 1. Guideline 2.1 - Information Needed

**审核问题：** Where can we locate the feature of 再让 DeepSeek/Kimi/豆包 解读 per your app promotional text?

**建议回复（英文，可直接或稍作修改后在 App Store Connect 中 Reply 使用）：**

> The “DeepSeek/Kimi/豆包 解读” mentioned in our promotional text does **not** refer to an in-app integration with those services. It refers to the following feature:
>
> **Where to find it:** On the **Birth Chart (命盘)** screen — the screen that appears after the user enters birth date, time, and gender and taps to view the result. In the **top-right area of the header bar** (next to the app logo), there is a button labeled **「复制到 AI」** (Copy to AI).
>
> **What it does:** When the user taps 「复制到 AI」, the app copies a formatted Bazi (八字) chart plus the Chinese prompt “请根据以下八字命盘进行解读” to the system clipboard. The user can then open **any** external app (e.g. DeepSeek, Kimi, 豆包, ChatGPT) and paste the content there to ask that app for an interpretation. We do not embed or integrate DeepSeek, Kimi, or 豆包 inside our app; we only provide a one-tap copy for use in the user’s chosen AI app.
>
> **Summary:** The “interpretation by DeepSeek/Kimi/豆包” is done by the user in those external apps; our app only supplies the 「复制到 AI」 button on the 命盘 screen to copy the chart text.

**中文要点（便于你自行组织回复）：**

- 功能位置：**命盘页**（排盘结果页）**顶部右侧**，与 Logo 在一起的 **「复制到 AI」** 按钮。
- 功能含义：点击后把「请根据以下八字命盘进行解读」+ 命盘全文复制到剪贴板，用户自行到 DeepSeek / Kimi / 豆包等任意 App 里粘贴并解读，本 App 内没有集成上述任何一家 AI。

---

## 2. Guideline 1.5 - Support URL 不可用

**审核问题：** Support URL `https://lufi000.github.io/zhiji/support.html` 无法访问或显示错误。

**已做：**

- 在仓库中新增了可用的支持页：`docs/support.html`，内容包含使用说明、获取支持方式、隐私说明。

**你需要做：**

1. **部署该页面，使上述 URL 可访问**
   - 若你的 GitHub 仓库名为 `zhiji`、用户名为 `lufi000`：
     - 在仓库 **Settings → Pages** 中，Source 选择 **Deploy from a branch**，Branch 选 `main`（或 `master`），Folder 选 **/docs**，保存。
     - 部署完成后，根地址为 `https://lufi000.github.io/zhiji/`，支持页即为 `https://lufi000.github.io/zhiji/support.html`。
   - 若支持页放在其他站点（例如自己的博客、Notion 公开页），则把该页的完整 URL 记下来。

2. **在 App Store Connect 中更新 Support URL**
   - 打开 App Store Connect → 你的 App → App 信息（或版本信息）→ 找到 **Support URL** 字段。
   - 将 Support URL 改为已部署且能正常打开的地址（例如 `https://lufi000.github.io/zhiji/support.html` 或你实际使用的 URL）。

3. **重新提交或回复审核**
   - 若你只更新了 Support URL 而未发新版本：在 Resolution Center 中回复说明已更新 Support URL 并给出新 URL，请审核再次验证。
   - 若你发布了新版本：在新版本说明中可写“已更新支持页面链接”，并在回复中说明 Support URL 已更正。

**建议回复（英文）：**

> We have fixed the Support URL. The support page is now available at: [你实际填写的 Support URL]
>
> We have also updated the Support URL in App Store Connect to point to this page. Please try again when you have a moment.

---

## 3. Guideline 4.3(b) - Design - Spam（类别饱和）

**审核意见：** 应用主要提供占星、星座、手相、算命或生肖类内容，与现有大量应用重复，建议重新考虑应用概念或考虑以 Web App 形式提供。

**建议策略：**

- **不要与审核争辩“八字不是占星”**，而是强调**功能与体验上的差异**，说明本应用不是通用“算命/星座”类应用，而是**可查证、规则透明的八字排盘工具**，并突出与“复制到 AI”的配合使用方式。

**建议回复要点（英文，可按需精简或扩展）：**

> Thank you for the feedback. We would like to clarify how 知几 (Zhiji) differs from generic astrology/fortune-telling apps:
>
> 1. **Focus on verifiable Bazi (八字) charting, not fortune‑telling.** The app is a Bazi (Four Pillars) calculator: users input birth date, time, and gender and receive a structured chart (four pillars, major cycles, yearly cycles). Calculation rules (solar terms, midnight handling, etc.) are transparent and can be checked against standard references. We do not sell in-app “fortune” or “lucky” reports.
>
> 2. **“Copy to AI” workflow.** We do not host or sell interpretations inside the app. We provide a single “Copy to AI” button on the chart screen so users can paste the chart into their preferred external AI app (e.g. DeepSeek, Kimi, ChatGPT) for personal reflection. The app stays a calculation and charting tool; interpretation is left to the user and their chosen tools.
>
> 3. **Educational and self-reflection angle.** Our positioning is self-understanding and life rhythm within a traditional framework, not prediction or superstition. The in-app content (e.g. “energy interaction” between pillars) is explanatory and structural, not “luck” or “fortune” promises.
>
> We believe 知几 offers a distinct experience: a transparent, rule-based Bazi charting tool that works with the user’s own AI for interpretation, rather than another generic astrology/fortune app. We would be grateful if the app could be re-reviewed with this distinction in mind. If the team still considers the category saturated, we will consider the suggested alternatives (e.g. a web app) for future versions.

**中文要点：**

- 强调：**可查证的八字排盘工具**，非通用算命/占星。
- 强调：**无应用内付费解读/算命**，仅有「复制到 AI」交给用户自选 AI。
- 强调：**自我认知与人生节奏**，不承诺吉凶或运气。
- 礼貌请求按“差异化工具”重新评估；若仍被拒，可表示会考虑 Web App 等建议。

---

## 4. 回复与重新提交顺序建议

1. **先修复 Support URL**
   - 部署 `docs/support.html`，在 App Store Connect 中更新 Support URL，确认在浏览器中能打开。

2. **在 App Store Connect 的 Resolution Center 中一次性回复**
   - 回答 2.1：说明「复制到 AI」的位置与含义（可粘贴上面英文回复）。
   - 说明 1.5：已更新 Support URL 并给出新链接。
   - 回应 4.3(b)：说明差异化（可粘贴或改写上面英文回复）。

3. **若审核要求重新提交版本**
   - 在“新版本说明”中可写：已更新支持页面链接；命盘页提供「复制到 AI」便于用户在外部 AI 中解读。
   - 再次确认 Support URL 在 Connect 中正确且可访问。

---

## 5. 验证方式

- **2.1：** 审核在 iPad 上进入排盘结果（命盘）页，应能在右上角看到「复制到 AI」按钮，点击后粘贴到备忘录可看到“请根据以下八字命盘进行解读”及命盘内容。
- **1.5：** 在浏览器中打开你在 Connect 中填写的 Support URL，应能正常显示支持与帮助内容。
- **4.3(b)：** 取决于审核对差异化的认可；回复后若仍被拒，可考虑改为 Web App 或进一步强化产品差异后再提交。

如有需要，可把 `docs/support.html` 中的联系方式改为你的真实邮箱或反馈渠道后再部署。
