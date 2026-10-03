# Round 3 — Fixes

## 修复的问题

### H1: 单分类 Widget 无法选择分类（需要手输 UUID）→ FIXED
- **SingleCategoryWidget.swift**: 实现 `CategoryEntity: AppEntity` 和 `CategoryEntityQuery: EntityQuery`
- `suggestedEntities()` 从 App Group 数据库读取所有未归档分类，返回名称列表供用户选择
- `entities(for:)` 通过 UUID 查询具体分类
- `SelectCategoryIntent` 的参数从 `categoryId: String?` 改为 `category: CategoryEntity?`
- Provider 通过 `configuration.category?.id` 获取 UUID

### H2: 主 App 静默切换数据库 → FIXED
- **SharedModelContainer.swift**: 新增 `static private(set) var isUsingSharedStore` 属性，追踪当前使用的 store 类型
- **DashboardView.swift**: 添加 `safeAreaInset(edge: .bottom)` 底部警告条，当 `!SharedModelContainer.isUsingSharedStore` 时显示 "App Group 不可用，Widget 数据无法同步"

### H3: saveAndReloadWidgets 保存失败仍刷新 Widget → FIXED
- **ModelContextExtension.swift**: `saveAndReloadWidgets()` 改为 `@discardableResult func -> Bool`
- 使用 `do { try self.save() } catch { return false }` — 只有保存成功才调用 `reloadAllTimelines()`
- 保存失败返回 false，调用方可选择检查返回值

### H4: 删除 DDL 后 onDisappear 操作已删除对象 → FIXED
- **DeadlineEditorView.swift**: 新增 `@State private var isDeleted = false`
- 删除按钮先设置 `isDeleted = true`，再执行删除和 dismiss
- `onDisappear` 增加 `guard !isDeleted else { return }` 跳过通知重调度

### M5: 提醒规则未先持久化再操作系统通知 → FIXED
- **DeadlineEditorView.swift**: 以下路径在操作 UNUserNotificationCenter 前先调用 `try? modelContext.save()`：
  - 启停提醒 Toggle
  - 删除提醒按钮
  - 添加预设提醒
  - 添加自定义提醒

### M7: 设置阈值无约束 → FIXED
- **SettingsView.swift**: Stepper 取值范围互相约束：
  - warningDays: `max(urgentDays + 1, 7)...90`
  - urgentDays: `1...min(warningDays - 1, 30)`
  - criticalHours: `1...min(urgentDays * 24, 72)`
- 保证 `criticalHours < urgentDays <= warningDays` 不会倒置

### Minor: ProgressWidget 错误状态 → FIXED
- **ProgressWidget.swift**: 添加 `isError` 字段和 `unavailable` 静态条目
- App Group 失败时显示 "需要配置 App Group" 而不是 "没有进行中的 DDL"

## 验证结果
- `xcodebuild build` → BUILD SUCCEEDED
- 22 个单元测试全部通过
- 无法进行 UI 验证（无 macOS 模拟器）
