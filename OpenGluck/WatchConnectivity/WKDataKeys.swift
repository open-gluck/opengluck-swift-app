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
    
    case showDataInMmolL
    
    case enableContactTrick
    
    static func from(keyValue: String) -> WKDataKeys? {
        let rawValue = String(keyValue.dropFirst("WKData.".count))
        return WKDataKeys(rawValue: rawValue)
    }
    
    var keyValue: String {
        return "WKData.\(self.rawValue)"
    }
}

