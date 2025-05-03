import SwiftUI
import OG

struct GlucoseTrendBrick: View {
    let now: Date
    let graphGeometry: CGSize?

    var body: some View {
        Brick(title: "Trend") {
            GlucoseTrend(now: now, graphGeometry: graphGeometry)
                .frame(maxWidth: 75)
        }
        .frame(maxHeight: BrickUI.smallHeight)

    }
}

#Preview("TrendBrick") {
    OpenGluckEnvironmentUpdaterView {
        Grid {
            GridRow {
                GlucoseTrendBrick(now: Date(), graphGeometry: CGSize(width: 300, height: 200))
            }
        }
    }
    .environmentObject(OpenGluckConnection())
    .preferredColorScheme(.dark)
}
