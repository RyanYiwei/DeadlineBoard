# Round 0 — Build Notes

## 构建内容

从零创建了完整的 macOS「Deadline Board」App，包含主 App、Widget Extension 和单元测试。

### 项目结构

```
CountDown/
├── project.yml                     # XcodeGen 项目配置
├── DeadlineBoard.xcodeproj/        # 生成的 Xcode 项目
├── DeadlineBoard/                  # 主 App target
│   ├── DeadlineBoardApp.swift      # App 入口
│   ├── DeadlineBoard.entitlements  # App Group 权限
│   ├── Assets.xcassets/            # 资源目录
│   └── Views/
│       ├── DashboardView.swift     # 首页 Dashboard
│       ├── CategoryCardView.swift  # 分类卡片
│       ├── CategoryDetailView.swift # 分类详情
│       ├── CategoryEditorView.swift # 分类编辑器
│       ├── DeadlineRowView.swift   # DDL 列表行
│       ├── DeadlineEditorView.swift # DDL 编辑器
│       ├── ArchivedCategoriesView.swift # 归档分类
│       ├── SettingsView.swift      # 设置页
│       └── DeepLinkHandler.swift   # Deep Link 处理
├── Shared/                         # App 和 Widget 共享代码
│   ├── Models/
│   │   ├── DDCategory.swift        # 分类模型
│   │   ├── DDDeadline.swift        # DDL 模型
│   │   ├── DDActionItem.swift      # 行动项模型
│   │   └── DDReminderRule.swift    # 提醒规则模型
│   ├── Services/
│   │   ├── DeadlineQueryService.swift   # 最近 DDL 查询逻辑
│   │   ├── ProgressCalculator.swift     # 进度计算
│   │   ├── UrgencyCalculator.swift      # 紧迫程度计算
│   │   ├── DateFormatService.swift      # 日期格式化
│   │   ├── NotificationService.swift    # 本地通知服务
│   │   └── SharedModelContainer.swift   # SwiftData 共享容器
│   └── Constants/
│       ├── AppConstants.swift      # 常量定义
│       └── ColorExtension.swift    # Color hex 扩展
├── DeadlineBoardWidget/            # Widget Extension target
│   ├── DeadlineBoardWidgetBundle.swift
│   ├── SingleCategoryWidget.swift  # 单分类 Widget
│   ├── MultiCategoryWidget.swift   # 多分类概览 Widget
│   ├── ProgressWidget.swift        # 进度概览 Widget
│   ├── Info.plist
│   └── DeadlineBoardWidget.entitlements
└── DeadlineBoardTests/
    └── DeadlineBoardTests.swift    # 22 个单元测试
```

### 已实现功能

1. **数据模型**：DDCategory、DDDeadline、DDActionItem、DDReminderRule，使用 SwiftData + App Group
2. **首页 Dashboard**：NavigationSplitView，左侧分类列表，右侧详情，支持拖动排序
3. **分类管理**：创建、编辑、归档、删除、颜色和图标选择
4. **DDL 管理**：创建、编辑、删除、标记完成/恢复
5. **分类详情**：按逾期/进行中/即将开始/已完成分组展示
6. **最近 DDL 查询**：严格按照产品规则（逾期优先 → 最近截止 → 优先级 → 创建时间）
7. **进度系统**：手动进度 + 行动项自动进度两种模式
8. **紧迫程度**：>30天绿色 / 8-30天黄色 / 1-7天橙色 / <24小时红色 / 逾期红色
9. **提醒通知**：UserNotifications 本地通知，支持预设和自定义时间
10. **设置页**：紧迫程度阈值、显示已完成、通知权限、关于
11. **Widget**：三种 Widget（单分类、多分类概览、进度概览），使用共享数据
12. **Deep Link**：Widget 点击通过 URL scheme 打开对应分类/DDL

### 编译验证

- `xcodebuild build` → **BUILD SUCCEEDED**
- 主 App target 编译通过
- Widget Extension target 编译通过
- 22 个单元测试全部通过

### 测试覆盖

- DeadlineQueryService：6 个测试（完成过滤、逾期优先、最早逾期、最近即将到期、优先级决胜、空分类）
- ProgressCalculator：5 个测试（手动进度、清单进度、空清单、完成=100%、全部完成检测）
- UrgencyCalculator：6 个测试（逾期/紧急/即将到期/注意/正常/已完成各级别）
- DateFormatService：5 个测试（逾期文本、明天文本、多天文本、进度文本、行动项文本）

### 未验证 / 已知限制

- **无法在命令行验证 UI**：没有 macOS 模拟器可用，UI 渲染效果未直接验证
- **App Group 需要签名配置**：App Group 需要有效的 Development Team 才能创建共享容器，纯命令行编译时使用 `CODE_SIGN_IDENTITY="-"` 跳过签名
- **Widget 运行时需要真实签名**：Widget Extension 需要嵌入主 App 并签名后才能实际运行

### 用户需要在 Xcode 中手动配置的步骤

1. 打开 `DeadlineBoard.xcodeproj`
2. 选择 DeadlineBoard target → Signing & Capabilities → 选择自己的 Team
3. 选择 DeadlineBoardWidgetExtension target → 同样配置 Team
4. 确保两个 target 的 App Group 都设置为 `group.com.deadlineboard.shared`
5. 首次运行时允许通知权限
