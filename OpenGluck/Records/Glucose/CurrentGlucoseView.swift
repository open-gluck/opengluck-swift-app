import SwiftUI
import OG
import OGUI

fileprivate struct CurrentGlucoseViewUI {
    static let cornerRadius = 10.0
}

struct CurrentGlucoseView: View {
    @EnvironmentObject var openGlückEnvironment: OpenGluckEnvironment
    
    let now: Date
    enum Mode {
        case graph
        case current
        case full
    }
    
    var mode: Mode = .full
    @State var graphGeometry: CGSize?
    
    @ViewBuilder var graph: some View {
        if let lastGlucoseRecords = openGlückEnvironment.lastGlucoseRecords, let lastInsulinRecords = openGlückEnvironment.lastInsulinRecords, let lastLowRecords = openGlückEnvironment.lastLowRecords {
            GeometryReader { reader in
                let _ = Task {
                    self.graphGeometry = reader.size
                }
                GlucoseGraph(
                    glucoseRecords: .constant(lastGlucoseRecords
                        .filter {
                            -$0.timestamp.timeIntervalSinceNow < GlucoseGraph.maxLookbehindInterval
                        }
                        .map {
                            OpenGluckGlucoseRecord(timestamp: $0.timestamp, mgDl: $0.mgDl, recordType: $0.recordType)
                        }),
                    insulinRecords: .constant(lastInsulinRecords.filter {
                        -$0.timestamp.timeIntervalSinceNow < GlucoseGraph.maxLookbehindInterval &&
                        !$0.deleted
                        
                    }),
                    lowRecords: .constant(lastLowRecords.filter {
                        -$0.timestamp.timeIntervalSinceNow < GlucoseGraph.maxLookbehindInterval
                        
                    }))
            }
        }
    }
    
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
        switch mode {
        case .graph:
            graph
        case .current:
            current
        case .full:
            Grid {
                GridRow {
                    graph
                        .frame(maxHeight: 200)
                    #if !os(watchOS)
                        .clipShape(RoundedRectangle(cornerRadius: CurrentGlucoseViewUI.cornerRadius))
                    #endif
                }
                GridRow {
                    Grid {
                        GridRow {
                            Brick(title: "Trend") {
                                if let lastHistoricGlucoseRecord = openGlückEnvironment.lastHistoricGlucoseRecord {
                                    HStack(spacing: 0) {
                                        Spacer()
                                        GlucoseView(
                                            glucoseRecord: .constant(lastHistoricGlucoseRecord),
                                            hasCgmRealTimeData: .constant(openGlückEnvironment.cgmHasRealTimeData),
                                            font: .system(size: 16),
                                            captionFont: .system(size: 10),
                                            mode: .vibrantAgo
                                        )
                                        Spacer()
                                            .frame(maxWidth: 20.0)
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
                                            Image(systemName: "arrow.right")
                                                .rotationEffect(.degrees(angle))
                                                .scaleEffect(2)
                                                .opacity(0.8)
                                            Spacer()
                                        }
                                    }
                                }
                            }
                            Brick(title: "Current") {
                                current
                            }
                        }
                    }
                    .frame(maxHeight: BrickUI.smallHeight)
                }
            }
        }
    }
}

struct CurrentGlucoseView_Previews: PreviewProvider {
    static var previews: some View {
        OpenGluckEnvironmentUpdater {
            CurrentGlucoseView(now: Date())
        }
        .environmentObject(OpenGluckConnection())
    }
}
