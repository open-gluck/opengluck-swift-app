import Foundation
import SwiftUI

struct PhoneAppTabs: View {
#if OPENGLUCK_CONTACT_TRICK_IS_YES
    @EnvironmentObject var openGlückConnection: OpenGluckConnection
    @AppStorage(WKDataKeys.enableContactTrick.keyValue, store: OpenGluckManager.userDefaults) var enableContactTrick: Bool = false
#endif
    @EnvironmentObject var navigationData: PhoneNavigationData
    @State var graphGeometry: CGSize?
    
    var body: some View {
        NavigationStack(path: $navigationData.path) {
            TabView(selection: $navigationData.currentTab) {
                CheckConnectionHasClient {
                    RobustTimelineView(.everyMinute) { context in
                        let now = context.date
                        Grid {
                            GridRow {
                                AddLowBrick()
                                AddInsulinBrick()
                            }
                            GridRow {
                                CurrentGlucoseView(now: now, mode: .graphBrick, graphGeometry: $graphGeometry)
                                    .gridCellColumns(2)
                            }
                            GridRow {
                                GlucoseTrendBrick(now: now, graphGeometry: graphGeometry)
                                CurrentGlucoseBrick(now: now)
                            }
                        }
                    }
                }
                .tag(PhoneNavigationData.Tabs.graph)
                .tabItem {
                    Image(systemName: "chart.xyaxis.line")
                    Text("Home")
                }
                CheckConnectionHasClient {
                    RobustTimelineView(.everyMinute) { context in
                        List {
                            LastRecordsView(now: context.date)
                        }
                    }
                }
                .tag(PhoneNavigationData.Tabs.records)
                .tabItem {
                    Image(systemName: "list.bullet.rectangle.portrait")
                    Text("History")
                }
                
                PhoneAdvancedView()
                    .tag(PhoneNavigationData.Tabs.advanced)
                    .tabItem {
                        Image(systemName: "table.badge.more")
                        Text("More")
                    }
            }
        }
    }
}

#Preview {
    OpenGluckEnvironmentUpdaterRootView {
        PhoneAppTabs()
    }
    .environmentObject(PhoneAppDelegate())
    .environmentObject(OpenGluckConnection())
    .environmentObject(PhoneNavigationData())
}
