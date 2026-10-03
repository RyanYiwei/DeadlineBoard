# Round 1 — Codex Review

**Thread ID**: `01a0fe59-424d-79b3-853c-af663e06ab3d`

## 原始回复

总体结论：核心本地数据模型、CRUD 和排序逻辑基本成立，但 Widget、Deep Link、设置和通知链路尚未闭合，不满足项目基线的全部成功标准。

```text
Functional completeness: 5.5/10
Lightweight design: 8.5/10
Memory & concurrency safety: 9.0/10
Network & server security: N/A
Privacy & data-leak risk: 9.0/10
Data reliability: 5.5/10
```

**OVERALL SCORE：7.8/10**

网络维度确认为 N/A，权重已按比例分配给其余维度。

### A. Current capabilities

代码当前确实可以：

- 使用 SwiftData 在 App Group 容器中持久化分类、DDL、行动项和提醒规则。
- 创建、编辑、归档、恢复、删除分类，并拖动调整分类顺序。
- 创建、编辑、删除、完成和恢复 DDL。
- 根据"逾期优先、截止时间、优先级、创建时间"选择每个分类最紧迫的 DDL。
- 按逾期、进行中、未开始、已完成对 DDL 分组。
- 计算手动进度及 checklist 进度。
- 创建、启停和删除预设相对提醒，并在部分操作路径中更新系统通知。
- 实现了三种 Widget 的展示代码，并从同一 App Group SwiftData 数据库读取数据。
- 显示通知权限状态并请求权限。
- 持久化四个设置值，但其中业务设置目前没有实际生效。
- 提供 22 个纯逻辑单元测试，覆盖查询、进度、紧迫度和日期文本。

系统实际读写的状态包括：

- App Group 中的 SwiftData 数据库：分类、DDL、备注、行动项、提醒规则等。
- 标准 `UserDefaults`：紧迫度阈值、是否显示已完成项目。
- `UNUserNotificationCenter` 中的待发送本地通知。
- WidgetKit 保存的单分类 Widget 字符串配置。
- 当前选择、弹窗状态等 SwiftUI `@State`，这些不会跨重启恢复。

功能状态表：

| 状态 | 功能 |
|---|---|
| Fully implemented | 核心数据模型；分类 CRUD/归档/排序；DDL 基本 CRUD；最紧迫 DDL 查询；DDL 分组；手动及 checklist 进度计算；本地持久化 |
| Partially implemented | 通知；三种 Widget；完成/恢复状态；Deep Link；DDL 编辑；行动项管理；崩溃恢复；设置页面 |
| Not implemented | 可用的自定义提醒时间选择；行动项拖动排序；设置项接入业务；数据修改后主动刷新 Widget；打开指定 DDL 的 Deep Link；SwiftUI Preview 示例数据；通知与数据库启动时对账 |
| Not applicable / not claimed | 网络同步、导入、断点续传、网络重试、上传去重、服务端清理 |

正常退出或重启后，SwiftData、UserDefaults 和系统通知通常能够保留；但代码依赖 SwiftData 自动保存，没有显式提交点。数据库与通知中心又是两个独立状态源，崩溃发生在两者更新之间时，重启后没有自动修复机制。

### B. Critical problems

未发现 Critical 严重度的安全漏洞、远程攻击面或确定性的无交互数据损毁问题。

项目仍不应标记为 READY，因为下面几项 High/Medium 问题会直接破坏核心产品功能。

### C. Important improvements

1. **Widget Deep Link 端到端不可用或不完整**

- 文件：project.yml:30、DeepLinkHandler.swift:16
- 问题：Widget 构造了 `deadlineboard://...` URL，但工程配置没有注册 `CFBundleURLTypes`。即使手工注册 scheme，`selectDeadline` 也只设置分类，声明的 `navigateToDeadline` 从未使用。
- 触发：点击任意 Widget 行或单分类 Widget。
- 后果：系统可能无法启动 App；deadline 链接最多只能打开所属分类，不能打开目标 DDL。
- 严重程度：**High**
- 建议：在 `project.yml` 注册 URL scheme；用 `NavigationPath` 或明确的 deadline selection 驱动详情导航；增加 category/deadline/非法 UUID 三类 Deep Link 测试。

