import SwiftUI

struct InsulinUnit: View {
    let units: Int
    
    enum Style {
        case short
        case long
    }
    
    static func localize(_ units: Int) -> String {
        Self.localize(Double(units))
    }
    
    static func localize(_ units: Double) -> String {
        if abs(units - round(units)) < Double.ulpOfOne {
            return "\(Int(round(units))) IU"
        } else {
            return "\(round(units * 10) / 10) IU"
        }
    }
    
    var body: some View {
        Text(Self.localize(units))
    }
    
    static func foregroundColor(forTimestamp timestamp: Date) -> Color? {
        let elapsed = -timestamp.timeIntervalSinceNow
        if elapsed < 30 * 60 {
            return Color.orange
        } else if elapsed < 60 * 60 {
            return Color.red
        } else {
            return nil
        }
    }
}

