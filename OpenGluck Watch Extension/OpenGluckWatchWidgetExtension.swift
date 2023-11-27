import WidgetKit
import SwiftUI
import Intents
import WatchConnectivity

@main
struct OpenGluckWatchWidgetExtension: WidgetBundle {
    var body: some Widget {
        AppLauncherWidget()
        CurrentGlucoseWidget()
        GraphWidget()

        // hide debug widgets
//        DebugWidget()
//        TimelineDebugWidget()
    }
}
