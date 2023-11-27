import Foundation
import Contacts
import SwiftUI
import WidgetKit
import OG

#if OPENGLUCK_CONTACT_TRICK_IS_YES

class ContactUpdater
{
    // this is a debug feature, that you can use to force the contact to be updated
    let FORCE_UPDATE_CONTACT = false;
    var granted: Bool? = nil
    static let email = "bg@calendar-trick.opengluck.com"
    
    let store: CNContactStore = CNContactStore()
    
    private static func getUpdate(forTimestamp timestamp: Date?, episodeTimestamp: Date?) -> Date? {
        if let timestamp, let episodeTimestamp {
            return max(timestamp, episodeTimestamp)
        }
        if let timestamp {
            return timestamp
        }
        if let episodeTimestamp {
            return episodeTimestamp
        }
        return nil
    }
    
    var lastUpdate: Date? {
        return Self.getUpdate(forTimestamp: WKDefaults.shared.currentMeasurementTimestamp, episodeTimestamp: WKDefaults.shared.currentMeasurementEpisodeTimestamp)
    }
        
    struct UpdaterStatus: Codable {
        // this is serialized as the contact last name
        let mgDl: Int?
        let timestamp: Date?
        let episodeTimestamp: Date?
        let hasRealTime: Bool?
        let episode: Episode?
        
        enum CodingKeys: CodingKey {
            case mgDl
            case updatedAt
            case timestamp
            case episodeTimestamp
            case hasRealTime
            case episode
        }
        
        var updatedAt: Date {
            return ContactUpdater.getUpdate(forTimestamp: timestamp, episodeTimestamp: episodeTimestamp)!
        }
        
        init(from decoder: Decoder) throws {
            let container: KeyedDecodingContainer<ContactUpdater.UpdaterStatus.CodingKeys> = try decoder.container(keyedBy: ContactUpdater.UpdaterStatus.CodingKeys.self)
            self.mgDl = try container.decodeIfPresent(Int.self, forKey: ContactUpdater.UpdaterStatus.CodingKeys.mgDl)
            if let updatedAt = try container.decodeIfPresent(Date.self, forKey: ContactUpdater.UpdaterStatus.CodingKeys.updatedAt) {
                // old version
                self.timestamp = updatedAt
            } else {
                self.timestamp = try container.decodeIfPresent(Date.self, forKey: ContactUpdater.UpdaterStatus.CodingKeys.timestamp)
            }
            self.episodeTimestamp = try container.decodeIfPresent(Date.self, forKey: ContactUpdater.UpdaterStatus.CodingKeys.episodeTimestamp)
            self.hasRealTime = try container.decodeIfPresent(Bool.self, forKey: ContactUpdater.UpdaterStatus.CodingKeys.hasRealTime)
            self.episode = try container.decodeIfPresent(Episode.self, forKey: ContactUpdater.UpdaterStatus.CodingKeys.episode)
        }
    
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(mgDl, forKey: ContactUpdater.UpdaterStatus.CodingKeys.mgDl)
            try container.encode(timestamp, forKey: ContactUpdater.UpdaterStatus.CodingKeys.timestamp)
            try container.encode(episode, forKey: ContactUpdater.UpdaterStatus.CodingKeys.episode)
            try container.encode(episodeTimestamp, forKey: ContactUpdater.UpdaterStatus.CodingKeys.episodeTimestamp)
            try container.encode(hasRealTime, forKey: ContactUpdater.UpdaterStatus.CodingKeys.hasRealTime)
        }
         
