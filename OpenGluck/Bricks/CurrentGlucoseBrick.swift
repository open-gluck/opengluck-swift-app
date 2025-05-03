import SwiftUI
import OG

struct CurrentGlucoseBrick: View {
    let now: Date
    @EnvironmentObject var openGlückEnvironment: OpenGluckEnvironment

    var body: some View {
        let debugLastGlucoseRecord = openGlückEnvironment.lastGlucoseRecords?.sorted(by: { $0.timestamp > $1.timestamp }).first
        Brick(title: "Current") {
            CurrentGlucose(now: now)
        }
        .frame(maxHeight: BrickUI.smallHeight)
    }
}

#Preview("TrendBrick") {
    OpenGluckEnvironmentUpdaterView {
        Grid {
            GridRow {
                CurrentGlucoseBrick(now: Date())
            }
        }
    }
    .environmentObject(OpenGluckConnection())
    .preferredColorScheme(.dark)
}
