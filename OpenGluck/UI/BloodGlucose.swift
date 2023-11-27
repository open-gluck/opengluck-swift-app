import SwiftUI

struct BloodGlucose: View {
    @AppStorage(WKDataKeys.showDataInMmolL.keyValue, store: OpenGluckManager.userDefaults) var showDataInMmolL: Bool = false

    let mgDl: Double
    
    enum Style {
        case short
        case long
    }
    
    static func localize(_ mgDl: Int, style: Style = Style.long) -> String {
        Self.localize(Double(mgDl), style: style)
    }
    
    static func localize(_ mgDl: Double, style: Style = Style.long) -> String {
        if OpenGluckManager.userDefaults.bool(forKey: WKDataKeys.showDataInMmolL.keyValue) {
            let mmolL = round(mgDl * 0.0555 * 10) / 10
            return style == .long ? "\(mmolL) mmol/L" : "\(mmolL)"
        } else {
            let mgDl = Int(round(mgDl))
            return style == .long ? "\(mgDl) mg/dL" : "\(mgDl)"
        }
    }
    
    var body: some View {
        Text(Self.localize(mgDl))
    }
}

