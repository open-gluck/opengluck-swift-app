import SwiftUI
import OG

struct CurrentGlucoseBrick: View {
    let now: Date
    @EnvironmentObject var openGlückEnvironment: OpenGluckEnvironment

    var body: some View {
        Brick(title: "Current") {
            CurrentGlucose(now: now)
        }
        .frame(maxHeight: BrickUI.smallHeight)
    }
}

#Preview("TrendBrick") {
    Grid {
        GridRow {
            GlucoseTrendBrick(graphGeometry: CGSize(width: 300, height: 200))
        }
    }
        .preferredColorScheme(.dark)
}
