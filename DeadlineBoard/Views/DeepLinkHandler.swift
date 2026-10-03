import SwiftUI
import SwiftData

struct DeepLinkHandler: ViewModifier {
    @Environment(\.modelContext) private var modelContext
    @Binding var selectedCategory: DDCategory?
    @Binding var selectedDeadline: DDDeadline?

    func body(content: Content) -> some View {
        content
            .onOpenURL { url in
                handleDeepLink(url)
            }
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == AppConstants.deepLinkScheme else { return }

        let pathComponents = url.pathComponents.filter { $0 != "/" }
        guard let host = url.host() else { return }

        switch host {
        case "category":
            if let idString = pathComponents.first,
               let uuid = UUID(uuidString: idString) {
                selectCategory(withId: uuid)
            }
        case "deadline":
            if let idString = pathComponents.first,
               let uuid = UUID(uuidString: idString) {
                selectDeadline(withId: uuid)
            }
        default:
            break
        }
    }

    private func selectCategory(withId id: UUID) {
        let predicate = #Predicate<DDCategory> { $0.id == id }
        let descriptor = FetchDescriptor(predicate: predicate)
        if let category = try? modelContext.fetch(descriptor).first {
            selectedCategory = category
        }
    }

    private func selectDeadline(withId id: UUID) {
        let predicate = #Predicate<DDDeadline> { $0.id == id }
        let descriptor = FetchDescriptor(predicate: predicate)
        if let deadline = try? modelContext.fetch(descriptor).first,
           let category = deadline.category {
            selectedCategory = category
            selectedDeadline = deadline
        }
    }
}

extension View {
    func handleDeepLinks(
        selectedCategory: Binding<DDCategory?>,
        selectedDeadline: Binding<DDDeadline?>
    ) -> some View {
        modifier(DeepLinkHandler(
            selectedCategory: selectedCategory,
            selectedDeadline: selectedDeadline
        ))
    }
}
