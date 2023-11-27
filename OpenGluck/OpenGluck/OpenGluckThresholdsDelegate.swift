import SwiftUI
import OGUI

enum OpenGluckThreholdsDelegateValues: String {
    case normalLow = "OpenGlückConnection.thresholds.normalLow"
    case normalHigh = "OpenGlückConnection.thresholds.normalHigh"
    case low = "OpenGlückConnection.thresholds.low"
    case high = "OpenGlückConnection.thresholds.high"
    case highVeryHigh = "OpenGlückConnection.thresholds.highVeryHigh"
}

class OpenGluckThreholdsDelegate: OGUIThresholdsDelegate {
    @AppStorage(OpenGluckThreholdsDelegateValues.normalLow.rawValue, store: OpenGluckManager.userDefaults) var appStorageThresholdsNormalLow: String = ""
    @AppStorage(OpenGluckThreholdsDelegateValues.normalHigh.rawValue, store: OpenGluckManager.userDefaults) var appStorageThresholdsNormalHigh: String = ""
    @AppStorage(OpenGluckThreholdsDelegateValues.low.rawValue, store: OpenGluckManager.userDefaults) var appStorageThresholdsLow: String = ""
    @AppStorage(OpenGluckThreholdsDelegateValues.high.rawValue, store: OpenGluckManager.userDefaults) var appStorageThresholdsHigh: String = ""
    @AppStorage(OpenGluckThreholdsDelegateValues.highVeryHigh.rawValue, store: OpenGluckManager.userDefaults) var appStorageThresholdsHighVeryHigh: String = ""
    
    var normalLow: Double {
        if appStorageThresholdsNormalLow.isEmpty {
            return DefaultOGUIThresholdsDelegate.defaultNormalLow
        }
        return Double(appStorageThresholdsNormalLow)!
    }
    
    var normalHigh: Double {
        if appStorageThresholdsNormalHigh.isEmpty {
            return DefaultOGUIThresholdsDelegate.defaultNormalHigh
        }
        return Double(appStorageThresholdsNormalHigh)!
    }
    
    var low: Double {
        if appStorageThresholdsLow.isEmpty {
            return DefaultOGUIThresholdsDelegate.defaultLow
        }
        return Double(appStorageThresholdsLow)!
    }
    
    var high: Double {
        if appStorageThresholdsHigh.isEmpty {
            return DefaultOGUIThresholdsDelegate.defaultHigh
        }
        return Double(appStorageThresholdsHigh)!
    }
    
    var highVeryHigh: Double {
        if appStorageThresholdsHighVeryHigh.isEmpty {
            return DefaultOGUIThresholdsDelegate.defaultHighVeryHigh
        }
        return Double(appStorageThresholdsHighVeryHigh)!
    }
}
