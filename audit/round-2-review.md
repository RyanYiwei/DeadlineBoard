复审结论：本轮确实修复了自定义提醒和 checklist 双向状态等问题，但修复记录明显高估了 Deep Link、Widget 刷新、通知对账、删除保护和容器降级的完成度，并引入了本地数据库与 App Group 数据库分叉的新风险。

```text
Functional completeness: 6.8/10
Lightweight design: 7.8/10
Memory & concurrency safety: 8.8/10
Network & server security: N/A
Privacy & data-leak risk: 9.0/10
Data reliability: 5.8/10
```

**OVERALL SCORE：7.9/10**

网络维度确认为 N/A，权重已按比例分配给其余维度。

### A. Current capabilities

本轮新增并确认有效的能力包括：

- Dashboard 删除分类前显示确认框，并清理关联通知。
- DDL 删除前显示确认框，删除后返回上一级。
- 自定义提醒提供 DatePicker，过去时间无法添加。
- Checklist 行动项取消勾选、添加或删除后可以自动重新打开 DDL。
- 行动项支持拖动排序。
- CategoryCard 和 DeadlineRow 开始读取用户定义的紧迫度阈值。
- `showCompleted` 可以控制分类详情中的已完成分组。
- 标题、所属分类、截止时间、状态和部分进度修改会请求刷新 Widget。
- 启动时执行了一轮有限的通知检查。

修复状态：

| 问题 | 状态 | 结论 |
|---|---|---|
| H1 Deep Link | **PARTIALLY RESOLVED** | 添加了处理代码，但 URL scheme 类型配置有误，deadline 导航时序也仍然失败 |
| H2 Widget 刷新 | **PARTIALLY RESOLVED** | 大量变更点已添加 reload，但并非全部；没有先保存数据库，并可能过度刷新 |
| H3 通知一致性 | **PARTIALLY RESOLVED** | 状态路径改善，但 reconciliation 不清理禁用/孤儿请求，调度错误仍被忽略 |
| H4 删除确认 | **PARTIALLY RESOLVED** | Dashboard 分类和 DDL 已修；归档页面仍可无确认级联删除 |
| M5 设置生效 | **PARTIALLY RESOLVED** | 主 App 部分生效；Widget 不使用阈值，设置改变也未形成可靠刷新依赖 |
| M6 自定义提醒 | **RESOLVED** | DatePicker、未来时间校验和通知调度均存在 |
| M7 Checklist 双向 | **RESOLVED** | 主要双向逻辑和拖动排序已经实现 |
| M8 Widget 稳定 ID | **STILL OPEN** | 仍按可变且可重复的分类名称查询 |
| M9 容器降级 | **PARTIALLY RESOLVED** | 避免了首次失败直接崩溃，但引入静默双数据库和"数据消失"风险 |

第一轮 Minor 修复状态：

- 分类卡片绝对日期：**RESOLVED**
- DDL 分类 Picker 排除归档分类：**RESOLVED**
- 删除 DDL 后退出编辑页：**RESOLVED**
- SwiftUI Preview：**STILL OPEN**
- DateFormatter 重复创建、DST 固定秒数偏移、提醒去重、集成测试：**STILL OPEN**

### B. Critical problems

未发现 Critical 严重度的远程安全漏洞或内存破坏问题。

但新的数据库 fallback 设计具有明显的数据可靠性风险，正式使用前必须修正。

### C. Important improvements

1. **Deep Link 仍未端到端修复**

- 文件：project.yml:39、DeepLinkHandler.swift:46、DashboardView.swift:22
- 问题一：`CFBundleURLTypes` 被写成了包含 XML 的字符串。生成的 Xcode 工程同样显示：

  ```text
  INFOPLIST_KEY_CFBundleURLTypes = "<array>...</array>";
  ```

  这不是 plist 所要求的 `[Dictionary]` 类型。项目能够编译不等于 Launch Services 会将它识别为 URL scheme。
- 问题二：deadline 处理先设置分类，延迟 0.1 秒后才设置 `selectedDeadline`。分类详情此时已经以 `initialDeadline == nil` 执行过 `onAppear`；其 identity 只取决于 category ID，后续 deadline 改变不会重新触发 `onAppear`。
- 触发：点击单分类 Widget 中的 DDL。
- 后果：App 可能无法被 scheme 启动；即便启动，也很可能只进入分类而不导航到 DDL。
- 严重程度：**High**
- 建议：
  - 使用 XcodeGen 的 `info.properties` 生成真正的 `CFBundleURLTypes` 数组，或提供真实 Info.plist。
  - 删除基于 0.1 秒延迟的时序方案。
  - 在详情视图使用 `onChange(of: initialDeadline?.id, initial: true)`，或由 Dashboard 直接持有导航路径。
  - 构建后用 `plutil -p DeadlineBoard.app/Contents/Info.plist` 验证最终类型。

2. **App Group fallback 会形成静默的"双数据库"**

