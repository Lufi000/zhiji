# 知几 App 优化功能清单

> 最后更新：2026年1月23日

---

## 概览

| 阶段 | 时间周期 | 核心目标 | 预期收益提升 |
|------|---------|---------|-------------|
| Phase 1 | 1-2周 | 基础完善 | +20% 用户信任 |
| Phase 2 | 1个月 | 订阅体系 | +150% 收入 |
| Phase 3 | 2-3个月 | 功能扩展 | +300% 收入 |
| Phase 4 | 3-6个月 | 增长引擎 | 用户量翻倍 |

---

## Phase 1: 基础完善（1-2周）

### 1.1 恢复购买功能 [P0]

**目标**: 让用户在换设备后能恢复已购买的内容

**实现清单**:
- [ ] 在设置页面添加"恢复购买"按钮
- [ ] 实现 `StoreManager.restorePurchases()` 方法
- [ ] 处理消耗型产品的恢复逻辑（需要服务端记录或 App Receipt 验证）
- [ ] 添加恢复成功/失败的用户提示
- [ ] 考虑使用 Keychain 或 iCloud KeyValue 存储购买记录

**代码位置**: `知几/Store/StoreManager.swift`

```swift
// 需要添加的方法
func restorePurchases() async throws -> Int {
    // 返回恢复的购买数量
}
```

---

### 1.2 付费功能预览 [P0]

**目标**: 让用户在购买前了解付费内容的价值

**实现清单**:
- [ ] 流年解析页面添加"预览"模块
- [ ] 显示模糊化的解析内容示例
- [ ] 添加"解锁查看完整内容"引导
- [ ] 设计预览内容的展示样式（半透明遮罩 + 锁图标）

**代码位置**: `知几/Views/LiuNianAnalysisView.swift`

---

### 1.3 错误处理优化 [P1]

**目标**: 提升购买流程的用户体验

**实现清单**:
- [ ] 网络错误时显示友好提示
- [ ] 购买失败时提供重试选项
- [ ] 添加购买中的进度指示器
- [ ] 处理 App Store 服务不可用的情况

---

### 1.4 本地化字符串提取 [P1]

**目标**: 为后续国际化做准备

**实现清单**:
- [ ] 创建 `Localizable.strings` 文件
- [ ] 提取所有硬编码中文字符串
- [ ] 使用 `NSLocalizedString` 或 String Catalog

**涉及文件**:
- `LiuNianAnalysisView.swift`
- `ResultView.swift`
- `BaziCalculatorView.swift`
- `ExplanationSheetView.swift`

---

## Phase 2: 订阅体系（1个月）

### 2.1 订阅产品配置 [P0]

**目标**: 建立可持续的订阅收入模式

**产品设计**:

| 产品ID | 名称 | 类型 | 价格 | 权益 |
|--------|------|------|------|------|
| `com.lufi.zhiji.monthly` | 月度会员 | Auto-Renewable | ¥18/月 | 无限流年解析 |
| `com.lufi.zhiji.yearly` | 年度会员 | Auto-Renewable | ¥128/年 | 无限解析 + AI报告 |
| `com.lufi.zhiji.lifetime` | 终身会员 | Non-Consumable | ¥298 | 全功能永久 |

**实现清单**:
- [ ] 在 `Products.storekit` 中添加订阅产品
- [ ] 更新 `StoreManager` 支持订阅类型
- [ ] 实现订阅状态检查 `isSubscriptionActive()`
- [ ] 处理订阅过期逻辑
- [ ] 实现优雅降级（订阅过期后的处理）

**代码位置**: `知几/Store/`

```swift
// 新增产品ID
enum ProductID: String, CaseIterable {
    case liuNianAnalysis = "com.lufi.zhiji.liunian_analysis"
    case monthlySubscription = "com.lufi.zhiji.monthly"
    case yearlySubscription = "com.lufi.zhiji.yearly"
    case lifetimePurchase = "com.lufi.zhiji.lifetime"
}

// 新增订阅状态
var subscriptionStatus: SubscriptionStatus {
    // .active, .expired, .none
}
```

---

### 2.2 会员中心页面 [P0]

**目标**: 集中展示订阅选项和会员权益

