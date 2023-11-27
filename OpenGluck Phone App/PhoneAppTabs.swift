import Foundation
import SwiftUI

@MainActor
fileprivate struct CheckConnectionHasClient<C: View>: View {
    let content: () -> C
    
    @State var hasCompletedSetup: Bool = false
    @EnvironmentObject var environment: OpenGluckEnvironment

    var body: some View {
        Group {
            if !hasCompletedSetup {
                ContentUnavailableView("Unknown Server URL/Token", systemImage: "exclamationmark.magnifyingglass", description: Text("Please configure a connection in the More tab."))
            } else if environment.lastSuccessAt == nil {
                ContentUnavailableView("Still Loading…", systemImage: "network.slash", description: Text("\nLoading data from OpenGlück server takes a while…\n\nCheck your network and configuration."))
            } else {
                content()
            }
        }
        .onAppear {
            hasCompletedSetup = OpenGluckConnection.client != nil
        }
    }
}

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

    var body: some View {
        TabView(selection: $currentTab) {
            CheckConnectionHasClient {
                TimelineView(.everyMinute) { context in
                    CurrentGlucoseView(now: context.date)
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