- 文件：SharedModelContainer.swift:17
- 问题：App Group 打开失败后，主 App 会改用自己的本地数据库；Widget Extension 也会独立执行相同逻辑，但其本地容器属于另一个 sandbox。
- 触发：App Group 签名配置错误、只有一方成功打开、暂时失败后恢复。
- 后果：主 App 与 Widget 数据不一致；fallback 数据会"消失"。
- 严重程度：**High**
- 建议：不要无提示地切换持久化位置。主 App 应显示降级状态并禁用 Widget，记录当前 store 选择；Widget 打不开共享库时应显示错误 entry。

3. **Widget reload 与数据库保存存在竞态**

- 文件：DashboardView.swift:39、DeadlineEditorView.swift:17
- 问题：数据修改后立即调用 `reloadAllTimelines()`，但没有先调用 `modelContext.save()`。
- 后果：Widget 可能读取修改前的数据库。
- 严重程度：**High**
- 建议：集中实现 `saveAndReloadWidgets()`，确认 `modelContext.save()` 成功后再刷新。

4. **Widget 刷新点仍不完整**

- 文件：ArchivedCategoriesView.swift:27、DeadlineEditorView.swift:43
- 缺失路径：恢复归档分类、从归档删除、修改优先级、修改进度模式。
- 严重程度：**Medium**

5. **新引入了高频 Widget 和通知刷新**

- 文件：DeadlineEditorView.swift:20
- 问题：标题每输入一个字符都会重新调度全部提醒并刷新所有 Widget。
- 严重程度：**Medium**
- 建议：文本编辑结束时更新；Slider 使用编辑结束回调。

6. **通知 reconciliation 仍然不是完整对账**

- 文件：DeadlineBoardApp.swift:30、NotificationService.swift:43
- 不会：删除已禁用规则的 pending request、删除孤儿通知、处理调度错误。
- 严重程度：**Medium**

7. **归档页面仍能无确认级联删除分类**

- 文件：ArchivedCategoriesView.swift:32
- 问题：`.onDelete` 直接删除分类，没有确认、通知清理或 Widget 刷新。
- 严重程度：**High**

8. **设置仅部分生效**

- 文件：UrgencyCalculator.swift:45、SingleCategoryWidget.swift:144、MultiCategoryWidget.swift:124
- 问题：Widget 仍使用默认阈值；设置保存在 `UserDefaults.standard` 而非 App Group suite。
- 严重程度：**Medium**

### M8 Pushback 裁决

**OVERRULED**

理由：
- 当前目标是 macOS 14，代码已经使用 `AppIntentConfiguration` 和 `WidgetConfigurationIntent`。
- `AppEntity`/`EntityQuery` 可用于该部署目标的实体参数。
- 分类重命名是已经实现的正常操作，不是极端情况。
- 项目没有限制分类名唯一。

应改为保存分类 UUID，并在展示时查询名称。M8 保持 **STILL OPEN**。

### D. Minor improvements

- 切换 `progressMode` 时没有调用 `recheckCompletionState()`，也没有刷新 Widget。
- 行动项重新排序后没有统一保存。
- 相对提醒仍以固定秒数计算，跨夏令时时可能偏移。
- 相同相对提醒可以重复添加。
- `DateFormatter` 仍在每次格式化时重新创建。
- 仍没有 SwiftUI Preview。
- 22 个现有测试没有增加任何针对本轮修复的覆盖。

### E. Resource analysis

- **正常使用一周**：数据库规模和内存占用仍然很低，没有常驻 timer、轮询或网络任务。
- **连续运行数月**：业务数据库按用户数据自然增长，没有缓存泄漏。fallback 可能额外创建第二份数据库。
- **长时间离线**：没有影响，项目不依赖网络。
- **已有大数据集**：仍会按分类加载并排序关联 DDL，符合预期的几百条规模。
- **新增资源回归**：逐字符重排通知、Slider 高频 `reloadAllTimelines`、DatePicker 连续重排通知。

### F. Security & privacy analysis

**网络与服务端安全：N/A。**

隐私结论与第一轮一致：没有分析 SDK、网络上报或敏感日志。

### G. Data-loss scenarios

1. App Group 暂时失败时写入本地 fallback；恢复后 fallback 数据不会迁移。
2. 主 App 与 Widget 分别使用各自的 fallback store。
3. 归档页面仍可无确认级联删除分类。
4. 归档删除不会取消系统通知。
5. Widget reload 可能先于 SwiftData 自动保存。
6. 通知规则与 pending requests 可能永久不一致。
7. 通知调度错误没有反馈。

### H. Final verdict

**Verdict：REVISE**

正式使用前最应该修复：
1. 正确生成 URL scheme plist 数组并修复 deadline 导航状态驱动。
2. 移除静默本地 fallback，设计明确的降级状态与数据迁移。
3. 所有 Widget 刷新前显式保存，并补齐优先级、模式和归档恢复路径。
4. 让归档删除复用统一的确认、通知清理和 Widget 刷新流程。
5. 完成通知集合对账，并处理调度失败。
6. 使用稳定 UUID 实现单分类 Widget 配置。