**实现清单**:
- [ ] 创建 `MembershipView.swift`
- [ ] 设计订阅方案对比卡片
- [ ] 显示当前订阅状态
- [ ] 添加管理订阅入口（跳转系统设置）
- [ ] 显示订阅到期时间

**UI设计要点**:
```
┌─────────────────────────────────────┐
│         解锁全部功能                  │
├─────────────────────────────────────┤
│  ┌─────────┐  ┌─────────┐          │
│  │ 月度会员 │  │ 年度会员 │ ← 推荐    │
│  │ ¥18/月  │  │ ¥128/年 │          │
│  │         │  │ 省59%   │          │
│  └─────────┘  └─────────┘          │
│                                     │
│  ┌─────────────────────────────┐   │
│  │      终身会员 ¥298           │   │
│  │      一次付费，永久使用        │   │
│  └─────────────────────────────┘   │
│                                     │
│  会员权益:                           │
│  ✓ 无限命盘流年解析                  │
│  ✓ AI深度解读无限使用                │
│  ✓ 专属客服支持                      │
└─────────────────────────────────────┘
```

---

### 2.3 付费墙优化 [P0]

**目标**: 提高付费转化率

**实现清单**:
- [ ] 重新设计 `LiuNianAnalysisView` 中的付费墙
- [ ] 添加订阅选项（除了单次购买）
- [ ] 显示"已有X人解锁"社会证明
- [ ] 添加限时优惠倒计时（可选）
- [ ] A/B测试不同付费墙设计

**付费墙层级**:
```
用户点击流年解析
    ↓
检查订阅状态
    ├── 已订阅 → 直接显示内容
    └── 未订阅 → 显示付费墙
                  ├── 订阅方案（推荐）
                  └── 单次购买（¥12）
```

---

### 2.4 免费试用期 [P1]

**目标**: 降低付费门槛，提高转化

**实现清单**:
- [ ] 新用户赠送1次免费流年解析
- [ ] 在 `UserDefaults` 中记录试用状态
- [ ] 试用后引导订阅
- [ ] 显示"您已使用免费体验"提示

```swift
// 试用状态管理
struct TrialManager {
    static let freeTrialKey = "hasUsedFreeTrial"

    static var hasUsedFreeTrial: Bool {
        UserDefaults.standard.bool(forKey: freeTrialKey)
    }

    static func markTrialUsed() {
        UserDefaults.standard.set(true, forKey: freeTrialKey)
    }
}
```

---

## Phase 3: 功能扩展（2-3个月）

### 3.1 八字合盘功能 [P0]

**目标**: 新增高价值付费功能

**功能描述**: 分析两个人八字的匹配程度（情侣、合作伙伴）

**实现清单**:
- [ ] 创建 `HePanView.swift` - 合盘输入页
- [ ] 创建 `HePanResultView.swift` - 合盘结果页
- [ ] 实现 `HePanCalculator.swift` - 合盘算法
  - [ ] 日主五行相生相克分析
  - [ ] 十神互补分析
  - [ ] 地支合冲分析
  - [ ] 综合匹配度评分
- [ ] 添加内购产品 `com.lufi.zhiji.hepan` (¥18)
- [ ] 订阅用户免费使用

**算法要点**:
```
匹配度计算 =
    日主关系权重 (40%)
  + 十神互补权重 (30%)
  + 地支关系权重 (20%)
  + 五行平衡权重 (10%)
```

---

### 3.2 年度运势报告 [P1]

**目标**: 提供可导出的专业报告

**实现清单**:
- [ ] 创建 `AnnualReportView.swift`
- [ ] 设计报告模板（12个月逐月分析）
- [ ] 集成 AI 生成个性化内容
- [ ] 实现 PDF 导出功能
- [ ] 添加分享功能
- [ ] 内购定价 ¥28

**报告内容结构**:
```
年度运势报告
├── 年度总览
├── 事业运势（按月）
├── 财运分析（按月）
├── 感情运势（按月）
├── 健康提醒
├── 重要时间节点
└── 年度建议
```

---

### 3.3 起名建议功能 [P2]

**目标**: 基于八字提供取名建议

