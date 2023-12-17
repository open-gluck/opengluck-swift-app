import SwiftUI
import UserNotifications
import WatchKit

struct WatchContentView: View {
    @EnvironmentObject var appDelegate: WatchAppDelegate
    
    @AppStorage(WKDataKeys.openglückUrl.keyValue, store: OpenGluckManager.userDefaults) var openglückUrl: String = ""
    @AppStorage(WKDataKeys.openglückToken.keyValue, store: OpenGluckManager.userDefaults) var openglückToken: String = ""
    @State var graphGeometry: CGSize?
    
    var body: some View {
        TimelineView(.everyMinute) { context in
            OpenGluckEnvironmentUpdater {
                ScrollView {
                    //WKDataDebugView()
                    //WKComplicationDebugView()
                    Group {
                        CurrentGlucoseView(now: context.date, graphGeometry: $graphGeometry)
                            .padding(.bottom, 10)
                            // LATER improve use watchOS 10
                            .frame(minHeight: 190)
                    }
                    LastRecordsView()
                        .padding(.vertical)
                }
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
