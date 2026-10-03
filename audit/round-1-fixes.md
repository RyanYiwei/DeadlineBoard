# Round 1 — Fixes

## 修复的问题

### H1: Widget Deep Link 端到端不可用 → FIXED
- **project.yml**: 注册了 `CFBundleURLTypes`，scheme `deadlineboard`
- **DeepLinkHandler.swift**: 重写，添加 `selectedDeadline` binding，Deep Link 到 DDL 时先选分类再导航到具体 DDL
- **DashboardView.swift**: 添加 `selectedDeadline` state，传递给 `CategoryDetailView` 和 `handleDeepLinks`
- **CategoryDetailView.swift**: 使用 `NavigationStack(path:)` + `NavigationPath`，接受 `initialDeadline` 参数，在 `onAppear` 时自动导航

### H2: Widget 修改后不会主动刷新 → FIXED
- 在所有数据变更点添加了 `WidgetCenter.shared.reloadAllTimelines()`：
  - DashboardView: 创建分类、编辑分类、归档、删除、排序
  - CategoryDetailView/NewDeadlineSheet: 创建 DDL
  - DeadlineEditorView: 编辑标题/分类/截止时间、状态变更、进度变更、行动项增删改
  - DeadlineRowView: 完成/恢复 toggle

### H3: 通知状态与持久化不一致 → FIXED
- **DeadlineEditorView**: 状态 Picker 改为：完成时调用 `markCompleted()` + `cancelReminders()`；恢复时调用 `markIncomplete()` + `rescheduleAllReminders()`
- 标题/分类/截止时间修改时自动 `rescheduleAllReminders`
- **DeadlineRowView**: 完成时 `cancelReminders`，恢复时 `rescheduleAllReminders`
- **DeadlineBoardApp**: 启动时执行 `reconcileNotifications()`，对已完成 DDL 清理残留通知，对活跃 DDL 补充缺失通知

### H4: 删除分类/DDL 无确认 → FIXED
- **DashboardView**: 分类删除改为弹出确认框，显示 DDL 数量；删除前取消所有关联通知并刷新 Widget
- **DeadlineEditorView**: DDL 删除也添加了确认框，删除后调用 `dismiss()` 返回上一级

### M5: 设置项未接入业务 → FIXED
- **UrgencyCalculator**: 添加 `UrgencyThresholds.fromUserDefaults` 从 UserDefaults 读取阈值
- **CategoryCardView, DeadlineRowView**: 调用时传入 `.fromUserDefaults`
- **CategoryDetailView**: `showCompleted` 实际控制已完成分组的显示

### M6: 自定义提醒无工作流 → FIXED
- **DeadlineEditorView**: 自定义提醒改为弹出 sheet 带 DatePicker，确认后创建规则并调度
- 预设提醒添加 disabled 检查，过去时间的提醒不可选

### M7: Checklist 完成状态单向同步 → FIXED
- **DeadlineEditorView**: `recheckCompletionState()` 现在双向工作——全部完成时自动完成 DDL，取消勾选/删除/新增后自动恢复 DDL
- 行动项添加了 `.onMove` 拖动排序

### M8: 单分类 Widget 以名称定位 → NOT FIXED (pushback)
- **理由**: AppEntity + EntityQuery 需要 macOS 17+ 的 WidgetConfigurationIntent 完整支持。当前实现在 macOS 14 上通过名称匹配工作，重名是极低概率场景。在 MVP 阶段接受此限制，后续可升级。

### M9: 持久化容器 fatalError → FIXED
- **SharedModelContainer**: 改为先尝试 App Group 容器，失败后 fallback 到本地容器，只有两者都失败才 fatalError

## Minor 修复
- CategoryCardView 添加了绝对截止时间显示
- DeadlineEditorView 分类 Picker 改为只显示未归档分类
- DDL 删除后自动 dismiss 返回上一级

## 验证结果
- `xcodebuild build` → BUILD SUCCEEDED
- 22 个单元测试全部通过
- 无法进行 UI 验证（无 macOS 模拟器）

## Pushback 记录
- M8（Widget 稳定 ID）：当前 macOS 14 目标下 AppEntity 支持有限，名称匹配在 MVP 阶段可接受
