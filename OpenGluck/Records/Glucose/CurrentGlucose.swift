import SwiftUI

struct CurrentGlucose: View {
    @EnvironmentObject var openGlückEnvironment: OpenGluckEnvironment
    let now: Date

    var body: some View {
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
}