**实现清单**:
- [ ] 创建 `NamingView.swift`
- [ ] 实现起名算法
  - [ ] 根据喜用神确定宜用五行
  - [ ] 字库按五行分类
  - [ ] 姓名五格计算
- [ ] 集成 AI 生成名字寓意解释
- [ ] 内购定价 ¥38

---

### 3.4 每日运势推送 [P2]

**目标**: 提高用户留存和打开率

**实现清单**:
- [ ] 集成本地通知 (UserNotifications)
- [ ] 创建 `DailyFortuneView.swift`
- [ ] 实现每日运势算法（流日干支 + 命盘互动）
- [ ] 设计通知内容模板
- [ ] 用户可设置推送时间
- [ ] 订阅用户专属功能

---

## Phase 4: 增长引擎（3-6个月）

### 4.1 用户账户系统 [P0]

**目标**: 数据云同步，多设备使用

**实现清单**:
- [ ] 集成 Sign in with Apple
- [ ] 创建 `UserManager.swift`
- [ ] 实现 iCloud 数据同步
  - [ ] 已保存的命盘
  - [ ] 购买记录
  - [ ] 用户偏好设置
- [ ] 创建 `SettingsView.swift`
- [ ] 添加账户管理页面

**数据模型**:
```swift
struct UserProfile: Codable {
    let id: String
    var savedBazi: [SavedBazi]
    var purchaseHistory: [PurchaseRecord]
    var preferences: UserPreferences
}
```

---

### 4.2 分享裂变功能 [P0]

**目标**: 通过社交分享获取新用户

**实现清单**:
- [ ] 命盘结果生成分享图片
- [ ] 集成系统分享 Sheet
- [ ] 设计分享图片模板（带二维码/App链接）
- [ ] 分享成功奖励积分
- [ ] 积分兑换付费功能

**分享图片设计**:
```
┌─────────────────────────────────┐
│  我的八字命盘                    │
│                                 │
│    甲  丙  戊  庚                │
│    子  午  辰  申                │
│                                 │
│  日主：戊土 | 身强              │
│  喜用神：金、水                  │
│                                 │
│  ─────────────────             │
│  扫码查看你的命盘               │
│  [二维码]                       │
│  知几 · 知命知己                │
└─────────────────────────────────┘
```

---

### 4.3 邀请奖励系统 [P1]

**目标**: 激励用户邀请新用户

**实现清单**:
- [ ] 生成用户专属邀请码
- [ ] 新用户注册时填写邀请码
- [ ] 双方各获得1次免费流年解析
- [ ] 创建 `InviteView.swift`
- [ ] 邀请记录页面

**规则设计**:
```
邀请人奖励：
  - 每成功邀请1人 → 1次免费流年解析
  - 邀请满5人 → 1个月会员
  - 邀请满10人 → 3个月会员

被邀请人奖励：
  - 注册即得1次免费流年解析
```

---

### 4.4 深色模式支持 [P1]

**目标**: 提升夜间使用体验

**实现清单**:
- [ ] 更新 `DesignSystem.swift` 添加深色配色
- [ ] 所有颜色使用 `Color` 的动态颜色
- [ ] 测试所有页面的深色模式显示
- [ ] 添加手动切换选项（跟随系统/浅色/深色）

```swift
// DesignSystem 更新
extension DesignSystem {
    static var background: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(hex: "#1A1A1A")
                : UIColor(hex: "#FFFFFF")
        })
    }
}
```

---

### 4.5 多语言支持 [P2]

**目标**: 拓展海外市场

**支持语言**:
- [ ] 简体中文（已有）
- [ ] 繁体中文
- [ ] English
- [ ] 日本語（潜在市场）

**实现清单**:
- [ ] 创建 String Catalog
- [ ] 翻译所有UI文本
- [ ] 翻译命理术语（需要专业翻译）
- [ ] 测试各语言显示

---

## Phase 5: 技术优化（持续进行）

### 5.1 代码重构 [P0]

**目标**: 提高代码可维护性

**实现清单**:
- [ ] 拆分 `ResultView.swift`（当前1000+行）
  - [ ] `ResultHeaderView` - 四柱展示
  - [ ] `DayMasterCardView` - 日主卡片
  - [ ] `WuXingChartView` - 五行图表
  - [ ] `ShiShenChartView` - 十神图表
  - [ ] `DaYunSectionView` - 大运区域
