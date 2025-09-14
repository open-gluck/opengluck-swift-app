import WidgetKit
import SwiftUI
import os
import OG

struct CurrentBloodGlucoseProvider: TimelineProvider {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: CurrentBloodGlucoseProvider.self)
    )
    
    func placeholder(in context: Context) -> CurrentBloodGlucoseTimelineEntry {
        CurrentBloodGlucoseTimelineEntry(
            date: Date(),
            mgDl: 142,
            timestamp: Date().addingTimeInterval(-158),
            episode: nil,
            episodeTimestamp: nil
        )
    }
    
    
    @preconcurrency func getSnapshot(in context: Self.Context, completion: @escaping @Sendable (Self.Entry) -> Void) {
        completion(CurrentBloodGlucoseTimelineEntry.current())
    }
    
    @preconcurrency func getTimeline(in context: Self.Context, completion: @escaping @Sendable (Timeline<Self.Entry>) -> Void) {
        Self.logger.debug("CurrentBloodGlucoseProvider.getTimeline()")
        Task {
            let currentData: CurrentData?
            do {
                let openGlückConnection = await OpenGluckConnection()
                currentData = try await openGlückConnection.getCurrentData(becauseUpdateOf: "CurrentBloodGlucoseProvider.getTimeline")
                print("Got current: \(currentData!)")
            } catch {
                Self.logger.error("Could not get current glucose record from widget: \(error)")
                currentData = nil
            }
            let entries: [CurrentBloodGlucoseTimelineEntry] = [
                CurrentBloodGlucoseTimelineEntry.current(),
                CurrentBloodGlucoseTimelineEntry.noDataEntry(at: Date().addingTimeInterval(OpenGluckManager.freshDuration(hasRealTime: currentData?.hasCgmRealTimeData ?? false)))
            ]
            let timeline = Timeline(entries: entries, policy: .after(Date().addingTimeInterval(60)))
            completion(timeline)
        }
    }
}

struct CurrentBloodGlucoseTimelineEntry: TimelineEntry {
    let date: Date
    let mgDl: Int?
    let timestamp: Date?
    let episode: Episode?
    let episodeTimestamp: Date?
    
    enum State: String {
        case disconnected
        case mgDl
        case episode
    }
    
    var state: State {
        if let timestamp, let episodeTimestamp {
            if timestamp >= episodeTimestamp {
                return .mgDl
            } else {
                return .episode
            }
        } else if timestamp != nil {
            if mgDl != nil {
                return .mgDl
            } else {
                return .disconnected
            }
        } else if episodeTimestamp != nil {
            return .episode
        } else {
            return .disconnected
        }
    }
    
    static func current() -> CurrentBloodGlucoseTimelineEntry {
        let mgDl = WKDefaults.shared.currentMeasurementMgDl
        let timestamp = WKDefaults.shared.currentMeasurementTimestamp
        let episode = WKDefaults.shared.currentMeasurementEpisode
        let episodeTimestamp = WKDefaults.shared.currentMeasurementEpisodeTimestamp
        return CurrentBloodGlucoseTimelineEntry(
            date: Date(),
            mgDl: mgDl != 0 ? mgDl : nil,
            timestamp: timestamp,
            episode: episode,
            episodeTimestamp: episodeTimestamp
        )
    }
    
    static func noDataEntry(at date: Date) -> CurrentBloodGlucoseTimelineEntry {
        CurrentBloodGlucoseTimelineEntry(
            date: Date().addingTimeInterval(60 * 15),
            mgDl: nil,
            timestamp: nil,
            episode: nil,
            episodeTimestamp: nil
        )
    }
}

struct CurrentBloodGlucoseWidgetEntryView : View {
    var entry: CurrentBloodGlucoseProvider.Entry
    
    /*private var color: Color {
        if let mgDl = entry.mgDl {
            return FreestyleLibre.glucoseColor(mgDl: Double(mgDl))
        } else {
            return Color(red: 0x88 / 256, green: 0x88 / 256, blue: 0x88 / 256)
        }
    }
    
    private var colorText: Color {
        if let mgDl = entry.mgDl {
            return FreestyleLibre.glucoseTextColor(mgDl: Double(mgDl))
        } else {
            return Color(red: 0xff / 256, green: 0xff / 256, blue: 0xff / 256)
        }
    }*/
    
