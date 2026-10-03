# Project Anchor — Deadline Board

## 一句话目标

以"分类"为中心的 macOS 原生 DDL 管理 App，每个分类展示当前最需要关注的一个 DDL，配合桌面 Widget 快速查看进度和截止时间。

## 起点

全新项目，路径 `/Users/yiwei/codes/CountDown`。

## 技术栈

- **语言**: Swift（当前 Xcode 26.6 支持的版本）
- **UI**: SwiftUI
- **持久化**: SwiftData
- **Widget**: WidgetKit
- **通知**: UserNotifications（本地通知）
- **架构**: MVVM，不过度抽象
- **最低系统**: macOS 14 (Sonoma)
- **无第三方依赖**

客户端单体应用，无服务端。

## 部署场景

**个人自用**。用户本人在自己的 Mac 上使用，不面向公众，不部署到任何服务器。App 可能上架 Mac App Store，但核心场景是个人学业/项目 DDL 管理。

安全审查松紧尺度：**中低**——数据全部本地存储，无网络通信（除 UserNotifications 的系统级推送），无登录/鉴权。

## 敏感数据

**无**。存储的是课程名称、DDL 标题、备注文本等非敏感信息。不涉及凭据、健康数据、财务数据或个人隐私信息。

## 非目标

- 不做账号系统、团队协作
- 不做 CloudKit / iCloud 同步（未来可能加，第一版不做）
- 不做 AI 功能、附件、甘特图
- 不做多层子任务（行动项不嵌套）
- 不做苹果提醒事项双向同步
- 不为超大规模数据优化（预期几十个分类、几百个 DDL）
- 不做 iOS 版本

## 约束

- 纯 Swift，不使用第三方依赖
- macOS 14+ 
- 主 App 和 Widget 必须共享同一份数据模型和业务逻辑（通过 App Group）
- Widget 不能假设实时刷新，使用 Timeline + WidgetCenter 策略
- 需要提供 SwiftUI Preview 示例数据

## 成功标准

1. 项目能在 Xcode 中编译运行
2. 能创建分类、在分类下创建 DDL、设置截止时间和优先级
3. 首页以分类为中心展示最近 DDL，排序规则正确
4. 支持手动进度和行动项自动进度两种模式
5. 本地通知能正常发送提醒
6. Widget 能展示分类概览、单分类和进度信息
7. Widget 与 App 数据一致，通过 Deep Link 打开对应页面
8. 有基本的单元测试覆盖核心逻辑
