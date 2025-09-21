import WidgetKit
import Intents
import WatchConnectivity
import SwiftUI
import OG
import OGUI

fileprivate struct CurrentGlucoseLargeWidgetData {
    enum Status {
        case error(error: Error)
        case ok(currentData: CurrentData)
    }
    let state: Status
}

fileprivate final class CurrentGlucoseLargeWidgetConfiguration: BaseWidgetConfiguration {
    enum WidgetError: Error {
        case noClientConfiguration
        case noData
    }
    static let kind = WidgetKinds.CurrentGlucoseLargeWidget.rawValue
#if os(watchOS)
    static let supportedWidgetFamilies: [WidgetFamily] = [
        .accessoryCorner,
        .accessoryInline,
        .accessoryCircular,
        .accessoryRectangular
    ]
#endif
#if os(iOS)
    static let supportedWidgetFamilies: [WidgetFamily] = [
        .accessoryInline,
        .accessoryCircular,
        .accessoryRectangular,
//        .systemExtraLarge,
//        .systemLarge,
//        .systemMedium,
        .systemSmall
    ]
#endif
    static let maximumValidityInterval: TimeInterval? = 10 * 60
    static let useSameDataForAllEntries = true
    static let refreshInterval: TimeInterval = 60
    static let numberOfEntries = 10
    static let configurationDisplayName = "Large Current Glucose"
    static let description = "Shows the current glucose, in large."
    
    static func getRefreshTimelineAfter() -> Date {
        return Date().addingTimeInterval(60)
    }

    static func getDataStartingDate(_ data: CurrentGlucoseLargeWidgetData) -> Date? {
        switch data.state {
        case .error(error: _): return nil
        case .ok(currentData: let currentData):
            let glucoseTimestamp = currentData.currentGlucoseRecord?.timestamp
            let episodeTimestamp = currentData.currentEpisodeTimestamp
            if let glucoseTimestamp {
                return max(glucoseTimestamp, episodeTimestamp)
            } else {
                return episodeTimestamp
            }
        }
    }
    
    static func getPreviewData() -> CurrentGlucoseLargeWidgetData {
        let currentData: CurrentData = {
            let timestamp4mAgo = Date().addingTimeInterval(-4 * 60)
            let timestamp16mAgo = Date().addingTimeInterval(-16 * 60)
            let currentDataJson = """
{
"current_glucose_record": {
  "timestamp": "\(timestamp4mAgo.ISO8601Format())",
  "mgDl": 139,
  "record_type": "scan"
},
"last_historic_glucose_record": {
  "timestamp": "\(timestamp16mAgo.ISO8601Format())",
  "mgDl": 175,
  "record_type": "historic"
},
"current_episode": "normal",
"current_episode_timestamp": "\(timestamp4mAgo.ISO8601Format())",
"has_cgm_real_time_data": true,
"revision": 31877
}
"""
            let jsonDecoder = JSONDecoder()
            jsonDecoder.dateDecodingStrategy = .custom { decoder -> Date in
                let isoDateFormatter = ISO8601DateFormatter()
                let container = try decoder.singleValueContainer()
                let dateStr = try container.decode(String.self).replacingOccurrences(of: "\\.\\d+", with: "", options: .regularExpression)
                let date = isoDateFormatter.date(from: dateStr)
                return date!
            }
            return try! jsonDecoder.decode(CurrentData.self, from: currentDataJson.data(using: .utf8)!)
        }()

        return CurrentGlucoseLargeWidgetData(state: .ok(currentData: currentData))
    }
    
    static func getData(forTimelineDate timelineDate: Date, date: Date) async throws -> CurrentGlucoseLargeWidgetData {
        do {
            let openGlückConnection = await OpenGluckConnection()
            guard let client = openGlückConnection.getClient() else {
                return CurrentGlucoseLargeWidgetData(state: .error(error: WidgetError.noClientConfiguration))
            }
            guard let currentData = try await client.getCurrentData() else {
                return CurrentGlucoseLargeWidgetData(state: .error(error: WidgetError.noData))

            }
            return CurrentGlucoseLargeWidgetData(state: .ok(currentData: currentData))
        } catch {
            return CurrentGlucoseLargeWidgetData(state: .error(error: error))
        }
    }
}

