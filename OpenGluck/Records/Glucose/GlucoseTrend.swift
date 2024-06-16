import SwiftUI

struct GlucoseTrend: View {
    let graphGeometry: CGSize?
    @EnvironmentObject var openGlückEnvironment: OpenGluckEnvironment

    var body: some View {
        ZStack {
            if let lastHistoricGlucoseRecord = openGlückEnvironment.lastHistoricGlucoseRecord {
                HStack {
                    GlucoseView(
                        glucoseRecord: .constant(lastHistoricGlucoseRecord),
                        hasCgmRealTimeData: .constant(openGlückEnvironment.cgmHasRealTimeData),
                        font: .system(size: 16),
                        captionFont: .system(size: 10),
                        mode: .vibrantAgoSmall
                    )
                    .frame(alignment: .bottomLeading)
                    Spacer()
                }
                if let graphGeometry, let lastGlucoseRecords = openGlückEnvironment.lastGlucoseRecords, let lastGlucoseRecord = lastGlucoseRecords.sorted(by: { $0.timestamp > $1.timestamp }).first {
                    // make an educated guess of the slope, assume max=350,
                    // and width~5hrs
                    // and fill entire width
                    // angle=90 is all the way down,
                    // angle=-90 is all the way up
                    let elapsed: Double = lastGlucoseRecord.timestamp.timeIntervalSince(lastHistoricGlucoseRecord.timestamp)
                    let deltaMgDl: Double = Double(lastGlucoseRecord.mgDl - lastHistoricGlucoseRecord.mgDl)
                    let deltaFullWidth: Double = (3600.0*5) * deltaMgDl / elapsed
                    let angleRaw = -(45 * graphGeometry.height / graphGeometry.width) / 350.0 * deltaFullWidth
                    let angle: Double = max(min(angleRaw, 90), -90)
                    HStack {
                        Spacer()
                    Image(systemName: "arrow.right")
                        .rotationEffect(.degrees(angle))
                        .scaleEffect(2)
                        .opacity(0.8)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: BrickUI.smallHeight)
    }
}
