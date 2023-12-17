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
        case graphBrick
    }
    
    var mode: Mode = .graph
    @Binding var graphGeometry: CGSize?
    
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
    
    var body: some View {
        switch mode {
        case .graph:
            graph
        case .graphBrick:
            graph
                .frame(maxHeight: 200)
#if !os(watchOS)
                .clipShape(RoundedRectangle(cornerRadius: CurrentGlucoseViewUI.cornerRadius))
#endif
        }
    }
}

struct CurrentGlucoseView_Previews: PreviewProvider {
    static var previews: some View {
        OpenGluckEnvironmentUpdater {
            Grid {
                GridRow {
                    CurrentGlucoseView(now: Date(), mode: .graphBrick, graphGeometry: .constant(CGSize(width: 0, height: 0)))
                        .gridCellColumns(2)
                }
            }
        }
        .environmentObject(OpenGluckConnection())
    }
}
