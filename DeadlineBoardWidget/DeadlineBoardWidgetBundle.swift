import SwiftUI
import WidgetKit

@main
struct DeadlineBoardWidgetBundle: WidgetBundle {
    var body: some Widget {
        SingleCategoryWidget()
        MultiCategoryWidget()
        ProgressWidget()
    }
}
