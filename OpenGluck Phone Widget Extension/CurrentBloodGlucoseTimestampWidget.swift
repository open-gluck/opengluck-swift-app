import WidgetKit
import SwiftUI
import os
import OGUI

struct CurrentBloodGlucoseTimestampProvider: TimelineProvider {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: CurrentBloodGlucoseTimestampProvider.self)
    )
    static let openGlückConnection = OpenGluckConnection()
    
    func placeholder(in context: Context) -> CurrentBloodGlucoseTimestampTimelineEntry {
        CurrentBloodGlucoseTimestampTimelineEntry(date: Date(), mgDl: 142, timestamp: Date().addingTimeInterval(-158))
    }
    
    
    func getSnapshot(in context: Context, completion: @escaping (CurrentBloodGlucoseTimestampTimelineEntry) -> ()) {
        completion(CurrentBloodGlucoseTimestampTimelineEntry.current())
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        Self.logger.debug("CurrentBloodGlucoseTimestampProvider.getTimeline()")
        Task {
            let entries: [CurrentBloodGlucoseTimestampTimelineEntry] = [
                CurrentBloodGlucoseTimestampTimelineEntry.current(),
            ]
            let timeline = Timeline(entries: entries, policy: .after(Date().addingTimeInterval(60)))
            completion(timeline)
        }
    }
}

struct CurrentBloodGlucoseTimestampTimelineEntry: TimelineEntry {
    let date: Date
    let mgDl: Int?
    let timestamp: Date?
    
    static func current() -> CurrentBloodGlucoseTimestampTimelineEntry {
        let mgDl = OpenGluckManager.userDefaults.integer(forKey: WKDataKeys.currentMeasurementMgDl.keyValue)
        let timestamp = OpenGluckManager.userDefaults.object(forKey: WKDataKeys.currentMeasurementTimestamp.keyValue) as? Date
        return CurrentBloodGlucoseTimestampTimelineEntry(date: Date(), mgDl: mgDl != 0 ? mgDl : nil, timestamp: timestamp)
    }
}

struct CurrentBloodGlucoseTimestampWidgetEntryView : View {
    var entry: CurrentBloodGlucoseTimestampProvider.Entry
    @Environment(\.widgetFamily) var widgetFamily

    private var color: Color {
        if let mgDl = entry.mgDl {
            return OGUI.glucoseColor(mgDl: Double(mgDl))
        } else {
            return Color(red: 0x88 / 256, green: 0x88 / 256, blue: 0x88 / 256)
        }
    }
    
    private var colorText: Color {
        if let mgDl = entry.mgDl {
            return OGUI.glucoseTextColor(mgDl: Double(mgDl))
        } else {
            return Color(red: 0xff / 256, green: 0xff / 256, blue: 0xff / 256)
        }
    }
    
    var body: some View {
        ZStack {
            let timeFormat: Date.FormatStyle.TimeStyle = widgetFamily == .accessoryCircular ? .shortened : .standard
            //AccessoryWidgetBackground()
            VStack {
                if let timestamp = entry.timestamp {
                    Text("Widget")
                        .font(.caption)
                    Text("\(entry.date.formatted(date: .omitted, time: timeFormat))")
                        .font(.headline)
                    Text(widgetFamily == .accessoryCircular ? "Meas." : "Measurement")
                        .font(.caption)
                    Text("\(timestamp.formatted(date: .omitted, time: timeFormat))")
                        .font(.headline)
                    
                } else {
                    Text("Widget")
                        .font(.caption)
                    Text("\(entry.date.formatted(date: .omitted, time: timeFormat))")
                        .font(.headline)
                    Text("Measurement")
                        .font(.caption)
                    HStack {
                        Image(systemName: "exclamationmark.icloud.fill")
                        Text("No Data")
                    }
                    .font(.headline)
                }
            }
            .scaleEffect(widgetFamily == .accessoryCircular ? 0.8 : 1.0)
        }
        .containerBackground(.background, for: .widget)
    }
}

struct CurrentBloodGlucoseTimestampWidget: Widget {
    let kind: String = "BloodGlucoseTimestamp"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CurrentBloodGlucoseTimestampProvider()) { entry in
            CurrentBloodGlucoseTimestampWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Blood Glucose Timestamp")
        .description("Shows the time of the last blood glucose measurement.")
        .supportedFamilies([.accessoryRectangular, .accessoryInline, .accessoryCircular])
    }
}

struct CurrentBloodGlucoseTimestampWidget_Previews: PreviewProvider {
    static var previews: some View {
        CurrentBloodGlucoseTimestampWidgetEntryView(entry: CurrentBloodGlucoseTimestampTimelineEntry(date: Date(), mgDl: 143, timestamp: Date().addingTimeInterval(-158)))
            .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
            .previewDisplayName(".accessoryRectangular")
        CurrentBloodGlucoseTimestampWidgetEntryView(entry: CurrentBloodGlucoseTimestampTimelineEntry(date: Date(), mgDl: 143, timestamp: Date().addingTimeInterval(-158)))
            .previewContext(WidgetPreviewContext(family: .accessoryCircular))
            .previewDisplayName(".accessoryCircular")
        CurrentBloodGlucoseTimestampWidgetEntryView(entry: CurrentBloodGlucoseTimestampTimelineEntry(date: Date(), mgDl: 143, timestamp: nil))
            .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
            .previewDisplayName("noData.accessoryRectangular")
    }
}
