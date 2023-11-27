import SwiftUI
import OGUI

fileprivate struct GlucoseSlider: View {
    @Binding var value: Double
    @State var current: Double?
    
    var body: some View {
        HStack {
            Slider(value: .init(get: {
                value
            }, set: { unroundedValue in
                let roundedValue = round(unroundedValue)
                current = roundedValue
                self.value = roundedValue
            }), in: 0...300)
            ZStack {
                if let current {
                    BloodGlucose(mgDl: current)
                }
                // keep some width for large numbers
                Text("999 mg/dL").opacity(0)
            }
        }.task(id: value) {
            current = value
        }
    }
}

struct PreferencesView: View {
    @AppStorage(OpenGluckThreholdsDelegateValues.normalLow.rawValue, store: OpenGluckManager.userDefaults) var appStorageThresholdsNormalLow: String = ""
    @AppStorage(OpenGluckThreholdsDelegateValues.normalHigh.rawValue, store: OpenGluckManager.userDefaults) var appStorageThresholdsNormalHigh: String = ""
    @AppStorage(OpenGluckThreholdsDelegateValues.low.rawValue, store: OpenGluckManager.userDefaults) var appStorageThresholdsLow: String = ""
    @AppStorage(OpenGluckThreholdsDelegateValues.high.rawValue, store: OpenGluckManager.userDefaults) var appStorageThresholdsHigh: String = ""
    @AppStorage(OpenGluckThreholdsDelegateValues.highVeryHigh.rawValue, store: OpenGluckManager.userDefaults) var appStorageThresholdsHighVeryHigh: String = ""
    @AppStorage(WKDataKeys.showDataInMmolL.keyValue, store: OpenGluckManager.userDefaults) var showDataInMmolL: Bool = false

    let thresholdsDelegate = OpenGluckThreholdsDelegate()
    @State var rerender: UUID = UUID()

    var body: some View {
        if rerender.uuidString.isEmpty {} // rerender we we reset
        
        Form {
            Section("Units") {
                Picker("Show Blood Glucose in", selection: $showDataInMmolL) {
                    Text("mg/dL")
                        .tag(false)
                    Text("mmol/L")
                        .tag(true)
                }
            }
            Section("Thresholds") {
                Section("Low") {
                    GlucoseSlider(value: .init(get: {
                        thresholdsDelegate.low
                    }, set: { value in
                        appStorageThresholdsLow = String(value)
                    }))
                }
                .tint(OGUI.lowColor)
                .foregroundColor(OGUI.lowColor)
                
                Section("Low → Normal") {
                    GlucoseSlider(value: .init(get: {
                        thresholdsDelegate.normalLow
                    }, set: { value in
                        appStorageThresholdsNormalLow = String(value)
                    }))
                }
                .tint(OGUI.normalColor)
                .foregroundColor(OGUI.normalColor)
                
                
                Section("Normal → High") {
                    GlucoseSlider(value: .init(get: {
                        thresholdsDelegate.normalHigh
                    }, set: { value in
                        appStorageThresholdsNormalHigh = String(value)
                    }))
                }
                .tint(OGUI.normalColor)
                .foregroundColor(OGUI.normalColor)
                
                Section("High") {
                    GlucoseSlider(value: .init(get: {
                        thresholdsDelegate.high
                    }, set: { value in
                        appStorageThresholdsHigh = String(value)
                    }))
                }
                .tint(OGUI.highColor)
                .foregroundColor(OGUI.highColor)
                
                Section("High → Very High") {
                    GlucoseSlider(value: .init(get: {
                        thresholdsDelegate.highVeryHigh
                    }, set: { value in
                        appStorageThresholdsHighVeryHigh = String(value)
                    }))
                }
                .tint(OGUI.veryHighColor)
                .foregroundColor(OGUI.veryHighColor)
                
                Button("Reset All Thresholds To Defaults", role: .destructive) {
                    appStorageThresholdsNormalLow = ""
                    appStorageThresholdsNormalHigh = ""
                    appStorageThresholdsLow = ""
                    appStorageThresholdsHigh = ""
                    appStorageThresholdsHighVeryHigh = ""
                    rerender = UUID()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        PreferencesView()
    }
}
