import SwiftUI
import BackgroundTasks
import UserNotifications
import WatchConnectivity
import os
import OG
import WidgetKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        Self.handleShortcutItem(shortcutItem)
        completionHandler(true)
    }
        
    static func handleShortcutItem(_ shortcutItem: UIApplicationShortcutItem) {
        Task {
            if shortcutItem.type == "add-insulin" {
                await UIApplication.shared.open(PhoneNavigationData.urlAddInsulin)
            } else if shortcutItem.type == "add-low" {
                await UIApplication.shared.open(PhoneNavigationData.urlAddLow)
            }
        }
    }
}

class PhoneAppDelegate: UIResponder, UIApplicationDelegate, WCSessionDelegate, ObservableObject {
#if OPENGLUCK_CONTACT_TRICK_IS_YES
    @AppStorage(WKDataKeys.enableContactTrick.keyValue, store: OpenGluckManager.userDefaults) var enableContactTrick: Bool = false
#endif

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: PhoneAppDelegate.self)
    )

    let navigationData = PhoneNavigationData()
    let openGlückConnection = OpenGluckConnection()
    let sheetStatusOptions: SheetStatusViewOptions = SheetStatusViewOptions()
    private var deviceToken: String?
    
    var notificationsGranted: Bool = false
    override init() {
        super.init()
    }

    var openglückUrl: String {
        get {
            return WKData.default.get(key: WKDataKeys.openglückUrl) as! String? ?? ""
        }
        set {
            try? WKData.default.set(key: WKDataKeys.openglückUrl, value: newValue)
            self.registerDeviceTokenWithOpenGluck()
        }
    }

    var openglückToken: String {
        get {
            return WKData.default.get(key: WKDataKeys.openglückToken) as! String? ?? ""
        }
        set {
            try? WKData.default.set(key: WKDataKeys.openglückToken, value: newValue)
            self.registerDeviceTokenWithOpenGluck()
        }
    }

    func scheduleBackgroundTask() {
        let task = BGAppRefreshTaskRequest(identifier: Bundle.main.bundleIdentifier!)
        try? BGTaskScheduler.shared.submit(task)
        print("Done scheduling")
    }

    private func handleAppRefresh(task: BGAppRefreshTask) {
        self.scheduleBackgroundTask()
        
        Task {
            // as a last resort, try to update one last time
            try? _ = await openGlückConnection.getCurrentData(becauseUpdateOf: "Background App Refresh")
            
#if OPENGLUCK_CONTACT_TRICK_IS_YES
            openGlückConnection.contactsUpdater.checkIfUpToDate()
#endif
            task.setTaskCompleted(success: true)
        }
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else {
            print("skip didFinishLaunchingWithOptions in preview")
            return true
        }

        let center = UNUserNotificationCenter.current()
        center.delegate = self

        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Authorization for notification failed \(error)")
            }
            if granted {
                self.notificationsGranted = true
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            }
        }
        
        setupNotificationActions()
        

        BGTaskScheduler.shared.register(forTaskWithIdentifier: Bundle.main.bundleIdentifier!, using: nil) { (task) in
            print("Running task!")
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }

        NotificationCenter.default.addObserver(forName:UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { (_) in
            print("NotificationCenter.default.didBecomeActiveNotification")
            Task {
                await MainActor.run {
                    OpenGluckEnvironment.enableAutoUpdate = true
                }
            }
        }
        NotificationCenter.default.addObserver(forName:UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { (_) in
            print("NotificationCenter.default.addObserver")
            Task {
                await MainActor.run {
                    OpenGluckEnvironment.enableAutoUpdate = false
                    self.scheduleBackgroundTask()
                }
            }
        }

        let session = WCSession.default
        session.delegate = self
        session.activate()
        try? WKData.default.syncToOther(key: WKDataKeys.openglückUrl)
        try? WKData.default.syncToOther(key: WKDataKeys.openglückToken)

        self.registerDeviceTokenWithOpenGluck()
        
        if let shortcutItem = launchOptions?[UIApplication.LaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem {
            SceneDelegate.handleShortcutItem(shortcutItem)
        }
        
#if OPENGLUCK_CONTACT_TRICK_IS_YES
        if enableContactTrick {
            Task {
                await openGlückConnection.contactsUpdater.requestAccess()
                let _ = try? await openGlückConnection.getCurrentData(becauseUpdateOf: "UIApplication.didBecomeActiveNotification", force: true)
            }
        }
#endif
        
        AppsShortcuts.updateAppShortcutParameters()
        return true
    }
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let sceneConfig = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        sceneConfig.delegateClass = SceneDelegate.self
        return sceneConfig
    }

    func registerDeviceTokenWithOpenGluck() {
        if let deviceToken {
            Task { try? await OpenGluckConnection.client?.register(deviceToken: deviceToken) }
        }
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let deviceToken = deviceToken.reduce("") {$0 + String(format: "%02x", $1)}
        try? WKData.default.set(key: WKDataKeys.phoneDeviceToken, value: deviceToken)
        self.deviceToken = deviceToken
        registerDeviceTokenWithOpenGluck()
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        try? WKData.default.flush()
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
    }

    func sessionDidDeactivate(_ session: WCSession) {
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        WKData.default.didReceive(userInfo: message)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        WKData.default.didReceive(userInfo: message)
        replyHandler([:])
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        WKData.default.didReceive(userInfo: userInfo)
    }
}

