import Foundation
import SwiftUI
#if !os(tvOS)
import WidgetKit
#endif
@preconcurrency import OG // FIXME LATER TODO upgrade lib
@preconcurrency import OGUI // FIXME LATER TODO upgrade lib

@MainActor class OpenGluckConnectionEnablers {
#if OPENGLUCK_CONTACT_TRICK_IS_YES
    @AppStorage(WKDataKeys.enableContactTrick.keyValue, store: OpenGluckManager.userDefaults) var enableContactTrick: Bool = false
#endif
    @AppStorage(WKDataKeys.enableUpdateBadgeCount.keyValue, store: OpenGluckManager.userDefaults) var enableUpdateBadgeCount: Bool = false
    
    static let `default` = OpenGluckConnectionEnablers()
}

final class OpenGluckConnection: ObservableObject, OpenGluckSyncClientDelegate, Sendable {
    private let syncClient: OpenGluckSyncClient
    #if OPENGLUCK_CONTACT_TRICK_IS_YES
    let contactsUpdater = ContactUpdater()
    #endif

    init() {
        syncClient = OpenGluckSyncClient()
        OGUI.thresholdsDelegate = OpenGluckThreholdsDelegate() // thresholdsDelegate
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
    
    func getSyncClient() async -> OpenGluckSyncClient {
        await syncClient.setDelegate(self)
        return syncClient
    }
    
    func getCurrentData(becauseUpdateOf: String, force: Bool? = false) async throws -> CurrentData? {
        guard Self.client != nil else {
            return nil
        }
        let syncClient = await getSyncClient()
        let currentData = try await syncClient.getCurrentDataIfChanged()
        guard let currentData else {
            guard let lastSyncCurrentData = await syncClient.lastSyncCurrentData else {
                return nil
            }
            return lastSyncCurrentData
        }
        let hasCgmRealTimeData = currentData.hasCgmRealTimeData
        if let currentGlucoseRecord = currentData.currentGlucoseRecord {
            let episode = currentData.currentEpisode
            let episodeTimestamp = currentData.currentEpisodeTimestamp
#if OPENGLUCK_CONTACT_TRICK_IS_YES
            if await OpenGluckConnectionEnablers.default.enableContactTrick {
                await contactsUpdater.updateMgDl(mgDl: currentGlucoseRecord.mgDl, timestamp: currentGlucoseRecord.timestamp, hasCgmRealTimeData: hasCgmRealTimeData, episode: episode, episodeTimestamp: episodeTimestamp, becauseUpdateOf: becauseUpdateOf, force: force)
            }
#endif
        }
        let instantMgDl: Int? = currentData.currentInstantGlucoseRecord?.mgDl
        let instantTimestamp: Date? = currentData.currentInstantGlucoseRecord?.timestamp
        let dataTimestamp: Date? = currentData.currentGlucoseRecord?.timestamp
        let mostRecentTimestamp: Date? = if let instantTimestamp, let dataTimestamp {
            max(instantTimestamp, dataTimestamp)
        } else if let instantTimestamp {
            instantTimestamp
        } else if let dataTimestamp {
            dataTimestamp
        } else {
            nil
        }
#if os(iOS)
        if let mostRecentTimestamp, -mostRecentTimestamp.timeIntervalSinceNow >= OpenGluckUI.maxGlucoseFreshnessTimeInterval {
            try await UNUserNotificationCenter.current().setBadgeCount(0)
        } else if let mgDl: Int = currentData.currentGlucoseRecord?.mgDl {
            if await OpenGluckConnectionEnablers.default.enableUpdateBadgeCount {
                try await UNUserNotificationCenter.current().setBadgeCount(instantMgDl ?? mgDl)
            }
        }
#endif
#if !os(tvOS)
        if let client = getClient() {
            await client.recordLog("reloading all timelines because of \(becauseUpdateOf)")
            WidgetCenter.shared.reloadAllTimelines()
        }
#endif
        return currentData
    }
}
