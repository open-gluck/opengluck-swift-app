import Foundation
import WidgetKit

enum WidgetKinds: String {
    case AppLauncherWidget = "open-gluck.github.io.ios.widgets.app-launcher"
    case DebugWidget = "open-gluck.github.io.ios.widgets.debug"
    case TimelineDebugWidget = "open-gluck.github.io.ios.widgets.timeline-debug"
    case CurrentGlucoseWidget = "open-gluck.github.io.ios.widgets.current-glucose"
    case CurrentGlucoseLargeWidget = "open-gluck.github.io.ios.widgets.current-glucose-large"
    case GraphWidget = "open-gluck.github.io.ios.widgets.graph"
    
    func reloadTimeline() {
        WidgetCenter.shared.reloadTimelines(ofKind: self.rawValue)
    }
}
