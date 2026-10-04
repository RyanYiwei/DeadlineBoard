# Deadline Board

以「分类」为中心的 macOS 原生 DDL 管理应用。常驻菜单栏，快速查看各分类最近的截止日；配合桌面 Widget 一览进度和倒计时。面向个人学业与项目管理场景。

## 功能

- **菜单栏常驻**：点击图标弹窗显示各分类最近 DDL，不占 Dock 位置
- **Dashboard 面板**：完整的分类管理、DDL 编辑、时间轴首页
- **时间轴首页**：未选分类时按日期分组展示所有待办 DDL
- **行动项管理**：展开 DDL 行内直接勾选、添加、删除行动项
- **自定义分类颜色**：系统取色器 + Hex 输入，8 种预设有机配色
- **桌面 Widget**：单分类、多分类概览（可选最多 5 个分类）、进度总览
- **本地通知提醒**：自定义提醒规则，支持多条规则
- **Deep Link**：Widget 点击直达对应 DDL

## 技术栈

| 层 | 选型 |
|---|---|
| UI | SwiftUI (macOS 14+) |
| 持久化 | SwiftData (App Group 共享) |
| Widget | WidgetKit (AppIntents) |
| 通知 | UserNotifications |
| 项目生成 | XcodeGen |

## 快速开始

```bash
# 需要先安装 xcodegen
brew install xcodegen

# 生成 Xcode 项目
xcodegen generate

# 命令行编译（跳过签名）
xcodebuild build -project DeadlineBoard.xcodeproj -scheme DeadlineBoard \
  -destination 'platform=macOS' CODE_SIGN_IDENTITY="-" CODE_SIGNING_ALLOWED=NO

# 推荐在 Xcode 中运行（支持签名和 Widget）
open DeadlineBoard.xcodeproj
# Xcode 中选择 Team → Cmd+R
```

## 项目结构

```
DeadlineBoard/                 # 主 App (Menu Bar 应用)
├── DeadlineBoardApp.swift     # 入口：MenuBarExtra + Window + 通知调和
├── Info.plist                 # URL Scheme + LSUIElement
└── Views/                     # SwiftUI 视图
    ├── MenuBarView.swift      # 菜单栏弹窗
    ├── DashboardView.swift    # 主面板 (NavigationSplitView)
    ├── HomePageView.swift     # 时间轴首页
    ├── CategoryDetailView.swift
    ├── DeadlineEditorView.swift
    └── DeadlineRowView.swift  # DDL 行 + 行动项内联管理

DeadlineBoardWidget/           # Widget Extension
├── SingleCategoryWidget.swift # 单分类 Widget (AppEntity 配置)
├── MultiCategoryWidget.swift  # 多分类概览 Widget (最多 5 个)
└── ProgressWidget.swift       # 进度总览 Widget

Shared/                        # 主 App 与 Widget 共享
├── Models/                    # SwiftData 模型
├── Services/                  # 业务逻辑 (通知、进度、紧急度、查询)
├── Constants/                 # 设计系统 (Theme.swift)、颜色、常量
└── Extensions/                # ModelContext 扩展
```
