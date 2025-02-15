import SwiftUI
import OG

struct CurrentGlucose: View {
    @EnvironmentObject var openGlückEnvironment: OpenGluckEnvironment
    let now: Date

    var body: some View {
        if let currentGlucoseRecord = openGlückEnvironment.currentGlucoseRecord {
            let currentInstantGlucoseRecord: OpenGluckInstantGlucoseRecord? = if let currentInstantGlucoseRecord = openGlückEnvironment.currentInstantGlucoseRecord {
                if currentInstantGlucoseRecord.timestamp > currentGlucoseRecord.timestamp { currentInstantGlucoseRecord } else { nil }
            } else {
                nil
            }
#if os(tvOS)
            GlucoseView(
                glucoseRecord: .constant(currentGlucoseRecord),
                hasCgmRealTimeData: .constant(openGlückEnvironment.cgmHasRealTimeData),
                font: .system(size: 35),
                captionFont: .system(size: 15),
                mode: .coloredBackground
            )
#else
            let freshnessLevel = 1.0 - (-currentGlucoseRecord.timestamp.timeIntervalSince(now) / OpenGluckUI.maxGlucoseFreshnessTimeInterval)
            let currentInstantIsFresh = if let timestamp = currentInstantGlucoseRecord?.timestamp { -timestamp.timeIntervalSince(now) < OpenGluckUI.maxGlucoseFreshnessTimeInterval } else { false }
            if freshnessLevel <= 0 {
                CurrentDataGauge(timestamp: .constant(nil), mgDl: .constant(nil), instantMgDl: .constant(nil), hasCgmRealTimeData: .constant(openGlückEnvironment.cgmHasRealTimeData), episode: .constant(.disconnected), episodeTimestamp: .constant(now), freshnessLevel: .constant(freshnessLevel))
            } else {
                CurrentDataGauge(timestamp: .constant(currentGlucoseRecord.timestamp), mgDl: .constant(currentGlucoseRecord.mgDl), instantMgDl: .constant(currentInstantIsFresh ? currentInstantGlucoseRecord?.mgDl : nil), hasCgmRealTimeData: .constant(openGlückEnvironment.cgmHasRealTimeData), episode: .constant(nil), episodeTimestamp: .constant(nil), freshnessLevel: .constant(freshnessLevel))
            }
#endif
        }
    }
}

#Preview {
    OpenGluckEnvironmentUpdater {
        Grid {
            GridRow {
                TimelineView(.everyMinute) { context in
                    CurrentGlucose(now: context.date)
                }
            }
        }
    }
    .environmentObject(OpenGluckConnection())
}

/*
// this is a debug view that randomly spills a value
struct CurrentGlucose: View {
    @EnvironmentObject var openGlückEnvironment: OpenGluckEnvironment
    let now: Date
    let timer = Timer.publish(every: 0.3, on: .main, in: .common).autoconnect()
    @State var instantMgDl: Int? = nil

    var body: some View {
        if let currentGlucoseRecord = openGlückEnvironment.currentGlucoseRecord {
            let currentInstantGlucoseRecord = openGlückEnvironment.currentInstantGlucoseRecord
#if os(tvOS)
            GlucoseView(
                glucoseRecord: .constant(currentGlucoseRecord),
                hasCgmRealTimeData: .constant(openGlückEnvironment.cgmHasRealTimeData),
                font: .system(size: 35),
                captionFont: .system(size: 15),
                mode: .coloredBackground
            )
#else
            let freshnessLevel = 1.0 - (-currentGlucoseRecord.timestamp.timeIntervalSince(now) / OpenGluckUI.maxGlucoseFreshnessTimeInterval)
            let currentInstantIsFresh = if let timestamp = currentInstantGlucoseRecord?.timestamp { -timestamp.timeIntervalSince(now) < OpenGluckUI.maxGlucoseFreshnessTimeInterval } else { false }
            CurrentDataGauge(timestamp: .constant(currentGlucoseRecord.timestamp), mgDl: .constant(currentGlucoseRecord.mgDl), instantMgDl: $instantMgDl, hasCgmRealTimeData: .constant(openGlückEnvironment.cgmHasRealTimeData), episode: .constant(nil), episodeTimestamp: .constant(nil), freshnessLevel: .constant(freshnessLevel))
                .onReceive(timer) { _ in
                    instantMgDl = .random(in: 50...80)
                }
#endif
        }
    }
}
*/
