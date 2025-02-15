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
    var showBackground: Bool = true
    @Binding var graphGeometry: CGSize?
    
    @ViewBuilder var graph: some View {
        if openGlückEnvironment.hasTimedOut {
            ContentUnavailableView("Still Loading…", systemImage: "network.slash", description: Text("\nLoading data from OpenGlück server takes a while…\n\nCheck your network and configuration."))
        } else {
            let lastGlucoseRecords: [OpenGluckGlucoseRecord] = openGlückEnvironment.lastGlucoseRecords ?? []
            let lastInsulinRecords: [OpenGluckInsulinRecord] = openGlückEnvironment.lastInsulinRecords ?? []
            let lastLowRecords: [OpenGluckLowRecord] = openGlückEnvironment.lastLowRecords ?? []
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
                        
                    }),
                    showBackground: showBackground
                )
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
                    CurrentGlucoseView(now: Date(), mode: .graphBrick, showBackground: false, graphGeometry: .constant(CGSize(width: 0, height: 0)))
                        .gridCellColumns(2)
                }
            }
        }
        .environmentObject(OpenGluckConnection())
    }
}
