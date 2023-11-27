import Foundation
import OG

class WKDefaults {
    private init() {}
    static var shared = WKDefaults()
    
    var currentMeasurementMgDl: Int? {
        get {
            OpenGluckManager.userDefaults.integer(forKey: WKDataKeys.currentMeasurementMgDl.keyValue)
        }
        set {
            OpenGluckManager.userDefaults.set(newValue, forKey: WKDataKeys.currentMeasurementMgDl.keyValue)
        }
    }
    var currentMeasurementTimestamp: Date? {
        get {
            OpenGluckManager.userDefaults.object(forKey: WKDataKeys.currentMeasurementTimestamp.keyValue) as? Date
        }
        set {
            OpenGluckManager.userDefaults.set(newValue, forKey: WKDataKeys.currentMeasurementTimestamp.keyValue)
        }
    }
    var currentMeasurementEpisode: Episode? {
        get {
            guard let rawValue = OpenGluckManager.userDefaults.object(forKey: WKDataKeys.currentMeasurementEpisode.keyValue) as? String else {
                return nil
            }
            return Episode(rawValue: rawValue)
        }
        set {
            OpenGluckManager.userDefaults.set(newValue?.rawValue, forKey: WKDataKeys.currentMeasurementEpisode.keyValue)
        }
    }
    var currentMeasurementEpisodeTimestamp: Date? {
        get {
            OpenGluckManager.userDefaults.object(forKey: WKDataKeys.currentMeasurementEpisodeTimestamp.keyValue) as? Date
        }
        set {
            OpenGluckManager.userDefaults.set(newValue, forKey: WKDataKeys.currentMeasurementEpisodeTimestamp.keyValue)
        }
    }
    var currentMeasurementHasRealTime: Bool {
        get {
            OpenGluckManager.userDefaults.object(forKey: WKDataKeys.currentMeasurementHasRealTime.keyValue) as? Bool ?? true
        }
        set {
            OpenGluckManager.userDefaults.set(newValue, forKey: WKDataKeys.currentMeasurementHasRealTime.keyValue)
        }
    }

}
