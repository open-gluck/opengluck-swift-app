import SwiftUI
import OGUI
import OG

@MainActor
class CurrentDataColors {
    private init() {}
    
    static let lowColor = OGUI.lowColor
    static let lowColorText = OGUI.lowColorText

    static let normalColor = OGUI.normalColor
    static let normalColorText = OGUI.normalColorText

    static let highColor = OGUI.highColor
    static let highColorText = OGUI.highColorText

    static let veryHighColor = OGUI.veryHighColor
    static let veryHighColorText = OGUI.veryHighColorText

    static let unknownColor = Color(red: 0x00 / 256, green: 0x00 / 256, blue: 0x00 / 256)
    static let unknownColorText = Color(red: 0xff / 256, green: 0xff / 256, blue: 0xff / 256)
    
    static let disconnectedColor = Color(red: 0x88 / 256, green: 0x88 / 256, blue: 0x88 / 256)
    static let disconnectedColorText = Color(red: 0xff / 256, green: 0xff / 256, blue: 0xff / 256)
    
    static func getInfo(forEpisode episode: Episode) -> (Color, Color, String?, String?) {
        switch episode {
        case .disconnected: return (disconnectedColor, disconnectedColorText, "—", nil)
        case .unknown:      return (unknownColor, unknownColorText, "?", nil)
        case .error:        return (Color(UIColor.purple), unknownColorText, nil, "xmark.octagon.fill")
        case .low:          return (lowColor, lowColorText, nil, "octagon.fill")
        case .normal:       return (normalColor, normalColorText, nil, "octagon.fill")
        case .high:         return (highColor, highColorText, nil, "octagon.fill")
        }
    }
    
    static func getInfo(forMgDl mgDl: Int, hasCgmRealTimeData: Bool?) -> (Color, Color, String?, String?) {
        let colorText: Color
        let color: Color
        let string: String

        if let hasCgmRealTimeData, hasCgmRealTimeData {
            colorText = OGUI.glucoseTextColor(mgDl: Double(mgDl))
            color = OGUI.glucoseColor(mgDl: Double(mgDl))
        } else {
            colorText = CurrentDataColors.unknownColorText
            color = unknownColor
        }
        string = BloodGlucose.localize(mgDl, style: .short)
        
        return (color, colorText, string, nil)
    }
    
}


