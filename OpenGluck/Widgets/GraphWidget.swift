import WidgetKit
import Intents
import WatchConnectivity
import SwiftUI
import OG
import OGUI

fileprivate struct GraphWidgetData {
    enum Status {
        case error(error: Error)
        case ok(lastData: LastData)
    }
    let state: Status
}

fileprivate class GraphWidgetConfiguration: BaseWidgetConfiguration {
    enum WidgetError: Error {
        case noClientConfiguration
        case noData
    }
    static let kind = WidgetKinds.GraphWidget.rawValue
#if os(watchOS)
    static let supportedWidgetFamilies: [WidgetFamily] = [
        .accessoryRectangular
    ]
#endif
#if os(iOS)
    static let supportedWidgetFamilies: [WidgetFamily] = [
        .systemExtraLarge,
        .systemLarge,
        .systemMedium,
        .systemSmall
    ]
#endif
    static let maximumValidityInterval: TimeInterval? = 10 * 60
    static let useSameDataForAllEntries = true
    static let refreshInterval: TimeInterval = 60
    static let numberOfEntries = 10
    static let configurationDisplayName = "Graph"
    static let description = "Shows the graph."
    
    static func getRefreshTimelineAfter() -> Date {
        return Date().addingTimeInterval(60)
    }

    static func getDataStartingDate(_ data: GraphWidgetData) -> Date? {
        return nil
    }
    
    static func getPreviewData() -> GraphWidgetData {
        let lastData: LastData = {
            let currentDataJson = "{\"revision\":40268,\"glucose-records\":[{\"timestamp\":\"2023-06-21T23:18:06.006000+02:00\",\"mgDl\":124,\"record_type\":\"scan\"},{\"timestamp\":\"2023-06-21T23:13:06.485000+02:00\",\"mgDl\":125,\"record_type\":\"scan\"},{\"timestamp\":\"2023-06-21T23:08:06.177000+02:00\",\"mgDl\":133,\"record_type\":\"scan\"},{\"timestamp\":\"2023-06-21T23:03:05.161000+02:00\",\"mgDl\":130,\"record_type\":\"scan\"},{\"timestamp\":\"2023-06-21T22:58:06.389000+02:00\",\"mgDl\":133,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T22:53:04.922000+02:00\",\"mgDl\":135,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T22:48:05.416000+02:00\",\"mgDl\":140,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T22:43:05.500000+02:00\",\"mgDl\":141,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T22:38:05.583000+02:00\",\"mgDl\":139,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T22:33:05.671000+02:00\",\"mgDl\":136,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T22:28:04.982000+02:00\",\"mgDl\":142,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T22:23:05.850000+02:00\",\"mgDl\":145,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T22:18:05.561000+02:00\",\"mgDl\":144,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T22:13:05.641000+02:00\",\"mgDl\":154,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T22:08:06.517000+02:00\",\"mgDl\":168,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T22:03:05.004000+02:00\",\"mgDl\":180,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T21:58:04.704000+02:00\",\"mgDl\":190,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T21:53:06.266000+02:00\",\"mgDl\":197,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T21:48:18.141000+02:00\",\"mgDl\":206,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T21:43:06.147000+02:00\",\"mgDl\":208,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T21:38:24.567000+02:00\",\"mgDl\":213,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T21:33:05.176000+02:00\",\"mgDl\":216,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T21:28:07.215000+02:00\",\"mgDl\":207,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T21:23:05.360000+02:00\",\"mgDl\":212,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T21:18:05.447000+02:00\",\"mgDl\":214,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T21:13:05.952000+02:00\",\"mgDl\":214,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T21:08:04.851000+02:00\",\"mgDl\":209,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T21:03:06.099000+02:00\",\"mgDl\":200,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T20:58:05.818000+02:00\",\"mgDl\":191,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T20:53:06.863000+02:00\",\"mgDl\":175,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T20:48:05.569000+02:00\",\"mgDl\":163,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T20:43:13.128000+02:00\",\"mgDl\":154,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T20:38:17.055000+02:00\",\"mgDl\":147,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T20:33:05.772000+02:00\",\"mgDl\":142,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T20:28:15.683000+02:00\",\"mgDl\":136,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T20:23:06.019000+02:00\",\"mgDl\":133,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T20:18:06.126000+02:00\",\"mgDl\":131,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T20:13:05.443000+02:00\",\"mgDl\":128,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T20:08:06.309000+02:00\",\"mgDl\":125,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T20:03:06.007000+02:00\",\"mgDl\":123,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T19:58:05.706000+02:00\",\"mgDl\":122,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T19:53:05.807000+02:00\",\"mgDl\":124,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T19:48:05.497000+02:00\",\"mgDl\":124,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T19:43:05.996000+02:00\",\"mgDl\":123,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T19:38:06.722000+02:00\",\"mgDl\":123,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T19:33:23.368000+02:00\",\"mgDl\":123,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T19:28:18.325000+02:00\",\"mgDl\":125,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T19:23:05.941000+02:00\",\"mgDl\":124,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T19:18:30.326000+02:00\",\"mgDl\":124,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T19:13:22.201000+02:00\",\"mgDl\":125,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T19:08:21.520000+02:00\",\"mgDl\":128,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T19:03:21.520000+02:00\",\"mgDl\":127,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T18:58:05.334000+02:00\",\"mgDl\":126,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T18:53:06.482000+02:00\",\"mgDl\":123,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T18:48:06.572000+02:00\",\"mgDl\":122,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T18:43:05.897000+02:00\",\"mgDl\":127,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T18:38:08.216000+02:00\",\"mgDl\":126,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T18:33:05.682000+02:00\",\"mgDl\":126,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T18:28:06.150000+02:00\",\"mgDl\":128,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T18:23:06.924000+02:00\",\"mgDl\":129,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T18:18:05.956000+02:00\",\"mgDl\":131,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T18:13:05.263000+02:00\",\"mgDl\":132,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T18:08:05.743000+02:00\",\"mgDl\":135,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T18:03:06.209000+02:00\",\"mgDl\":136,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T17:58:05.132000+02:00\",\"mgDl\":138,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T17:53:05.224000+02:00\",\"mgDl\":141,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T17:48:06.877000+02:00\",\"mgDl\":142,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T17:43:05.301000+02:00\",\"mgDl\":144,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T17:38:06.672000+02:00\",\"mgDl\":147,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T17:33:06.373000+02:00\",\"mgDl\":149,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T17:28:16.212000+02:00\",\"mgDl\":152,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T17:23:06.561000+02:00\",\"mgDl\":155,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T17:18:05.374000+02:00\",\"mgDl\":159,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T17:13:05.964000+02:00\",\"mgDl\":161,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T17:08:07.105000+02:00\",\"mgDl\":163,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T17:03:05.389000+02:00\",\"mgDl\":166,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T16:58:16.611000+02:00\",\"mgDl\":169,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T16:53:09.068000+02:00\",\"mgDl\":171,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T16:48:31.626000+02:00\",\"mgDl\":175,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T16:43:31.626000+02:00\",\"mgDl\":179,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T16:38:31.626000+02:00\",\"mgDl\":181,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T16:33:31.626000+02:00\",\"mgDl\":182,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T16:28:31.626000+02:00\",\"mgDl\":183,\"record_type\":\"historic\"},{\"timestamp\":\"2023-06-21T16:23:31.626000+02:00\",\"mgDl\":183,\"record_type\":\"historic\"}],\"low-records\":[{\"id\":\"AA52879A-80DC-47BF-8308-6945F0564B58\",\"timestamp\":\"2023-06-21T23:16:14+02:00\",\"sugar_in_grams\":10,\"deleted\":false}],\"insulin-records\":[{\"id\":\"1F9E7A5C-BC5C-48F2-8846-FA78E267B5A9\",\"timestamp\":\"2023-06-21T21:54:35+02:00\",\"units\":1,\"deleted\":false},{\"id\":\"A67C4D41-BDC3-4230-84BC-3D672D941E6E\",\"timestamp\":\"2023-06-21T20:58:10+02:00\",\"units\":1,\"deleted\":false},{\"id\":\"ECD6B010-92AF-46F5-AE33-E173029DB382\",\"timestamp\":\"2023-06-21T20:33:25+02:00\",\"units\":2,\"deleted\":false},{\"id\":\"348A9852-F3EF-453E-B381-65ED606E5023\",\"timestamp\":\"2023-06-21T20:26:54+02:00\",\"units\":3,\"deleted\":false}]}"
            let jsonNow = Date(timeIntervalSince1970: 1687382286.006)
            let now = Date()
            let jsonDecoder = JSONDecoder()
            jsonDecoder.dateDecodingStrategy = .custom { decoder -> Date in
                let isoDateFormatter = ISO8601DateFormatter()
                let container = try decoder.singleValueContainer()
                let dateStr = try container.decode(String.self).replacingOccurrences(of: "\\.\\d+", with: "", options: .regularExpression)
                let date: Date = isoDateFormatter.date(from: dateStr)!
                let interval = date.timeIntervalSince(jsonNow)
                return now.addingTimeInterval(interval)
            }
            return try! jsonDecoder.decode(LastData.self, from: currentDataJson.data(using: .utf8)!)
        }()

        return GraphWidgetData(state: .ok(lastData: lastData))
    }
    
    static func getData(forTimelineDate timelineDate: Date, date: Date) async throws -> GraphWidgetData {
        do {
            let openGlückConnection = await OpenGluckConnection()
            guard let client = openGlückConnection.getClient() else {
                return GraphWidgetData(state: .error(error: WidgetError.noClientConfiguration))
            }
            guard let lastData = try await client.getLastData() else {
                return GraphWidgetData(state: .error(error: WidgetError.noData))
            }
            return GraphWidgetData(state: .ok(lastData: lastData))
        } catch {
            return GraphWidgetData(state: .error(error: error))
        }
    }
}

