# Round 2 — Fixes

## 修复的问题

### C1: Deep Link plist 格式错误 → FIXED (High)
- **Info.plist**: 创建了独立的 `DeadlineBoard/Info.plist`，CFBundleURLTypes 是原生 plist 数组（不再是 XML 字符串）
- **project.yml**: 移除 `GENERATE_INFOPLIST_FILE` 和所有 `INFOPLIST_KEY_*`，改用 `INFOPLIST_FILE: DeadlineBoard/Info.plist`
- **验证**: `plutil -p` 确认 CFBundleURLTypes 是正确的 `[Dictionary]` 类型

### C1 续: Deep Link deadline 导航时序 → FIXED (High)
- **DeepLinkHandler.swift**: 移除 `DispatchQueue.main.asyncAfter(deadline: .now() + 0.1)` 延迟，同步设置 selectedCategory 和 selectedDeadline
- **CategoryDetailView.swift**: `initialDeadline` 改为 `@Binding`，添加 `onChange(of: initialDeadline?.id)` 处理同分类的后续 Deep Link；`onAppear` 处理首次加载
- **DashboardView.swift**: 传递 `$selectedDeadline` 作为 Binding，移除 `.onAppear { selectedDeadline = nil }`（由 CategoryDetailView 在导航后自行清除）

### C2: App Group fallback 双数据库 → FIXED (High)
- **SharedModelContainer.swift**: 新增 `createForWidget()` 方法，仅尝试 App Group 容器，失败返回 nil（不会创建私有本地数据库）
- **SingleCategoryWidget**: 使用 `createForWidget()`，失败时显示 "需要配置 App Group" 错误条目
- **MultiCategoryWidget**: 同上，失败显示错误条目
- **ProgressWidget**: 同上，失败返回空条目
- 主 App 保留 fallback 到本地的能力（开发/未签名环境需要），但 Widget 不再创建独立的数据库

### C3: Widget reload 与数据库保存竞态 → FIXED (High)
- **ModelContextExtension.swift**: 新增 `ModelContext.saveAndReloadWidgets()` 扩展方法，先 `try? self.save()` 再 `reloadAllTimelines()`
- 所有数据变更点从直接调用 `WidgetCenter.shared.reloadAllTimelines()` 改为 `modelContext.saveAndReloadWidgets()`
- 涉及文件：DashboardView, CategoryDetailView, DeadlineEditorView, DeadlineRowView, ArchivedCategoriesView

### C7: 归档页面无确认删除 → FIXED (High)
- **ArchivedCategoriesView.swift**: 
  - `.onDelete` 不再直接删除，改为设置 `categoryToDelete` 触发确认框
  - 确认框显示分类名称和 DDL 数量
  - 删除前清理所有关联通知 `cancelReminders(for:)`
  - 删除后调用 `saveAndReloadWidgets()`
  - 恢复归档分类也调用 `saveAndReloadWidgets()`

### M4: Widget 刷新点不完整 → FIXED (Medium)
- **ArchivedCategoriesView**: 恢复和删除归档分类都添加了 Widget 刷新
- **DeadlineEditorView**: 优先级 Picker 添加 `onChange` + Widget 刷新；进度模式 Picker 添加 Widget 刷新 + `recheckCompletionState()`
- **MultiCategoryWidget**: timeline 策略改为取所有分类最近截止时间与次日零点的较小值

### M5: 高频 Widget 和通知刷新 → FIXED (Medium)
- **DeadlineEditorView**: 
  - 移除标题 TextField 的 `onChange`（不再每个字符都 reschedule 通知 + reload Widget）
  - Slider 改用 `onEditingChanged` 参数，仅在拖动结束时 `saveAndReloadWidgets()`
  - 添加 `.onDisappear` 统一执行 `rescheduleAllReminders` + `saveAndReloadWidgets()`（捕获标题等变更）
  - 保留分类/截止时间的 `onChange`（这些是 Picker 单次选择，不会高频触发）

### M6: 通知 reconciliation 不完整 → IMPROVED (Medium)
- **DeadlineBoardApp.swift**: reconciliation 现在会：
  - 删除已完成 DDL 的通知（与之前相同）
  - 删除已禁用规则的 pending 通知（新增）
  - 删除过去时间规则的 pending 通知（新增）
  - 为缺失通知的活跃启用规则重新调度（改进：标记后统一调度，避免重复）

### M8: 单分类 Widget 稳定 ID → FIXED (Medium)
- Codex 裁决 OVERRULED，已修复
- **SelectCategoryIntent**: `categoryName: String?` 改为 `categoryId: String?`（存储 UUID 字符串）
- **SingleCategoryProvider**: 通过 UUID 而非名称查询分类
- 分类重命名后 Widget 配置不会失效；UUID 是唯一且不可变的

### M5 续: 设置仅部分生效 → FIXED (Medium)
- **AppConstants**: 新增 `appGroupDefaults` 静态属性（使用 App Group suite 的 UserDefaults）
- **UrgencyCalculator**: `fromUserDefaults` 改为读取 `AppConstants.appGroupDefaults`
- **SettingsView**: 紧迫度阈值的 `@AppStorage` 改为使用 `store: AppConstants.appGroupDefaults`
- Widget 中的 urgency 计算现在使用 `.fromUserDefaults`（SingleCategoryWidget, MultiCategoryWidget）
- 阈值变更时触发 `WidgetCenter.shared.reloadAllTimelines()`

## 验证结果
- `xcodebuild build` → BUILD SUCCEEDED
- `plutil -p Info.plist` 确认 CFBundleURLTypes 是正确的 plist 数组类型
- 22 个单元测试全部通过
- 无法进行 UI 验证（无 macOS 模拟器）

## 新增文件
- `DeadlineBoard/Info.plist` — 主 App 的 Info.plist（替代 GENERATE_INFOPLIST_FILE）
- `Shared/Extensions/ModelContextExtension.swift` — ModelContext.saveAndReloadWidgets() 扩展