    @ViewBuilder
    var bodyDisconnected: some View {
        Image(systemName: "exclamationmark.icloud.fill")
            .font(.title)
        Text("No Data")
    }
    
    @ViewBuilder
    var bodyEpisode: some View {
        let episode = entry.episode!
        switch episode {
        case .disconnected:
            bodyDisconnected
        case .unknown:
            Text("UNKN")
                .font(.system(size: 34, weight: .bold))
        case .error:
            Text("ERR")
                .font(.system(size: 51, weight: .bold))
        case .low:
            Text("LOW")
                .font(.system(size: 43, weight: .bold))
        case .normal:
            Text("NORM")
                .font(.system(size: 32, weight: .bold))
        case .high:
            Text("HIGH")
                .font(.system(size: 39, weight: .bold))
        }
    }
        
    var body: some View {
        ZStack {
            //AccessoryWidgetBackground()
            VStack {
                switch entry.state {
                case .disconnected:
                    bodyDisconnected
                case .mgDl:
                    Text(BloodGlucose.localize(entry.mgDl!, style: .short))
                        .font(.system(size: 49, weight: .bold))
                case .episode:
                    bodyEpisode
                }
            }
        }
        .containerBackground(.background, for: .widget)
    }
}

struct CurrentBloodGlucoseWidget: Widget {
    let kind: String = "BloodGlucose"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CurrentBloodGlucoseProvider()) { entry in
            CurrentBloodGlucoseWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Blood Glucose")
        .description("Shows the current blood glucose.")
        .supportedFamilies([.accessoryRectangular])
    }
}

struct CurrentBloodGlucoseWidget_Previews: PreviewProvider {
    static let sampleEntry143 = CurrentBloodGlucoseTimelineEntry(date: Date(), mgDl: 143, timestamp: Date().addingTimeInterval(-158), episode: nil, episodeTimestamp: nil)
    static func sampleEntryEpisode(_ episode: Episode) -> CurrentBloodGlucoseTimelineEntry {
        CurrentBloodGlucoseTimelineEntry(date: Date(), mgDl: 143, timestamp: Date().addingTimeInterval(-158), episode: episode, episodeTimestamp: Date().addingTimeInterval(-140))

    }
    static let sampleEntryHigh = sampleEntryEpisode(.high)
    static let sampleEntryNormal = sampleEntryEpisode(.normal)
    static let sampleEntryLow = sampleEntryEpisode(.low)
    static let sampleEntryError = sampleEntryEpisode(.error)
    static let sampleEntryDisconnected = sampleEntryEpisode(.disconnected)
    static let sampleEntryUnknown = sampleEntryEpisode(.unknown)
    static let sampleNoData = CurrentBloodGlucoseTimelineEntry.noDataEntry(at: Date())
    
    static var previews: some View {
        CurrentBloodGlucoseWidgetEntryView(entry: sampleEntry143)
            .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
            .previewDisplayName("143")
        CurrentBloodGlucoseWidgetEntryView(entry: sampleEntryHigh)
            .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
            .previewDisplayName("high")
        CurrentBloodGlucoseWidgetEntryView(entry: sampleEntryNormal)
            .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
            .previewDisplayName("normal")
        CurrentBloodGlucoseWidgetEntryView(entry: sampleEntryLow)
            .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
            .previewDisplayName("low")
        CurrentBloodGlucoseWidgetEntryView(entry: sampleEntryError)
            .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
            .previewDisplayName("error")
        CurrentBloodGlucoseWidgetEntryView(entry: sampleEntryDisconnected)
            .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
            .previewDisplayName("disconnected")
        CurrentBloodGlucoseWidgetEntryView(entry: sampleEntryUnknown)
            .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
            .previewDisplayName("unknown")
        CurrentBloodGlucoseWidgetEntryView(entry: sampleNoData)
            .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
            .previewDisplayName("noData")
    }
}
