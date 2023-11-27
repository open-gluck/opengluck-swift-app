import SwiftUI

/*
 Use this View as a container for items that should be marked as sensitive in widgets.
 
 It allows you to fix bugs in XCode previews that prevent the view from showing normally.
 */

struct PrivacySensitiveWidgetModifier: ViewModifier {
    @Environment(\.isWidgetInPreview) var isWidgetInPreview
    @Environment(\.redactionReasons) var redactionReasons

    func body(content: Content) -> some View {
#if targetEnvironment(simulator)
        if isWidgetInPreview {
            if redactionReasons.contains(.privacy) {
                content.redacted(reason: .placeholder)
            } else {
                content
            }
        } else {
            content.privacySensitive()
        }
#else
        content.privacySensitive()
#endif
    }
}

struct PrivacySensitiveWidgetGroup<Content>: View where Content: View {
    @ViewBuilder
    let content: () -> Content

    var body: some View {
        content()
            .modifier(PrivacySensitiveWidgetModifier())
    }
}
