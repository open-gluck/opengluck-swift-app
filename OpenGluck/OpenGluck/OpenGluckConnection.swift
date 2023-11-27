import Foundation
import SwiftUI
#if !os(tvOS)
import WidgetKit
#endif
import OG
import OGUI

class OpenGluckConnection: ObservableObject, OpenGluckSyncClientDelegate {
    let syncClient: OpenGluckSyncClient
    #if OPENGLUCK_CONTACT_TRICK_IS_YES
    let contactsUpdater = ContactUpdater()
    @AppStorage(WKDataKeys.enableContactTrick.keyValue, store: OpenGluckManager.userDefaults) var enableContactTrick: Bool = false
    #endif
    let thresholdsDelegate = OpenGluckThreholdsDelegate()

    init() {
        syncClient = OpenGluckSyncClient()
        syncClient.delegate = self
        OGUI.thresholdsDelegate = thresholdsDelegate
    }
    
    static var client: OpenGluckClient? {
        guard let url = OpenGluckManager.openglückUrl, let token = OpenGluckManager.openglückToken, !url.isEmpty, !token.isEmpty else {
            return nil
            
        }
        guard token.count == 32 else {
            return nil
        }
        return OpenGluckClient(hostname: url, token: token, target: OpenGluckManager.target)
    }
    
    func getClient() -> OpenGluckClient? {
        Self.client
    }
    
    func getCurrentData(becauseUpdateOf: String, force: Bool? = false) async throws -> CurrentData? {
        guard Self.client != nil else {
            return nil
        }
        let currentData = try await syncClient.getCurrentDataIfChanged()
        guard let currentData else {
            guard let lastSyncCurrentData = syncClient.lastSyncCurrentData else {
                return nil
            }
            return lastSyncCurrentData
        }
        let hasCgmRealTimeData = currentData.hasCgmRealTimeData
        if let currentGlucoseRecord = currentData.currentGlucoseRecord {
            let episode = currentData.currentEpisode
            let episodeTimestamp = currentData.currentEpisodeTimestamp
#if OPENGLUCK_CONTACT_TRICK_IS_YES
            if enableContactTrick {
                await contactsUpdater.updateMgDl(mgDl: currentGlucoseRecord.mgDl, timestamp: currentGlucoseRecord.timestamp, hasCgmRealTimeData: hasCgmRealTimeData, episode: episode, episodeTimestamp: episodeTimestamp, becauseUpdateOf: becauseUpdateOf, force: force)
            }
#endif
        }
        if let mgDl: Int = currentData.currentGlucoseRecord?.mgDl {
#if os(iOS)
            try await UNUserNotificationCenter.current().setBadgeCount(mgDl)
#endif
        }
#if !os(tvOS)
        WidgetCenter.shared.reloadAllTimelines()
#endif
        return currentData
    }
}
