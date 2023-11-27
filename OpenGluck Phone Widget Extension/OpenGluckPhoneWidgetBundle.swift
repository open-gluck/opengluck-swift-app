import WidgetKit
import SwiftUI

@main
struct OpenGluckPhoneWidgetBundle: WidgetBundle {
    var body: some Widget {
        CurrentGlucoseWidget()
        CurrentGlucoseLargeWidget()
        GraphWidget()

        // hide debug widgets
//        DebugWidget()
//        CurrentBloodGlucoseWidget()
//        CurrentBloodGlucoseTimestampWidget()
    }
}
