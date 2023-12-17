import SwiftUI
import OG

struct CurrentGlucoseBrick: View {
    let now: Date
    @EnvironmentObject var openGlückEnvironment: OpenGluckEnvironment

    @ViewBuilder var current: some View {
        if let currentGlucoseRecord = openGlückEnvironment.currentGlucoseRecord {
#if os(tvOS)
            GlucoseView(
                glucoseRecord: .constant(currentGlucoseRecord),
                hasCgmRealTimeData: .constant(openGlückEnvironment.cgmHasRealTimeData),
                font: .system(size: 35),
                captionFont: .system(size: 15),
                mode: .coloredBackground
            )
#else
            let freshnessLevel = 1.0 - (-currentGlucoseRecord.timestamp.timeIntervalSince(now) / TimeInterval(10 * 60))
            CurrentDataGauge(timestamp: .constant(currentGlucoseRecord.timestamp), mgDl: .constant(currentGlucoseRecord.mgDl), hasCgmRealTimeData: .constant(openGlückEnvironment.cgmHasRealTimeData), episode: .constant(nil), episodeTimestamp: .constant(nil), freshnessLevel: .constant(freshnessLevel))
#endif
        }
    }
    
    var body: some View {
        Brick(title: "Current") {
            current
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