        init(mgDl: Int?, timestamp: Date?, episode: Episode?, episodeTimestamp: Date?, hasRealTime: Bool?) {
            self.mgDl = mgDl
            self.timestamp = timestamp
            self.episodeTimestamp = episodeTimestamp
            self.hasRealTime = hasRealTime
            self.episode = episode
        }
    }
    
    init() {
    }
    
    struct RecordLogMessage: Codable {
        let becauseUpdateOf: String
        let mgDl: Int?
        let timestamp: String?
        let episode: Episode?
        let episodeTimestamp: String?
        let secondsAgo: Int
        let outcome: String
    }
    
    private enum ShouldUpdateStatus {
        case ok
        case skipSameMeasurementEpisode(lastMgDl: Int?, lastEpisode: Episode?)
        case skipNotLater(lastUpdate: Date?)
        case noTimestampError
    }
    private var queue = DispatchQueue(label: "PhoneContactUpdater")
    private func shouldUpdate(mgDl: Int?, timestamp: Date?, episode: Episode?, episodeTimestamp: Date?, hasRealTime: Bool?) -> ShouldUpdateStatus {
        guard !FORCE_UPDATE_CONTACT else {
            return .ok
        }
        return queue.sync(flags: .barrier) {
            let lastUpdate = self.lastUpdate
            guard let thisUpdate = Self.getUpdate(forTimestamp: timestamp, episodeTimestamp: episodeTimestamp) else {
                print("Cannot update as we have no timestamps, timestamp=\(String(describing: timestamp)), episodeTimestamp=\(String(describing: episodeTimestamp))")
                return ShouldUpdateStatus.noTimestampError
            }
            guard lastUpdate == nil || thisUpdate > lastUpdate! else {
                return ShouldUpdateStatus.skipNotLater(lastUpdate: lastUpdate)
            }
             //   print("Skip update earlier than last update, last=\(String(describing: lastTimestamp)), this=\(String(describing: timestamp))")
             //   await log("skipped: not later than previous update at \(String(describing: lastTimestamp))")
             //   return
            //}
            let lastMgDl = WKDefaults.shared.currentMeasurementMgDl
            let lastEpisode = WKDefaults.shared.currentMeasurementEpisode
            let lastEpisodeTimestamp = WKDefaults.shared.currentMeasurementEpisodeTimestamp
            if thisUpdate == timestamp && thisUpdate == episodeTimestamp {
                guard lastMgDl == nil ||  lastMgDl! == mgDl || lastEpisode == nil || lastEpisodeTimestamp! != timestamp else {
                    return ShouldUpdateStatus.skipSameMeasurementEpisode(lastMgDl: lastMgDl, lastEpisode: lastEpisode)
                }
            } else if thisUpdate == timestamp {
                guard lastMgDl == nil || lastMgDl! != mgDl else {
                    return ShouldUpdateStatus.skipSameMeasurementEpisode(lastMgDl: lastMgDl, lastEpisode: nil)
                }
            } else if thisUpdate == episodeTimestamp {
                guard lastEpisode == nil || lastEpisode! != episode else {
                    return ShouldUpdateStatus.skipSameMeasurementEpisode(lastMgDl: nil, lastEpisode: lastEpisode)
                }
            }

            print("==> before update; mgDl=\(String(describing: mgDl)), timestamp=\(String(describing: timestamp)), episode=\(String(describing: episode)), episodeTimestamp=\(String(describing: episodeTimestamp))")
            if let mgDl, let timestamp {
                WKDefaults.shared.currentMeasurementMgDl = mgDl
                WKDefaults.shared.currentMeasurementTimestamp = timestamp
            }
            if let episode, let episodeTimestamp {
                WKDefaults.shared.currentMeasurementEpisode = episode
                WKDefaults.shared.currentMeasurementEpisodeTimestamp = episodeTimestamp
            }
            WKDefaults.shared.currentMeasurementHasRealTime = hasRealTime ?? true
            
            return ShouldUpdateStatus.ok
            
            //await OpenGluck.recordLog(message: "ContactUpdater.updateMgDl(becauseUpdateOf: \(becauseUpdateOf)): Will update \(mgDl) at timestamp \(timestamp.description)")
            //await log("OK")
            
            //let predicate = CNContact.predicateForContacts(matchingEmailAddress: ContactUpdater.email)
            //let keysToFetch = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactImageDataKey] as [CNKeyDescriptor]
            //print("Will fetch contacts, updating to \(mgDl)")
            
        }
    }
    
    var contact: CNContact?  {
        get throws {
            let predicate = CNContact.predicateForContacts(matchingEmailAddress: ContactUpdater.email)
            let keysToFetch = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactImageDataKey] as [CNKeyDescriptor]
            
            let contacts = try self.store.unifiedContacts(matching: predicate, keysToFetch: keysToFetch)
            print("Found \(contacts.count) contact(s)")
            return contacts.first
        }
    }
    
    func updateMgDl(mgDl: Int?, timestamp: Date?, hasCgmRealTimeData: Bool?, episode: Episode?, episodeTimestamp: Date?, becauseUpdateOf: String, force: Bool? = false) async {
        let episode: Episode? = (hasCgmRealTimeData != nil && hasCgmRealTimeData!) ? nil : episode
        let episodeTimestamp: Date? = (hasCgmRealTimeData != nil && hasCgmRealTimeData!) ? nil : episodeTimestamp
        guard let thisUpdate = Self.getUpdate(forTimestamp: timestamp, episodeTimestamp: episodeTimestamp) else {
            print("Did not receive a timestamp for updateMgDl, do not update")
            return
        }
        
        func log(_ outcome: String) async {
            let secondsAgo = Int(-thisUpdate.timeIntervalSinceNow)
            print("Recording outcome: \(outcome) because update of \(becauseUpdateOf), mgDl=\(String(describing: mgDl)), timestamp=\(String(describing: timestamp)), episode=\(String(describing: episode)), episodeTimestamp=\(String(describing: episodeTimestamp)), thisUpdate=\(thisUpdate.ISO8601Format()), secondsAgo=\(secondsAgo)")
            await OpenGluckConnection.client?.recordLog(RecordLogMessage(becauseUpdateOf: becauseUpdateOf, mgDl: mgDl, timestamp: timestamp?.ISO8601Format(), episode: episode, episodeTimestamp: episodeTimestamp?.ISO8601Format(), secondsAgo: secondsAgo, outcome: outcome))
            
        }
        
        print("Updater.updateMgDl(mgDl=\(String(describing: mgDl)), last=\(WKDefaults.shared.currentMeasurementMgDl.debugDescription), episode=\(String(describing: episode)), lastEpisode=\(WKDefaults.shared.currentMeasurementEpisode.debugDescription)")
        
        if force == true {
            print("forcing update")
        } else {
            switch shouldUpdate(mgDl: mgDl, timestamp: timestamp, episode: episode, episodeTimestamp: episodeTimestamp, hasRealTime: hasCgmRealTimeData) {
            case .skipNotLater(lastUpdate: let lastUpdate):
                await log("skipped: not later than previous update at \(String(describing: lastUpdate))")
                return
            case .skipSameMeasurementEpisode(lastMgDl: let lastMgDl, lastEpisode: let lastEpisode):
                await log("skipped: same measurement: lastMgDl=\(String(describing: lastMgDl)), lastEpisode=\(String(describing: lastEpisode))")
                return
            case .ok:
                await log("OK")
            case .noTimestampError:
                await log("Error: did not find a timestamp")
            }
        }
        
        await updateImpl(force: force, log)
    }
    
    private func updateImpl(force: Bool? = false, _ log: (String) async -> Void) async {
        let lastMgDl = WKDefaults.shared.currentMeasurementMgDl
        let lastEpisode = WKDefaults.shared.currentMeasurementEpisode
        let lastTimestamp = WKDefaults.shared.currentMeasurementTimestamp
        let lastEpisodeTimestamp = WKDefaults.shared.currentMeasurementEpisodeTimestamp
        let lastHasRealTime = WKDefaults.shared.currentMeasurementHasRealTime
        
        WidgetCenter.shared.reloadAllTimelines() // at this point, the UserDefaults have already been updated
        
        do {
            guard let contact = try contact else {
                await log("Could not find contact")
                return
            }
            
            print("Will fetch contacts, updating to lastMgDl=\(String(describing: lastMgDl)), lastEpisode=\(String(describing: lastEpisode))")
            let jsonDecoder = JSONDecoder()
            jsonDecoder.dateDecodingStrategy = .iso8601
            if !FORCE_UPDATE_CONTACT, force != true, let previousUpdaterStatus = try? jsonDecoder.decode(UpdaterStatus.self, from: contact.familyName.data(using: .utf8)!) {
                print("Found previous updater status in contact: \(previousUpdaterStatus)")
                guard lastUpdate! > previousUpdaterStatus.updatedAt else {
                    await log("skipped: contact updated later, at \(String(describing: previousUpdaterStatus.updatedAt))")
                    return
                }
                guard previousUpdaterStatus.mgDl != lastMgDl || previousUpdaterStatus.episode != lastEpisode else {
                    await log("skipped: contact has same measurement and episode, mgDl=\(String(describing: previousUpdaterStatus.mgDl)), episode=\(String(describing: previousUpdaterStatus.episode))")
                    return
                }
            }
            await log("OK")
            
            guard let mutableContact = contact.mutableCopy() as? CNMutableContact else { return }
            
            let jsonEncoder = JSONEncoder()
            jsonEncoder.dateEncodingStrategy = .iso8601
            
            mutableContact.familyName = try String(data: jsonEncoder.encode(UpdaterStatus(mgDl: lastMgDl, timestamp: lastTimestamp!, episode: lastEpisode, episodeTimestamp: lastEpisodeTimestamp, hasRealTime: lastHasRealTime )), encoding: .utf8)!
            mutableContact.imageData = NumberImageView.getImage(timestamp: lastTimestamp, forMgDl: lastMgDl, hasCgmRealTimeData: lastHasRealTime, episode: lastEpisode, episodeTimestamp: lastEpisodeTimestamp).pngData()
            let saveRequest = CNSaveRequest()
            saveRequest.update(mutableContact)
            do {
                try self.store.execute(saveRequest)
                print("Contact updated")
            } catch {
                print("Error saving contact \(error)")
            }
        } catch {
            print("Caught error: \(error)")
        }
        print("Done updating for lastMgDl=\(lastMgDl.debugDescription), episode=\(lastEpisode.debugDescription)")
    }
    
    func updateContactIfStale() {
        do {
            let predicate = CNContact.predicateForContacts(matchingEmailAddress: ContactUpdater.email)
            let keysToFetch = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactImageDataKey] as [CNKeyDescriptor]
            let contacts = try store.unifiedContacts(matching: predicate, keysToFetch: keysToFetch)
            print("Found \(contacts.count) contact(s)")
            if let contact = contacts.first {
                guard let mutableContact = contact.mutableCopy() as? CNMutableContact else { return }
                
                print("Found contact: \(contact)")
                let familyName = contact.familyName
                let jsonDecoder = JSONDecoder()
                jsonDecoder.dateDecodingStrategy = .iso8601
                guard let data = familyName.data(using: .utf8) else {
                    return
                }
                let updaterStatus = try? jsonDecoder.decode(UpdaterStatus.self, from: data)
                let freshDuration = OpenGluckManager.freshDuration(hasRealTime: updaterStatus?.hasRealTime ?? false)
                print("Got updater status: \(String(describing: updaterStatus)), freshDuration=\(freshDuration)")
                if let updaterStatus, -updaterStatus.updatedAt.timeIntervalSinceNow > freshDuration {
                    print("Found stale record, last update was \(-updaterStatus.updatedAt.timeIntervalSinceNow) seconds ago")
                    mutableContact.givenName = "OpenGlück Stale at \(Date().description)"
                    mutableContact.imageData = NumberImageView.getImage(timestamp: nil, forMgDl: nil, hasCgmRealTimeData: nil, episode: .disconnected, episodeTimestamp: Date()).pngData()
                    if let hasRealTime = updaterStatus.hasRealTime, hasRealTime {
                        UNUserNotificationCenter.current().setBadgeCount(0)
                    }
                } else {
                    // not stale
                    print("Found fresh record")
                    return
                    //mutableContact.givenName = "OpenGlück Still fresh at \(Date().description)"
                }
                let saveRequest = CNSaveRequest()
                saveRequest.update(mutableContact)
                do {
                    try store.execute(saveRequest)
                    print("Contact updated")
                } catch {
                    print("Error saving contact \(error)")
                }
            }
        } catch {
            print("Caught error: \(error)")
        }    }
    
    func checkIfUpToDate() {
        store.requestAccess(for: .contacts, completionHandler: { granted, error in
            print("Contacts granted \(granted), error=\(error.debugDescription)")
            self.granted = granted
            guard granted else { return }
            self.updateContactIfStale()
        })
    }
}
#endif
