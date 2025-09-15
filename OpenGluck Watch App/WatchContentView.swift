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
                
                OpenGluckEnvironmentUpdaterView {
                    NavigationStack {
                        TabView(selection: $pageNumber) {
                            ZStack {
                                Color.clear
                                CheckConnectionHasClient {
                                    TimelineView(.everyMinute) { context in
                                        CurrentGlucoseView(now: context.date, mode: .graph, showBackground: false, graphGeometry: $graphGeometry)
                                    }
                                    .padding(.trailing)
                                    .padding(.bottom, 15)
                                    .containerBackground(GlucoseGraphBackground.gradient, for: .tabView)
                                }
                            }
                            .safeAreaInset(edge: .bottom) {
                                let bottomInsetHeight: CGFloat = 20.0
                                CheckConnectionHasClient {
                                    HStack(spacing: 0) {
                                        TimelineView(.everyMinute) { context in
                                            let now = context.date
                                            GlucoseTrend(now: now, graphGeometry: graphGeometry)
                                                .frame(width: 55)
                                                .offset(x: 10, y: 0)
                                            Spacer()
                                            CurrentGlucose(now: now)
                                        }
                                        .frame(maxWidth: 162)
                                    }
                                } setupContent: {
                                    Image(systemName: CheckConnectionHasClientDefaultSetupContent.systemImage)
                                } timeoutContent: {
                                    Image(systemName: CheckConnectionHasClientDefaultTimeoutContent.systemImage)
                                } exceptionContent: {
                                    Image(systemName: CheckConnectionHasClientDefaultExceptionContent.systemImage)
                                }
                                .padding(.horizontal, bottomInsetHeight)
                                .padding([.bottom, .trailing], bottomInsetHeight / 2)
                                .frame(height: bottomInsetHeight)
                                .offset(x: 0, y: 10)
                            }
                            .tag(Page.graph.rawValue)
                            
                            CheckConnectionHasClient {
                                TimelineView(.everyMinute) { context in
                                    let now = context.date
                                    List {
                                        LastRecordsView(now: now)
                                    }
                                }
                            }
                            .tag(Page.records.rawValue)
                        }
                        .tabViewStyle(.verticalPage)
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                HStack {
                                    if pageNumber == Page.graph.rawValue {
                                        AddLowButtonMulti(addLowButtonData: addLowButtonData)
                                    }
                                }
                                .animation(.easeInOut, value: pageNumber)
                            }
                            ToolbarItem(placement: .topBarTrailing) {
                                HStack {
                                    if pageNumber == Page.graph.rawValue {
                                        AddInsulinButton(addInsulinButtonData: addInsulinButtonData)
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
        OpenGluckEnvironmentUpdaterRootView {
            WatchContentView()
        }
        .environmentObject(WatchAppDelegate())
        .environmentObject(OpenGluckConnection())
    }
}