fileprivate typealias Entry = BaseWidgetProvider<GraphWidgetConfiguration, GraphWidget.WidgetView>.Entry

struct GraphWidget: Widget {
    fileprivate static let provider = BaseWidgetProvider<GraphWidgetConfiguration, WidgetView>(content: { entry in
        WidgetView(entry: entry)
    })
    
    struct WidgetView: View {
        @Environment(\.widgetFamily) var widgetFamily
        @Environment(\.redactionReasons) var redactionReasons
        
        fileprivate let entry: Entry
        
        var elapsed: TimeInterval {
            entry.elapsed
        }
        
        var elapsedMinutes: Int {
            Int(round(elapsed / 60))
        }
        
       var currentError: Error? {
            guard let data = entry.data else {
                return nil
            }
            switch data.state {
            case .error(error: let error): return error
            case .ok(lastData: _): return nil
            }
        }
        
        var lastData: LastData? {
            guard let data = entry.data else {
                return nil
            }
            switch data.state {
            case .error(error: _): return nil
            case .ok(lastData: let lastData): return lastData
            }
        }
        
#if os(iOS)
        let bgColor = Color(cgColor: UIColor.systemBackground.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark)).cgColor)
#else
        @Environment(\.widgetRenderingMode) var widgetRenderingMode
        var bgColor: Color { widgetRenderingMode == .fullColor ? Color.black : .white.opacity(0) }
