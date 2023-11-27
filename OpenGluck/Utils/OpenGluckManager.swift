import Foundation

final class OpenGluckManager
{
    private init() {
    }
    
    static let freshDurationRealTimeData: TimeInterval = 22 * 60 // 22m
    static let freshDurationNotRealTimeData: TimeInterval = 60 * 60 // 60m
    
    private static func readDefaults() {
        // This is used to override the URL/token of the server for development builds.
        // Create a file DevelopmentSecrets.xcconfig in the root, and include the two variables
        // defined here.
        guard let infoDictionary: [String: Any] = Bundle.main.infoDictionary else { return }
        if let defaultUrl: String = infoDictionary["OPENGLUCK_DEFAULT_URL"] as? String, !defaultUrl.isEmpty {
            userDefaults.set(defaultUrl, forKey: WKDataKeys.openglückUrl.keyValue)
        }
        if let defaultToken: String = infoDictionary["OPENGLUCK_DEFAULT_TOKEN"] as? String, !defaultToken.isEmpty {
            userDefaults.set(defaultToken, forKey: WKDataKeys.openglückToken.keyValue)
        }
    }
    
    static func freshDuration(hasRealTime: Bool) -> TimeInterval {
        return hasRealTime ? freshDurationRealTimeData : freshDurationNotRealTimeData
    }
    
    static var userDefaults: UserDefaults {
        UserDefaults(suiteName: "group.open-gluck.github.io.ios")!
    }
    
    static var openglückUrl: String? {
        readDefaults()
        guard let url = userDefaults.string(forKey: WKDataKeys.openglückUrl.keyValue) else {
            return nil
        }
        guard !url.isEmpty else {
            return nil
        }
        return url
    }

    static var openglückToken: String? {
        readDefaults()
        guard let token = userDefaults.string(forKey: WKDataKeys.openglückToken.keyValue) else {
            return nil
        }
        guard !token.isEmpty else {
            return nil
        }
        return token
    }
    
}

extension OpenGluckManager {
    static func secondsToTextAgo(_ elapsed: TimeInterval) -> String {
        let elapsedMinutes = Int(-elapsed / 60)
        let minutes = elapsedMinutes % 60
        let elapsedHours = (elapsedMinutes - minutes) / 60
        let hours = elapsedHours % 24
        let days = (elapsedHours - hours) / 24
        if elapsedMinutes < 0 {
            return "in the future"
        }
        if days >= 1 {
            return "\(days)d ago"
        } else if hours >= 1 {
            if minutes > 0 {
                return "\(hours)h \(minutes)m ago"
            } else {
                return "\(hours)h ago"
            }
        } else {
            return "\(minutes)m ago"
        }
    }

    static func minutesToText(elapsedMinutes: Int) -> String {
        let minutes = elapsedMinutes % 60
        let elapsedHours = (elapsedMinutes - minutes) / 60
        let hours = elapsedHours % 24
        let days = (elapsedHours - hours) / 24
        if elapsedMinutes < 0 {
            return "in the future"
        }
        if days >= 1 {
            return "\(days)d \(hours)h \(minutes)m"
        } else if hours >= 1 {
            if minutes > 0 {
                return "\(hours)h \(minutes)m"
            } else {
                return "\(hours)h"
            }
        } else {
            return "\(minutes)m"
        }
    }
}
