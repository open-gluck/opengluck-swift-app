import WidgetKit
import Intents
import WatchConnectivity
import SwiftUI
import OG

// you can use this file as a starting point for widgets that support placeholders, sensitive info,
// and that refreshes every N seconds

fileprivate struct TimelineDebugWidgetData {
    let alice: String
}

fileprivate class TimelineDebugWidgetConfiguration: BaseWidgetConfiguration {
    static let kind = WidgetKinds.TimelineDebugWidget.rawValue
    static let supportedWidgetFamilies: [WidgetFamily] = [ .accessoryCorner, .accessoryInline, .accessoryCircular, .accessoryRectangular ]
    static let maximumValidityInterval: TimeInterval? = 10
    static let useSameDataForAllEntries = false
    static let refreshInterval: TimeInterval = 1
    static let numberOfEntries = 100
    static let configurationDisplayName = "Timeline Debug"
    static let description = "Timeline Debug Widget."
    
    static func getRefreshTimelineAfter() -> Date {
        return Date().addingTimeInterval(5)
    }

    static func getDataStartingDate(_ data: TimelineDebugWidgetData) -> Date? {
        nil
    }
    
    static func getPreviewData() -> TimelineDebugWidgetData {
        TimelineDebugWidgetData(alice: "Bob")
    }
    
    static func getData(forTimelineDate timelineDate: Date, date: Date) async throws -> TimelineDebugWidgetData {
        TimelineDebugWidgetData(alice: "Charlie")
    }
}

fileprivate typealias Entry = BaseWidgetProvider<TimelineDebugWidgetConfiguration, TimelineDebugWidget.WidgetView>.Entry

struct TimelineDebugWidget: Widget {
    fileprivate static let provider = BaseWidgetProvider<TimelineDebugWidgetConfiguration, WidgetView>(content: { entry in
        WidgetView(entry: entry)
    })
    
    struct WidgetView: View {
        @Environment(\.widgetFamily) var widgetFamily
        
        fileprivate let entry: Entry
        
        var body: some View {
            let elapsed = entry.elapsed
            let expired = entry.expired
            let progress: Double = TimelineDebugWidgetConfiguration.maximumValidityInterval != nil ? Double(elapsed) / Double(TimelineDebugWidgetConfiguration.maximumValidityInterval!) : 0.0
            
            Group {
                if widgetFamily == .accessoryCorner {
                    // broken, mostly, see https://stackoverflow.com/questions/74339034/how-can-one-write-a-watchos-widget-for-accessorycorner-family-that-renders-appro
                    Image(systemName: "square.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.green)
                        .widgetLabel(label: {
                            Gauge(value: progress) {
                                Text("")
                            } currentValueLabel: {
                                Text("")
                            } minimumValueLabel: {
                                Text("0")
                                    .foregroundColor(.blue)
                            } maximumValueLabel: {
                                Text(
                                    TimelineDebugWidgetConfiguration.maximumValidityInterval == nil ?
                                    "+∞" :
                                        "\(Int(TimelineDebugWidgetConfiguration.maximumValidityInterval ?? 99999))s"
                                )
                                .foregroundColor(.pink)
                            }
                            .tint(Gradient(colors: [.blue, .green, .pink]))
                            
                        })
                } else if widgetFamily == .accessoryInline {
                    let text: String = {
                        guard !expired else {
                            return "Expired"
                        }
                        let elapsed = Int(round(elapsed))
                        if let maximumValidityInterval = TimelineDebugWidgetConfiguration.maximumValidityInterval {
                            return "∆=\(elapsed)s, max=\(Int(round(maximumValidityInterval)))s"
                        } else {
                            return "∆=\(elapsed)s, no limit"
                        }
                    }()
                    Text(text)
                } else if widgetFamily == .accessoryCircular {
                    // https://useyourloaf.com/blog/swiftui-gauges/
                    PrivacySensitiveWidgetGroup {
                        Gauge(value: progress) {
                            Text("M")
                        } currentValueLabel: {
                            Text("\(Int(round(elapsed)))")
                        } minimumValueLabel: {
                            Text("0")
                                .foregroundColor(.blue)
                        } maximumValueLabel: {
                            Text(TimelineDebugWidgetConfiguration.maximumValidityInterval == nil ? "" : "\(Int(round(TimelineDebugWidgetConfiguration.maximumValidityInterval!)))")
                                .foregroundColor(.pink)
                        }
                        .gaugeStyle(.accessoryCircular)
                        .tint(Gradient(colors: [.blue, .green, .pink]))
                    }
                } else if widgetFamily == .accessoryRectangular || true {
                    VStack {
                        Text("Here Some Label Text")
                        PrivacySensitiveWidgetGroup {
                            if entry.entryType == .expired {
                                Text("Expired")
                            } else if entry.entryType == .placeholder {
                                Text("Elapsed: XXs")
                                    .redacted(reason: .placeholder)
                            } else if entry.entryType == .normal {
                                Text(expired ? "Expired" : "Elapsed: \(Int(round(elapsed)))s")
                            }
                        }
                    }
                    .font(.system(size: 12))
                }
            }
            .containerBackground(.background, for: .widget)
        }
    }
    
    var body: some WidgetConfiguration {
        Self.provider.body
    }
}

struct TimelineDebugWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TimelineDebugWidget.WidgetView(entry: Entry.placeholder())
                .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
                .previewDisplayName("Placeholder")
            TimelineDebugWidget.WidgetView(entry: Entry.expired())
                .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
                .previewDisplayName("Expired")
            ForEach(TimelineDebugWidget.provider.configuration.supportedWidgetFamilies, id: \.self) { supportedWidgetFamily in
                TimelineDebugWidget.WidgetView(entry: Entry.preview)
                    .previewContext(WidgetPreviewContext(family: supportedWidgetFamily))
                    .previewDisplayName(String(describing: supportedWidgetFamily))
            }
        }
        .environment(\.isWidgetInPreview, true)
    }
}
