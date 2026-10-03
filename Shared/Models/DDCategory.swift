import Foundation
import SwiftData
import SwiftUI

@Model
final class DDCategory {
    @Attribute(.unique) var id: UUID
    var name: String
    var colorHex: String
    var iconName: String
    var sortOrder: Int
    var isArchived: Bool
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \DDDeadline.category)
    var deadlines: [DDDeadline]

    init(
        name: String,
        colorHex: String = "#007AFF",
        iconName: String = "folder.fill",
        sortOrder: Int = 0,
        isArchived: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.iconName = iconName
        self.sortOrder = sortOrder
        self.isArchived = isArchived
        self.createdAt = Date()
        self.deadlines = []
    }

    var color: Color {
        Color(hex: colorHex) ?? .blue
    }

    var activeDeadlines: [DDDeadline] {
        deadlines.filter { $0.status != .completed }
    }
}
