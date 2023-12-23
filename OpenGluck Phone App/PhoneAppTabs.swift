import Foundation
import SwiftUI

struct PhoneAppTabs: View {
    enum Tabs {
        case graph
        case records
        case advanced
    }

#if OPENGLUCK_CONTACT_TRICK_IS_YES
    @EnvironmentObject var openGlückConnection: OpenGluckConnection
    @AppStorage(WKDataKeys.enableContactTrick.keyValue, store: OpenGluckManager.userDefaults) var enableContactTrick: Bool = false
#endif
    @State var currentTab: Tabs = .graph
    @State var graphGeometry: CGSize?

    var body: some View {
        TabView(selection: $currentTab) {
            CheckConnectionHasClient {
                TimelineView(.everyMinute) { context in
                    Grid {
                        GridRow {
                            AddLowBrick()
                            AddInsulinBrick()
                        }
                        GridRow {
                            CurrentGlucoseView(now: context.date, mode: .graphBrick, graphGeometry: $graphGeometry)
                                .gridCellColumns(2)
                        }
                        GridRow {
                            GlucoseTrendBrick(graphGeometry: graphGeometry)
                            CurrentGlucoseBrick(now: context.date)
                        }
                    }
                }
            }
                .tag(Tabs.graph)
                .tabItem {
                    Image(systemName: "chart.xyaxis.line")
                    Text("Home")
                }
            CheckConnectionHasClient {
                List {
                    LastRecordsView()
                }
            }
                .tag(Tabs.records)
                .tabItem {
                    Image(systemName: "list.bullet.rectangle.portrait")
                    Text("History")
                }

            PhoneAdvancedView()
                .tag(Tabs.advanced)
                .tabItem {
                    Image(systemName: "table.badge.more")
                    Text("More")
                }
        }
    }
}

struct AppTabs_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            OpenGluckEnvironmentUpdater {
                PhoneAppTabs()
            }
        }
        .environmentObject(PhoneAppDelegate())
        .environmentObject(OpenGluckConnection())
    }
}
