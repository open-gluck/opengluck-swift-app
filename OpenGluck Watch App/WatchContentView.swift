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
    @State var isLowSheetShown: Bool = false
    @State var isInsulinSheetShown: Bool = false

    @StateObject var addInsulinButtonData: AddInsulinButtonData = AddInsulinButtonData()
    @StateObject var addLowButtonData: AddLowButtonData = AddLowButtonData()
    
    private enum Page: Int {
        case graph = 0
        case records = 1
    }
    
    private var isAnySheetShown: Bool { isLowSheetShown || isInsulinSheetShown }
    
    var body: some View {
        VStack {
            SheetStatusView()
            
            ZStack {
                AddInsulinButton.Interface(addInsulinButtonData: addInsulinButtonData, isShown: $isInsulinSheetShown)
                AddLowButton.Interface(addLowButtonData: addLowButtonData, isShown: $isLowSheetShown)
                
                OpenGluckEnvironmentUpdater {
                    NavigationStack {
                        TabView(selection: $pageNumber) {
                            if !isAnySheetShown {
                                CheckConnectionHasClient {
                                    TimelineView(.everyMinute) { context in
                                        CurrentGlucoseView(now: context.date, mode: .graph, showBackground: false, graphGeometry: $graphGeometry)
                                    }
                                    .padding(.trailing)
                                    .padding(.bottom, 15)
                                    .containerBackground(GlucoseGraph.Background.gradient, for: .tabView)
                                }
                                .tag(Page.graph.rawValue)
                            }

                            CheckConnectionHasClient {
                                List {
                                    LastRecordsView()
                                }
                            }
                            .tag(Page.records.rawValue)
                        }
                        .tabViewStyle(.verticalPage)
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                HStack {
                                    if pageNumber == Page.graph.rawValue {
                                        AddLowButton(addLowButtonData: addLowButtonData, isShown: $isLowSheetShown)
                                    }
                                }
                                .animation(.easeInOut, value: pageNumber)
                            }
                            ToolbarItem(placement: .topBarTrailing) {
                                HStack {
                                    if pageNumber == Page.graph.rawValue {
                                        AddInsulinButton(addInsulinButtonData: addInsulinButtonData, isShown: $isInsulinSheetShown)
                                    }
                                }
                                .animation(.easeInOut, value: pageNumber)
                            }
                            ToolbarItemGroup(placement: .bottomBar) {
                                ZStack {
                                    if pageNumber == Page.graph.rawValue {
                                        CheckConnectionHasClient {
                                            HStack {
                                                GlucoseTrend(graphGeometry: graphGeometry)
                                                    .frame(width: 100)
                                                Spacer()
                                                TimelineView(.everyMinute) { context in
                                                    CurrentGlucose(now: context.date)
                                                }
                                            }
                                        } setupContent: {
                                            Image(systemName: CheckConnectionHasClientDefaultSetupContent.systemImage)
                                        } timeoutContent: {
                                            Image(systemName: CheckConnectionHasClientDefaultTimeoutContent.systemImage)
                                        } exceptionContent: {
                                            Image(systemName: CheckConnectionHasClientDefaultExceptionContent.systemImage)
                                        }
                                    }
                                }
                                .animation(.easeInOut, value: pageNumber)
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
