import SwiftData
import WidgetKit

extension ModelContext {
    @discardableResult
    func saveAndReloadWidgets() -> Bool {
        do {
            try self.save()
            WidgetCenter.shared.reloadAllTimelines()
            return true
        } catch {
            return false
        }
    }
}
