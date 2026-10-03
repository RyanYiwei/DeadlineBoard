import Foundation
import SwiftData

enum SharedModelContainer {
    static let appGroupIdentifier = "group.com.deadlineboard.shared"
    static private(set) var isUsingSharedStore = false

    static var schema: Schema {
        Schema([
            DDCategory.self,
            DDDeadline.self,
            DDActionItem.self,
            DDReminderRule.self,
        ])
    }

    @MainActor
    static func create() -> ModelContainer {
        if let container = try? createWithAppGroup() {
            isUsingSharedStore = true
            return container
        }

        if let container = try? createLocalFallback() {
            isUsingSharedStore = false
            return container
        }

        fatalError("Failed to create any ModelContainer. Check App Group configuration and disk permissions.")
    }

    @MainActor
    static func createForWidget() -> ModelContainer? {
        try? createWithAppGroup()
    }

    private static func createWithAppGroup() throws -> ModelContainer {
        let config = ModelConfiguration(
            "DeadlineBoard",
            schema: schema,
            groupContainer: .identifier(appGroupIdentifier)
        )
        return try ModelContainer(for: schema, configurations: [config])
    }

    private static func createLocalFallback() throws -> ModelContainer {
        let config = ModelConfiguration(
            "DeadlineBoard",
            schema: schema
        )
        return try ModelContainer(for: schema, configurations: [config])
    }
}