- [ ] 创建显式 ViewModel 层
- [ ] 统一错误处理机制

---

### 5.2 性能优化 [P1]

**实现清单**:
- [ ] 命理计算结果缓存优化
- [ ] 图片资源压缩
- [ ] 启动时间优化
- [ ] 内存使用优化

---

### 5.3 测试覆盖 [P1]

**实现清单**:
- [ ] 核心算法单元测试（目标覆盖率80%）
  - [ ] `BaziCalculations` 测试
  - [ ] `StrengthCalculator` 测试
  - [ ] `ShiShenAnalysis` 测试
- [ ] UI 快照测试
- [ ] 内购流程集成测试

---

### 5.4 监控与分析 [P2]

**实现清单**:
- [ ] 集成 Firebase Analytics
- [ ] 关键事件埋点
  - [ ] 页面浏览
  - [ ] 付费转化漏斗
  - [ ] 功能使用频率
- [ ] 崩溃监控（Firebase Crashlytics）
- [ ] 性能监控

---

## 优先级总览

### P0 - 必须完成（影响收入和用户体验）
1. 恢复购买功能
2. 付费功能预览
3. 订阅产品配置
4. 会员中心页面
5. 付费墙优化
6. 八字合盘功能
7. 用户账户系统
8. 分享裂变功能
9. 代码重构

### P1 - 重要（提升竞争力）
1. 错误处理优化
2. 本地化字符串提取
3. 免费试用期
4. 年度运势报告
5. 邀请奖励系统
6. 深色模式支持
7. 性能优化
8. 测试覆盖

### P2 - 增强（锦上添花）
1. 起名建议功能
2. 每日运势推送
3. 多语言支持
4. 监控与分析

---

## 收入预测模型

### 当前模式
```
用户数: 1000
付费转化率: 5%
ARPU: ¥12
月收入: 1000 × 5% × ¥12 = ¥600
```

### 优化后预测
```
用户数: 1000 → 3000（分享裂变）
付费转化率: 5% → 15%（试用期+付费墙优化）
ARPU: ¥12 → ¥50（订阅模式）
月收入: 3000 × 15% × ¥50 = ¥22,500

增长: 3750%
```

---

## 里程碑检查点

| 里程碑 | 完成标准 | 目标日期 |
|--------|---------|---------|
| M1 基础完善 | 恢复购买上线，付费预览完成 | +2周 |
| M2 订阅上线 | 订阅系统完整可用 | +6周 |
| M3 功能扩展 | 合盘功能上线 | +12周 |
| M4 增长引擎 | 分享+邀请系统上线 | +20周 |
| M5 全面优化 | 代码重构完成，测试覆盖达标 | +26周 |

---

## 附录：文件创建清单

### 新增文件
```
知几/
├── Views/
│   ├── MembershipView.swift      # 会员中心
│   ├── HePanView.swift           # 合盘输入
│   ├── HePanResultView.swift     # 合盘结果
│   ├── AnnualReportView.swift    # 年度报告
│   ├── NamingView.swift          # 起名功能
│   ├── DailyFortuneView.swift    # 每日运势
│   ├── SettingsView.swift        # 设置页面
│   ├── InviteView.swift          # 邀请页面
│   └── Result/                   # ResultView 拆分
│       ├── ResultHeaderView.swift
│       ├── DayMasterCardView.swift
│       ├── WuXingChartView.swift
│       ├── ShiShenChartView.swift
│       └── DaYunSectionView.swift
├── Utils/
│   ├── HePanCalculator.swift     # 合盘算法
│   ├── DailyFortuneCalculator.swift
│   └── NamingCalculator.swift
├── Store/
│   └── TrialManager.swift        # 试用管理
├── Managers/
│   ├── UserManager.swift         # 用户管理
│   └── CloudSyncManager.swift    # iCloud 同步
└── Resources/
    ├── Localizable.strings       # 本地化
    └── Localizable.strings (zh-Hant)
```

---

*文档版本: 1.0*
*生成日期: 2026-01-23*
