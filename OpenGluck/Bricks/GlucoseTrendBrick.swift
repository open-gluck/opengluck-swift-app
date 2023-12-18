import SwiftUI
import OG

struct GlucoseTrendBrick: View {
    let graphGeometry: CGSize?

    var body: some View {
        Brick(title: "Trend") {
            GlucoseTrend(graphGeometry: graphGeometry)
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
