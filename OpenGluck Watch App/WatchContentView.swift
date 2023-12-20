import SwiftUI
import UserNotifications
import WatchKit
import OG

struct WatchContentView: View {
    @EnvironmentObject var appDelegate: WatchAppDelegate
    @StateObject var sheetStatusOptions: SheetStatusViewOptions = SheetStatusViewOptions()

    @AppStorage(WKDataKeys.openglückUrl.keyValue, store: OpenGluckManager.userDefaults) var openglückUrl: String = ""
    @AppStorage(WKDataKeys.openglückToken.keyValue, store: OpenGluckManager.userDefaults) var openglückToken: String = ""
    @State var graphGeometry: CGSize?
    @State var pageNumber: Int = 0
    
    @StateObject var addInsulinButtonData: AddInsulinButtonData = AddInsulinButtonData()
    @StateObject var addLowButtonData: AddLowButtonData = AddLowButtonData()
    
    private enum Page: Int {
        case graph = 0
        case records = 1
    }
    
    var body: some View {
        VStack {
            SheetStatusView()
            
            ZStack {
                AddInsulinButton.Interface(addInsulinButtonData: addInsulinButtonData)
                AddLowButton.Interface(addLowButtonData: addLowButtonData)
                
                OpenGluckEnvironmentUpdater {
                    NavigationStack {
                        TabView(selection: $pageNumber) {
                            TimelineView(.everyMinute) { context in
                                CurrentGlucoseView(now: context.date, mode: .graph, showBackground: false, graphGeometry: $graphGeometry)
                            }
                            .padding(.trailing)
                            .padding(.bottom, 15)
                            .containerBackground(GlucoseGraph.Background.gradient, for: .tabView)
                            .tag(Page.graph.rawValue)
                            
                            List {
                                LastRecordsView()
                            }
                            .tag(Page.records.rawValue)
                        }
                        .tabViewStyle(.verticalPage)
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                if pageNumber == Page.graph.rawValue {
                                    AddLowButton(addLowButtonData: addLowButtonData)
                                }
                            }
                            ToolbarItem(placement: .topBarTrailing) {
                                if pageNumber == Page.graph.rawValue {
                                    AddInsulinButton(addInsulinButtonData: addInsulinButtonData)
                                }
                            }
                            ToolbarItemGroup(placement: .bottomBar) {
                                if pageNumber == Page.graph.rawValue {
                                    GlucoseTrend(graphGeometry: graphGeometry)
                                        .frame(width: 100)
                                    TimelineView(.everyMinute) { context in
                                        CurrentGlucose(now: context.date)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .environmentObject(sheetStatusOptions)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        WatchContentView()
            .environmentObject(WatchAppDelegate())
            .environmentObject(OpenGluckConnection())
    }
}
