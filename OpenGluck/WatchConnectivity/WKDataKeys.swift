import Foundation

enum WKDataKeys: String {
    case openglückUrl
    case openglückToken
    case phoneDeviceToken
    case watchDeviceToken
    
    case debugPhoneEmoji
    case debugWatchEmoji
    
    case debugComplication
    
    case currentMeasurementMgDl
    case currentMeasurementTimestamp
    case currentMeasurementEpisode
    case currentMeasurementEpisodeTimestamp
    case currentMeasurementHasRealTime
    
    case enableUpdateBadgeCount
    case showDataInMmolL
    
    #if OPENGLUCK_CONTACT_TRICK_IS_YES
    case enableContactTrick
    case enableContactTrickDebug
    #endif
    
    static func from(keyValue: String) -> WKDataKeys? {
        let rawValue = String(keyValue.dropFirst("WKData.".count))
        return WKDataKeys(rawValue: rawValue)
    }
    
    var keyValue: String {
        return "WKData.\(self.rawValue)"
    }
}