// Conform to UNUserNotificationCenterDelegate to show local notification in foreground
extension PhoneAppDelegate: UNUserNotificationCenterDelegate {
    private func parseNotificationsUserInfo(userInfo: [AnyHashable:Any]) -> (Date?, Int?, Bool?, Episode?, Date?, Bool?) {
        print(userInfo.debugDescription)
        let timestampStr: String? = userInfo["timestamp"] as? String
        let timestamp: Date? = timestampStr != nil ? ISO8601DateFormatter().date(from: timestampStr!.replacingOccurrences(of: "\\.\\d+", with: "", options: .regularExpression)) : nil
        let mgDl: Int? = userInfo["mgDl"] as? Int
        if let mgDl, let aps = userInfo["aps"] as? [String:Any], let badge = aps["badge"] as? Int {
            guard mgDl == badge else {
                Self.logger.warning("Mismatch mgDl=\(mgDl), badge=\(badge)")
                return (nil, nil, nil, nil, nil, nil)
            }
        }
        let hasRealTime: Bool? = userInfo["hasRealTime"] as? Bool
        let isNewScanOrHistoric: Bool? = userInfo["isNewScanOrHistoric"] as? Bool

        let episode: Episode?
        let episodeTimestamp: Date?
        if let currentEpisodeRecord = userInfo["currentEpisodeRecord"] as? [AnyHashable:Any], let episodeTimestampString = currentEpisodeRecord["timestamp"] as? String {
            if let userInfoEpisode = currentEpisodeRecord["episode"] as? String {
                episode = Episode(rawValue: userInfoEpisode)
            } else {
                episode = nil
            }
            episodeTimestamp = ISO8601DateFormatter().date(from: episodeTimestampString.replacingOccurrences(of: "\\.\\d+", with: "", options: .regularExpression))
        } else {
            episode = nil
            episodeTimestamp = nil
        }
        return (timestamp, mgDl, hasRealTime, episode, episodeTimestamp, isNewScanOrHistoric)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) async -> UIBackgroundFetchResult {
        let (timestamp, mgDl, hasRealTime, episode, episodeTimestamp, isNewScanOrHistoric) = parseNotificationsUserInfo(userInfo: userInfo)
        Self.logger.info("Received remote notification => timestamp=\(String(describing: timestamp)) mgDl=\(String(describing: mgDl)), userInfo=\(userInfo), episode=\(String(describing: episode)), episodeTimestamp=\(String(describing: episodeTimestamp)), isNewScanOrHistoric=\(String(describing: isNewScanOrHistoric))")
        if let isNewScanOrHistoric, isNewScanOrHistoric {
            await openGlückConnection.getClient()?.recordLog("did receive notification, reload all timelines")
            WidgetCenter.shared.reloadAllTimelines()
        }
#if OPENGLUCK_CONTACT_TRICK_IS_YES
        await openGlückConnection.contactsUpdater.updateMgDl(mgDl: mgDl, timestamp: timestamp, hasCgmRealTimeData: hasRealTime, episode: episode, episodeTimestamp: episodeTimestamp, becauseUpdateOf: "didReceiveRemoteNotification")
#endif
        return .newData
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        // showing notification with app active
        let userInfo = notification.request.content.userInfo
        let (timestamp, mgDl, hasRealTime, episode, episodeTimestamp, isNewScanOrHistoric) = parseNotificationsUserInfo(userInfo: userInfo)
        Self.logger.info("Received user notification while app in foreground => timestamp=\(String(describing: timestamp)) mgDl=\(String(describing: mgDl)), episode=\(String(describing: episode)), episodeTimestamp=\(String(describing: episodeTimestamp)), userInfo=\(userInfo), episode=\(String(describing: episode)), episodeTimestamp=\(String(describing: episodeTimestamp)), isNewScanOrHistoric=\(String(describing: isNewScanOrHistoric))")
        if let isNewScanOrHistoric, isNewScanOrHistoric {
            await openGlückConnection.getClient()?.recordLog("present notification, reload all timelines")
            WidgetCenter.shared.reloadAllTimelines()
        }
#if OPENGLUCK_CONTACT_TRICK_IS_YES
        await openGlückConnection.contactsUpdater.updateMgDl(mgDl: mgDl, timestamp: timestamp, hasCgmRealTimeData: hasRealTime, episode: episode, episodeTimestamp: episodeTimestamp, becauseUpdateOf: "userNotificationCenter.willPresent")
#endif
        return [.banner, .badge, .sound]
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        await handleAction(response: response)
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        print("applicationDidEnterBackground")
        scheduleBackgroundTask()
    }
}

/* handle custom actions */
extension PhoneAppDelegate {
    private enum NotificationActions: String {
        case SNOOZE_LOW_ACTION
    }

    private func setupNotificationActions() {
        let center = UNUserNotificationCenter.current()

        let snoozeLowAction = UNNotificationAction(identifier: NotificationActions.SNOOZE_LOW_ACTION.rawValue,
                                                   title: "Snooze Low",
                                                   options: [])
        let lowCategory = UNNotificationCategory(identifier: "LOW",
                                                 actions: [snoozeLowAction],
                                                 intentIdentifiers: [],
                                                 hiddenPreviewsBodyPlaceholder: "",
                                                 options: [])
        
        center.setNotificationCategories([lowCategory])
    }
    
    private func reportErrorUsingNotification(title: String, error: Error) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = error.localizedDescription
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil  // Will show immediately
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Failed to schedule confirmation: \(error.localizedDescription)")
        }

    }

    private func handleAction(response: UNNotificationResponse) async {
        let action: NotificationActions? = NotificationActions(rawValue: response.actionIdentifier)
        guard let action else {
            return
        }
        switch action {
        case NotificationActions.SNOOZE_LOW_ACTION:
            let intent = AddSnoozedLowAppIntent()
            do {
                let _ = try await intent.perform()
            } catch {
                await reportErrorUsingNotification(title: "Could Not Snooze Low", error: error)
            }
        }
    }
}