2. **Widget 修改后不会主动刷新**

- 文件：MultiCategoryWidget.swift:55、ProgressWidget.swift:49、SingleCategoryWidget.swift:82
- 问题：整个项目没有调用 `WidgetCenter.reloadTimelines`。多分类和进度 Widget 只计划到次日零点；多分类 Widget 在 DDL 到期时也没有刷新节点。
- 触发：创建、编辑、完成、删除或重新排序数据。
- 后果：Widget 最长一天显示旧标题、旧进度或已删除内容，违反"Widget 与 App 数据一致"的成功标准。
- 严重程度：**High**
- 建议：把所有数据变更收口到一个轻量 mutation/service 层，成功保存后刷新相关 Widget；timeline 至少包含次日零点和当前最紧迫 DDL 的截止时间。

3. **通知状态与持久化状态会永久不一致**

- 文件：DeadlineEditorView.swift:38、NotificationService.swift:22
- 问题：
  - 在状态 Picker 中将 DDL 标为完成不会取消通知。
  - 通过 Picker 恢复 DDL 不调用 `markIncomplete()`，手动进度可能继续保持 100%，旧进度也不会恢复。
  - 修改标题或所属分类不会更新已排定通知的内容。
  - `UNUserNotificationCenter.add` 的错误被忽略。
  - 启动时没有依据 SwiftData 重新核对待发送通知。
- 触发：从编辑页修改状态、标题、分类，或系统拒绝通知请求。
- 后果：已完成/已删除内容仍可能通知；界面显示启用但系统实际没有请求；崩溃后差异长期保留。
- 严重程度：**High**
- 建议：为状态变化建立唯一入口；所有完成路径都取消通知，恢复路径重新计算并调度；使用 async `add` 捕获错误；启动时执行一次有界的 reconciliation。

4. **删除分类会级联丢失全部内容，且没有确认，也不取消通知**

- 文件：DashboardView.swift:99、DDCategory.swift:15、ArchivedCategoriesView.swift:32
- 问题：删除分类会 cascade 删除所有 DDL、行动项和提醒规则；操作没有确认或撤销。系统通知不属于 SwiftData cascade，因此仍会残留。
- 触发：上下文菜单删除分类，或在归档页面滑动删除。
- 后果：整个分类的数据不可恢复，同时以后仍可能收到孤儿通知。
- 严重程度：**High**
- 建议：分类永久删除前显示包含 DDL 数量的确认框；优先提供归档；删除前收集所有 notification identifier 并取消；保存成功后刷新 Widget。

5. **设置页面中的两个核心设置没有作用**

- 文件：SettingsView.swift:5、UrgencyCalculator.swift:47、CategoryDetailView.swift:45
- 问题：视图写入紧迫度阈值和 `showCompleted`，但调用紧迫度计算时始终使用默认值，完成分组也始终显示。
- 触发：用户修改任一设置。
- 后果：设置看似保存成功，实际界面和 Widget 完全不变。
- 严重程度：**Medium**

6. **自定义提醒只有按钮，没有实现工作流**

- 文件：DeadlineEditorView.swift:224
- 问题：点击"自定义时间"只创建一个固定为当前时间后 24 小时的规则；没有日期选择器，也没有调用调度方法。
- 触发：添加自定义提醒。
- 后果：界面出现已启用规则，但不会产生系统通知。
- 严重程度：**Medium**

7. **Checklist 完成状态存在单向同步**

