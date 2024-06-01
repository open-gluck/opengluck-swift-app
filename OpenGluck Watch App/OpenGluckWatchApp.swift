import SwiftUI
import UserNotifications
import WatchConnectivity
import WidgetKit

@main
struct OpenGluckWatchApp: App {
    static let taskReloadTime = "taskReloadTime"
    @WKApplicationDelegateAdaptor var appDelegate: WatchAppDelegate
    let openGlückConnection = OpenGluckConnection()
    
    private func scheduleBackgroundTask() async {
        WKApplication.shared()
            .scheduleBackgroundRefresh(
                withPreferredDate: Date().addingTimeInterval(10),
                userInfo: Self.taskReloadTime as NSSecureCoding & NSObjectProtocol) { error in
                    if error != nil {
                        // Handle the scheduling error.
                        fatalError("*** An error occurred while scheduling the background refresh task. ***")
                    }
                    
                    print("*** Scheduled! ***")
                }
        await openGlückConnection.getClient()?.recordLog("scheduleBackgroundTask")
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    var body: some Scene {
        WindowGroup {
            /*
             TimelineView(.periodic(from: Date(), by: 1)) { context in
             VStack {
             Text("\(String(describing: context.cadence))")
             Text("\(context.date.formatted(date: .omitted, time: .complete))")
             Text("\(Date().formatted(date: .omitted, time: .complete))")
             }
             }
             */
            WatchContentView()
                .environmentObject(openGlückConnection)
                .environmentObject(appDelegate)
                .onAppear {
                    Task {
                        await scheduleBackgroundTask()
                    }
                }
        }
        .backgroundTask(.appRefresh(Self.taskReloadTime)) { context in
            await scheduleBackgroundTask()
//            await openGlückConnection.getClient()?.recordLog(".backgroundTask(.appRefresh(Self.taskReloadTime)), context=\(context)")
            print(".backgroundTask(.appRefresh(Self.taskReloadTime))")
            WidgetCenter.shared.reloadAllTimelines()
        }
        /*.backgroundTask(.appRefresh) { context in
         await scheduleBackgroundTask()
         print("BG TASK")
         await openGlück.getClient().recordLog("BG TASK, context=\(String(describing: context))")
         WidgetKinds.DebugWidget.reloadTimeline()
         }*/
    }
}
