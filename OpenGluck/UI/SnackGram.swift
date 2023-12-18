import SwiftUI
import OGUI

struct SnackGram: View {
    let sugarInGrams: Double
    
    enum Style {
        case short
        case long
    }
    
    static func localize(_ sugarInGrams: Int) -> String {
        Self.localize(Double(sugarInGrams))
    }
    
    static func localize(_ sugarInGrams: Double) -> String {
        return "\(Int(round(sugarInGrams)))g"
    }
    
    var body: some View {
        Text(Self.localize(sugarInGrams))
    }
    
    static func foregroundColor(forTimestamp timestamp: Date) -> Color? {
        let elapsed = -timestamp.timeIntervalSinceNow
        if elapsed < 30 * 60 {
            return OGUI.lowColor
        } else if elapsed < 60 * 60 {
#if os(watchOS)
            return Color.white
#else
            return Color(uiColor: .label)
#endif
        } else {
#if os(watchOS)
            return Color.gray
#else
            return Color(uiColor: .placeholderText)
#endif
        }
    }
}

