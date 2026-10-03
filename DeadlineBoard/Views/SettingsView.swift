import SwiftUI
import UserNotifications
import WidgetKit

struct SettingsView: View {
    @AppStorage("urgencyWarningDays", store: AppConstants.appGroupDefaults) private var warningDays = 30
    @AppStorage("urgencyUrgentDays", store: AppConstants.appGroupDefaults) private var urgentDays = 7
    @AppStorage("urgencyCriticalHours", store: AppConstants.appGroupDefaults) private var criticalHours = 24
    @AppStorage("showCompleted") private var showCompleted = true

    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined

    var body: some View {
        TabView {
            generalTab
                .tabItem { Label("通用", systemImage: "gear") }

            urgencyTab
                .tabItem { Label("紧迫程度", systemImage: "clock.badge.exclamationmark") }

            notificationTab
                .tabItem { Label("通知", systemImage: "bell") }

            aboutTab
                .tabItem { Label("关于", systemImage: "info.circle") }
        }
        .frame(width: 450, height: 300)
        .task {
            notificationStatus = await NotificationService.shared.checkPermissionStatus()
        }
    }

    private var generalTab: some View {
        Form {
            Toggle("显示已完成项目", isOn: $showCompleted)
        }
        .padding()
    }

    private var urgencyTab: some View {
        Form {
            Section("紧迫程度阈值") {
                Stepper("警告（黄色）：\(warningDays) 天", value: $warningDays, in: max(urgentDays + 1, 7)...90)
                    .onChange(of: warningDays) {
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                Stepper("紧急（橙色）：\(urgentDays) 天", value: $urgentDays, in: 1...min(warningDays - 1, 30))
                    .onChange(of: urgentDays) {
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                Stepper("极紧急（红色）：\(criticalHours) 小时", value: $criticalHours, in: 1...min(urgentDays * 24, 72))
                    .onChange(of: criticalHours) {
                        WidgetCenter.shared.reloadAllTimelines()
                    }
            }

            Section {
                Text("超过 \(warningDays) 天：普通（绿色）")
                    .foregroundStyle(.green)
                Text("\(urgentDays+1)–\(warningDays) 天：注意（黄色）")
                    .foregroundStyle(.yellow)
                Text("1–\(urgentDays) 天：紧急（橙色）")
                    .foregroundStyle(.orange)
                Text("\(criticalHours) 小时以内：极紧急（红色）")
                    .foregroundStyle(.red)
                Text("已逾期：红色")
                    .foregroundStyle(.red)
            }
        }
        .padding()
    }

    private var notificationTab: some View {
        Form {
            Section("通知权限") {
                HStack {
                    Text("当前状态")
                    Spacer()
                    Text(notificationStatusText)
                        .foregroundStyle(notificationStatusColor)
                }

                if notificationStatus != .authorized {
                    Button("请求通知权限") {
                        Task {
                            _ = await NotificationService.shared.requestPermission()
                            notificationStatus = await NotificationService.shared.checkPermissionStatus()
                        }
                    }
                }
            }
        }
        .padding()
    }

    private var aboutTab: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 48))
                .foregroundStyle(.blue)
            Text("Deadline Board")
                .font(.title2.bold())
            Text("版本 1.0")
                .foregroundStyle(.secondary)
            Text("以分类为中心的 DDL 管理工具")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var notificationStatusText: String {
        switch notificationStatus {
        case .authorized: "已授权"
        case .denied: "已拒绝"
        case .notDetermined: "未设置"
        case .provisional: "临时授权"
        case .ephemeral: "临时"
        @unknown default: "未知"
        }
    }

    private var notificationStatusColor: Color {
        switch notificationStatus {
        case .authorized, .provisional, .ephemeral: .green
        case .denied: .red
        default: .secondary
        }
    }
}