- 文件：DeadlineEditorView.swift:110
- 问题：最后一个行动项完成时会自动完成 DDL；之后取消勾选、删除或新增行动项时，不会重新打开 DDL。行动项也没有需求中要求的拖动排序。
- 触发：完成全部行动项后再修改 checklist。
- 后果：DDL 保持完成和 100%，实际 checklist 已不完整。
- 严重程度：**Medium**

8. **单分类 Widget 以名称而非稳定 ID 定位分类**

- 文件：SingleCategoryWidget.swift:24
- 问题：配置参数是任意 `String`，没有动态分类列表；查询使用分类名。重名分类会随机取第一项，重命名后配置失效。
- 触发：存在同名分类、分类重命名或用户输入不存在的名称。
- 后果：Widget 显示错误分类或"未选择"。
- 严重程度：**Medium**

9. **持久化容器失败会直接终止进程**

- 文件：SharedModelContainer.swift:24
- 问题：数据库不可打开、迁移失败或 App Group 配置错误时直接 `fatalError`。
- 触发：存储损坏、权限/签名错误、未来模型迁移不兼容。
- 后果：App 或 Widget 无法启动，没有可诊断或恢复界面。
- 严重程度：**Medium**

### D. Minor improvements

- Dashboard 分类卡片只显示相对时间，没有需求中的绝对截止时间。
- `DateFormatter` 每次渲染都重新创建；可以缓存固定格式 formatter。
- "提前 N 天"使用固定 `86400` 秒，跨夏令时时可能偏移一小时；日历型偏移宜使用 `Calendar.date(byAdding:)`。
- DDL 分类 Picker 包含已归档分类。
- 删除 DDL 后没有显式返回上一级，当前编辑视图仍绑定已删除对象。
- 允许重复添加相同提醒，会生成不同 identifier 并收到重复通知。
- 没有 SwiftUI Preview 示例数据，不符合项目约束。
- 当前测试只覆盖纯逻辑函数，没有覆盖持久化关系、级联删除、通知状态机、Widget 查询或 Deep Link。

### E. Resource analysis

- **正常使用一周**：资源占用低。
- **连续运行数月**：SwiftData 会保留所有完成/归档数据，存储持续增长，但这是用户数据而非缓存泄漏。按预期规模问题很小。
- **长时间离线**：完全不受影响；项目没有网络功能。
- **已有大数据集**：Dashboard 的 `@Query` 会加载全部活动分类，并在每张卡片中访问、过滤和排序全部关联 DDL；复杂度大致为各分类 `O(n log n)`。对预期规模足够。
- **内存/并发**：未发现引用环、未取消的无限 Task、订阅、文件句柄或 timer。

### F. Security & privacy analysis

**网络与服务端安全：N/A。** 代码没有网络功能。

隐私方面：数据存储在 App Group 容器中，受 macOS 用户账户、App Sandbox 和可选 FileVault 保护。通知内容会显示分类名、DDL 标题、相对时间和进度。没有敏感数据泄漏风险。

### G. Data-loss scenarios

1. 误删分类会级联删除该分类的全部数据，无确认。
2. 删除 DDL 同样没有确认。
3. 数据库修改和通知中心操作不是事务。
4. 通过状态 Picker 恢复完成 DDL 时，完成前进度不会正确恢复。
5. 依赖 SwiftData autosave。
6. 存储容器失败时 App 直接崩溃。
7. 重复提醒规则没有去重。

### H. Final verdict

1. 是否足够轻量？ 是。
2. 是否适合长期连续运行？ 资源上适合；功能正确性上需要先修复。
3. 是否存在明显内存/资源泄漏？ 未发现。
4. 是否存在明显数据泄漏？ 无。
5. 真实网络攻击面？ N/A。
6. 能否安全用于真实数据？ 可用于试用；在无确认级联删除、通知状态不一致修复前，不建议作为唯一可靠 DDL 记录。
7. 正式使用前最应修复：注册 Deep Link；刷新 Widget；统一通知状态；删除确认；设置生效。

**Verdict：REVISE**
