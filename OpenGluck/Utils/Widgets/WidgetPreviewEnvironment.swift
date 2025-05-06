import SwiftUI

struct WidgetPreviewEnvironmentKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    // this was useful before XCode 15 to have privacy-sensitive previews work as expected
    var isWidgetInPreview: Bool {
        get { self[WidgetPreviewEnvironmentKey.self] }
        set { self[WidgetPreviewEnvironmentKey.self] = newValue }
    }
}
