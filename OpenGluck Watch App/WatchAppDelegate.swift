import WatchConnectivity
import UserNotifications
import SwiftUI
import WidgetKit

class WatchAppDelegate: NSObject, WKApplicationDelegate, WCSessionDelegate, ObservableObject, UNUserNotificationCenterDelegate {
    private var deviceToken: Data? = nil
    private var notificationsGranted: Bool?
    @AppStorage(WKDataKeys.debugComplication.keyValue, store: OpenGluckManager.userDefaults) private var debugComplication: Int = 0

    override init() {
        super.init()
        
        print("WatchAppDelegate.init()")

        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    func applicationDidFinishLaunching() {
        UNUserNotificationCenter.current().delegate = self
        WKExtension.shared().registerForRemoteNotifications()

        let session = WCSession.default
        session.delegate = self
        session.activate()
    }
    
    // Conform to UNUserNotificationCenterDelegate to show local notification in foreground
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        //print("COMPLETION HANDLER")
        return [.banner, .badge, .sound]
    }

    func didRegisterForRemoteNotifications(withDeviceToken deviceToken: Data) {
        self.deviceToken = deviceToken
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            print("Got notifications: \(granted)")
            self.notificationsGranted = granted
            if let error {
                print("Got error: \(error)")
            }
            if granted {
                let deviceToken = deviceToken.reduce("") {$0 + String(format: "%02x", $1)}
                try? WKData.default.set(key: WKDataKeys.watchDeviceToken, value: deviceToken)
                Task { try? await OpenGluckConnection.client?.register(deviceToken: deviceToken) }
            }
        }
    }

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            try? WKData.default.flush()
        }
    }
    
    private func checkReloadTimelines(_ userInfoKeys: [String]) {
        guard userInfoKeys.contains(WKDataKeys.debugComplication.rawValue) else {
            print("(not found)")
            return
        }
        WidgetKinds.DebugWidget.reloadTimeline()
    }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        let sendableUserInfo = userInfo as! [String: WKData.ValueType]
        print("WatchAppDelegate.session \(userInfo.description)")
        Task { @MainActor in
            WKData.default.didReceive(userInfo: sendableUserInfo)
            WidgetKinds.DebugWidget.reloadTimeline()
        }
    }
}
