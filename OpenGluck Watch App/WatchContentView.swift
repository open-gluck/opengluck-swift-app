import SwiftUI
import UserNotifications
import WatchKit

struct WatchContentView: View {
    @EnvironmentObject var appDelegate: WatchAppDelegate
    
    @AppStorage(WKDataKeys.openglückUrl.keyValue, store: OpenGluckManager.userDefaults) var openglückUrl: String = ""
    @AppStorage(WKDataKeys.openglückToken.keyValue, store: OpenGluckManager.userDefaults) var openglückToken: String = ""
    @State var graphGeometry: CGSize?
    
    var body: some View {
        OpenGluckEnvironmentUpdater {
            List {
                TimelineView(.everyMinute) { context in
                    Grid {
                        GridRow {
                            CurrentGlucoseView(now: context.date, mode: .graph, graphGeometry: $graphGeometry)
                                .frame(height: 120)
                                .gridCellColumns(2)
                        }
                        GridRow {
                            GlucoseTrend(graphGeometry: graphGeometry)
                            CurrentGlucose(now: context.date)
                        }
                        .padding(.all)
                    }
                }
                .padding(.horizontal, -15)
                .listItemTint(.clear)
                LastRecordsView()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        WatchContentView()
            .environmentObject(WatchAppDelegate())
            .environmentObject(OpenGluckConnection())
    }
}