fileprivate typealias Entry = BaseWidgetProvider<CurrentGlucoseLargeWidgetConfiguration, CurrentGlucoseLargeWidget.WidgetView>.Entry

struct CurrentGlucoseLargeWidget: Widget {
    fileprivate static let provider = BaseWidgetProvider<CurrentGlucoseLargeWidgetConfiguration, WidgetView>(content: { entry in
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
        
        var freshnessImageName: String {
            if currentGlucose == nil {
                return "icloud.slash"
            }
            if elapsedMinutes < 3 {
                return "circle.fill"
            } else if elapsedMinutes < 6 {
                return "circle.bottomhalf.filled"
            } else {
                return "circle"
            }
        }
        
        var currentText: String {
            switch entry.entryType {
            case .placeholder:
                return "XXX mg/dL"
            case .expired:
                return "Expired"
            case .normal:
                guard currentError == nil else {
                    return "Error: \(currentError!.localizedDescription)"
                }
                let mgDl: Int?
                let episode: Episode?
                
                if let currentTimestamp, let currentEpisodeTimestamp {
                    if currentTimestamp >= currentEpisodeTimestamp {
                        mgDl = currentGlucose
                        episode = nil
                    } else {
                        mgDl = nil
                        episode = currentEpisode
                    }
                } else if currentTimestamp != nil {
                    if let currentGlucose {
                        mgDl = currentGlucose
                        episode = nil
                    } else {
                        mgDl = nil
                        episode = .disconnected
                    }
                } else if let currentEpisode {
                    mgDl = nil
                    episode = currentEpisode
                } else {
                    mgDl = nil
                    episode = .disconnected
                }
                
                if let mgDl {
                    return "\(mgDl) mg/dL"
                } else if let episode {
                    switch episode {
                    case .disconnected:
                        return "Disconnected"
                    case .error:
                        return "Error"
                    case .high:
                        return "High"
                    case .low:
                        return "Low"
                    case .normal:
                        return "Normal"
                    case .unknown:
                        return "Unknown"
                    }
                } else {
                    fatalError("Expected to have a blood glucose or an episode")
                }
            }
        }
        
        var currentError: Error? {
            guard let data = entry.data else {
                return nil
            }
            switch data.state {
            case .error(error: let error): return error
            case .ok(currentData: _): return nil
            }
        }
        
        var currentData: CurrentData? {
            guard let data = entry.data else {
                return nil
            }
            switch data.state {
            case .error(error: _): return nil
            case .ok(currentData: let currentData): return currentData
            }
        }
        
        var currentGlucose: Int? {
            currentData?.currentGlucoseRecord?.mgDl
        }
        
        var currentTimestamp: Date? {
            currentData?.currentGlucoseRecord?.timestamp
        }
        
        var hasCgmRealTimeData: Bool? {
            currentData?.hasCgmRealTimeData
        }
        
        var currentEpisode: Episode? {
            currentData?.currentEpisode
        }
        
        var currentEpisodeTimestamp: Date? {
            currentData?.currentEpisodeTimestamp
        }
        
        var currentGlucoseColor: Color {
            if let currentGlucose {
                return OGUI.glucoseColor(mgDl: Double(currentGlucose))
            } else {
                return .white
            }
        }
                
        var body: some View {
            Group {
                switch entry.entryType {
                case .placeholder:
                    Text("XXX")
                        .redacted(reason: .placeholder)
                case .expired:
                    Text("Expired")
                        .font(.headline)
                case .normal:
                    if currentError != nil {
                        Text("Error")
                            .font(.headline)
                    } else if let currentGlucose {
                        Text("\(currentGlucose)")
                            .fontWeight(.bold)
                    } else {
                        Text("No Data")
                    }
                }
            }
            .font(.system(size: 999))
            .minimumScaleFactor(0.01)
            .containerBackground(.background, for: .widget)
        }
    }
    
    var body: some WidgetConfiguration {
        Self.provider.body
    }
}

#Preview("Placeholder", as: .accessoryRectangular) {
    CurrentGlucoseLargeWidget()
} timeline: {
    Entry.placeholder()
}
#Preview("Expired", as: .accessoryRectangular) {
    CurrentGlucoseLargeWidget()
} timeline: {
    Entry.expired()
}
#Preview("accessoryRectangular", as: .accessoryRectangular) {
    CurrentGlucoseLargeWidget()
} timeline: {
    Entry.preview
}