#endif

        var body: some View {
            Group {
                if entry.entryType == .placeholder {
                    Text("XXXXXX")
                        .redacted(reason: .placeholder)
                } else if entry.entryType == .expired {
                    VStack {
                        CurrentDataGauge(timestamp: .constant(nil), mgDl: .constant(nil), instantMgDl: .constant(nil), hasCgmRealTimeData: .constant(true), episode: .constant(.unknown), episodeTimestamp: .constant(entry.date), freshnessLevel: .constant(entry.freshnessLevel))
                        HStack {
                            Text("Expired")
                                .font(.headline)
                            Text(">\(elapsedMinutes)m ago")
                                .font(.subheadline)
                        }
                    }
                } else if entry.entryType == .normal {
                    if let currentError {
                        CurrentDataGauge(timestamp: .constant(nil), mgDl: .constant(nil), instantMgDl: .constant(nil), hasCgmRealTimeData: .constant(true), episode: .constant(.unknown), episodeTimestamp: .constant(entry.date), freshnessLevel: .constant(entry.freshnessLevel))
                        HStack {
                            Text("Error")
                                .font(.headline)
                            Text("\(currentError.localizedDescription)")
                                .font(.subheadline)
                        }
                    } else if let lastData {
#if os(watchOS)
                        let style: GlucoseGraph.Style = .small
#else
                        let style: GlucoseGraph.Style = .normal
#endif
                        
                        PrivacySensitiveWidgetGroup {
                            GlucoseGraphImpl(
                                now: entry.date,
                                glucoseRecords: lastData.glucoseRecords ?? [],
                                insulinRecords: (lastData.insulinRecords ?? []).filter { !$0.deleted },
                                lowRecords: lastData.lowRecords ?? [],
                                style: style,
                                colorScheme: .dark,
                                showBackground: true
                            )
                        }
                    } else {
                        fatalError("No error and no data")
                    }
                }
            }
            .containerBackground(.placeholder, for: .widget)
        }
    }
    
    var body: some WidgetConfiguration {
        Self.provider.body
            .contentMarginsDisabled()
    }
}

#if os(iOS)
#Preview("Placeholder", as: .systemLarge) {
    GraphWidget()
} timeline: {
    Entry.placeholder()
}
#Preview("Expired", as: .systemLarge) {
    GraphWidget()
} timeline: {
    Entry.expired()
}
#Preview("systemSmall", as: .systemSmall) {
    GraphWidget()
} timeline: {
    Entry.preview
}
#Preview("systemLarge", as: .systemLarge) {
    GraphWidget()
} timeline: {
    Entry.preview
}
#Preview("systemExtraLarge", as: .systemExtraLarge) {
    GraphWidget()
} timeline: {
    Entry.preview
}
#endif

#if os(watchOS)
#Preview("⌚️Placeholder", as: .accessoryRectangular) {
    GraphWidget()
} timeline: {
    Entry.placeholder()
}
#Preview("⌚️Expired", as: .accessoryRectangular) {
    GraphWidget()
} timeline: {
    Entry.expired()
}
#Preview("⌚️systemLarge", as: .accessoryRectangular) {
    GraphWidget()
} timeline: {
    Entry.preview
}
#endif
