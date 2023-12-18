import SwiftUI
import UserNotifications
import WatchKit
import OG

struct WatchContentView: View {
    @EnvironmentObject var appDelegate: WatchAppDelegate
    @StateObject var sheetStatusOptions: SheetStatusViewOptions = SheetStatusViewOptions()
    @EnvironmentObject var openGlückConnection: OpenGluckConnection

    @AppStorage(WKDataKeys.openglückUrl.keyValue, store: OpenGluckManager.userDefaults) var openglückUrl: String = ""
    @AppStorage(WKDataKeys.openglückToken.keyValue, store: OpenGluckManager.userDefaults) var openglückToken: String = ""
    @State var graphGeometry: CGSize?
    @State var pageNumber: Int = 0
    
    @State var showAddInsulin: Bool = false
    @State var unitsString: String = ""
    
    private enum Page: Int {
        case graph = 0
        case records = 1
    }
    
    private func uploadInsulinToOpenGlück(units: Int) async throws {
        guard let client = openGlückConnection.getClient() else {
            fatalError("No client")
        }
        let insulinRecords: [OpenGluckInsulinRecord] = [
            OpenGluckInsulinRecord(id: UUID(), timestamp: Date(), units: units, deleted: false)
        ]
        _ = try await client.upload(insulinRecords: insulinRecords)
    }

    private func addInsulin(units: Double) {
        let unitsString: String = abs(units - round(units)) < .ulpOfOne ? "\(Int(round(units)))" : "\(round(units * 10) / 10)"
        sheetStatusOptions.state = SheetStatusViewState.inProgress
        sheetStatusOptions.status = "\(unitsString) IU"
        sheetStatusOptions.subStatus1 = "Preparing…"
        sheetStatusOptions.state = .inProgress
        Task {
            defer { sheetStatusOptions.state = SheetStatusViewState.complete }
            sheetStatusOptions.subStatus1 = "Adding…"
            do {
                try await uploadInsulinToOpenGlück(units: Int(round(units)))
                sheetStatusOptions.subStatus1 = "Done!"
                NotificationCenter.default.post(name: Notification.Name.refreshOpenGlück, object: nil)
            } catch {
                sheetStatusOptions.pushError(message: error.localizedDescription)
            }
        }
    }
    
    var body: some View {
        VStack {
            SheetStatusView()
            
            ZStack {
                DigiTextView(placeholder: "",
                             text: $unitsString,
                             presentingModal: $showAddInsulin, onClose: {
                    pageNumber = Page.graph.rawValue
                }, onConfirm: {
                    Task {
                        pageNumber = Page.graph.rawValue
                        await Task.yield()
                        if let units = Double(unitsString) {
                            addInsulin(units: units)
                        }
                    }
                })
                .opacity(0)
                
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
                            ToolbarItem(placement: .topBarTrailing) {
                                if pageNumber == Page.graph.rawValue {
                                    Button {
                                        unitsString = ""
                                        showAddInsulin = true
                                    } label: {
                                        Image(systemName:"cross.vial")
                                            .foregroundColor(.white)
                                    }
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
