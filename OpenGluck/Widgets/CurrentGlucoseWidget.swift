import WidgetKit
import Intents
import WatchConnectivity
import SwiftUI
import OG
import OGUI

fileprivate struct CurrentGlucoseWidgetData {
    enum Status {
        case error(error: Error)
        case ok(currentData: CurrentData)
    }
    let state: Status
}

fileprivate class CurrentGlucoseWidgetConfiguration: BaseWidgetConfiguration {
    enum WidgetError: Error {
        case noClientConfiguration
        case noData
    }
    static let kind = WidgetKinds.CurrentGlucoseWidget.rawValue
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
    static let configurationDisplayName = "Current Glucose"
    static let description = "Shows the current glucose."
    
    static func getRefreshTimelineAfter() -> Date {
        return Date().addingTimeInterval(60)
    }

    static func getDataStartingDate(_ data: CurrentGlucoseWidgetData) -> Date? {
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
    
    static func getPreviewData() -> CurrentGlucoseWidgetData {
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

        return CurrentGlucoseWidgetData(state: .ok(currentData: currentData))
    }
    
    static func getData(forTimelineDate timelineDate: Date, date: Date) async throws -> CurrentGlucoseWidgetData {
        let openGlückConnection = OpenGluckConnection()
        do {
            guard let client = openGlückConnection.getClient() else {
                await openGlückConnection.getClient()?.recordLog("getData(forTimelineDate:date:) got error WidgetError.noClientConfiguration")
                return CurrentGlucoseWidgetData(state: .error(error: WidgetError.noClientConfiguration))
            }
            guard let currentData = try await client.getCurrentData() else {
                await openGlückConnection.getClient()?.recordLog("getData(forTimelineDate:date:) got error WidgetError.noData")
                return CurrentGlucoseWidgetData(state: .error(error: WidgetError.noData))
            }
            return CurrentGlucoseWidgetData(state: .ok(currentData: currentData))
        } catch {
            await openGlückConnection.getClient()?.recordLog("getData(forTimelineDate:date:) got error \(error)")
            return CurrentGlucoseWidgetData(state: .error(error: error))
        }
    }
}

fileprivate typealias Entry = BaseWidgetProvider<CurrentGlucoseWidgetConfiguration, CurrentGlucoseWidget.WidgetView>.Entry

struct CurrentGlucoseWidget: Widget {
    fileprivate static let provider = BaseWidgetProvider<CurrentGlucoseWidgetConfiguration, WidgetView>(content: { entry in
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
        
        var currentShortText: String {
            currentText.replacingOccurrences(of: " mg/dL", with: "")
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
                    return BloodGlucose.localize(mgDl)
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
        
        @ViewBuilder
        func currentDataText() -> some View {
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
                        Text(BloodGlucose.localize(currentGlucose, style: .short))
                            .fontWeight(.bold)
                    } else {
                        Text("No Data")
                    }
                }
            }
        }
        
        @ViewBuilder
        func currentDataGauge(includeFreshnessLevel: Bool) -> some View {
            switch entry.entryType {
            case .placeholder:
                Gauge(value: 0, label: {
                    Text("")
                })
                .gaugeStyle(.accessoryCircularCapacity)
                .redacted(reason: .placeholder)
            case .expired:
                CurrentDataGauge(timestamp: .constant(nil), mgDl: .constant(nil), instantMgDl: .constant(nil), hasCgmRealTimeData: .constant(true), episode: .constant(.unknown), episodeTimestamp: .constant(entry.date), freshnessLevel: .constant(entry.freshnessLevel))
            case .normal:
                if currentError != nil {
                    CurrentDataGauge(timestamp: .constant(nil), mgDl: .constant(nil), instantMgDl: .constant(nil), hasCgmRealTimeData: .constant(true), episode: .constant(.error), episodeTimestamp: .constant(entry.date), freshnessLevel: .constant(entry.freshnessLevel))
                } else {
                    CurrentDataGauge(timestamp: .constant(currentTimestamp), mgDl: .constant(currentGlucose), instantMgDl: .constant(nil), hasCgmRealTimeData: .constant(hasCgmRealTimeData), episode: .constant(currentEpisode), episodeTimestamp: .constant(currentEpisodeTimestamp), freshnessLevel: .constant(includeFreshnessLevel ? entry.freshnessLevel : nil))
                }
            }
        }
        
        //        @ViewBuilder
        //        func currentDataView(includeFreshnessLevel: Bool) -> some View {
        //            let textPadding: Double = -1
        //            let imagePadding: Double = 5
        //            if redactionReasons.contains(.privacy) || redactionReasons.contains(.placeholder) {
        //                Circle()
        //                    .foregroundColor(.white.opacity(0.3))
        //            } else if currentError != nil {
        //                CurrentDataView(timestamp: .constant(nil), mgDl: .constant(nil), hasCgmRealTimeData: .constant(true), episode: .constant(.error), episodeTimestamp: .constant(entry.date), freshnessLevel: .constant(includeFreshnessLevel ? freshnessLevel : nil), textPadding: textPadding, imagePadding: imagePadding)
        //            } else {
        //                CurrentDataView(timestamp: .constant(currentTimestamp), mgDl: .constant(currentGlucose), hasCgmRealTimeData: .constant(hasCgmRealTimeData), episode: .constant(currentEpisode), episodeTimestamp: .constant(currentEpisodeTimestamp), freshnessLevel: .constant(includeFreshnessLevel ? freshnessLevel : nil), textPadding: textPadding, imagePadding: imagePadding)
        //            }
        //        }
        //
        var freshnessImage: UIImage {
            // we rotate the image to make it better
            let image = UIImage(systemName: freshnessImageName)!
            let radians: CGFloat = 0 //.pi / 2
            let size = CGSize(width: image.size.height/2, height: image.size.width/2)
            var newSize = CGRect(origin: CGPoint.zero, size: size).applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size
            // Trim off the extremely small float value to prevent core graphics from rounding it up
            newSize.width = floor(newSize.width)
            newSize.height = floor(newSize.height)
            
            UIGraphicsBeginImageContextWithOptions(newSize, false, image.scale)
            let context = UIGraphicsGetCurrentContext()!
            
            // Move origin to middle
            context.translateBy(x: newSize.width/2, y: newSize.height/2)
            // Rotate around middle
            context.rotate(by: CGFloat(radians))
            // Draw the image at its center
            image.draw(in: CGRect(x: -size.width/2, y: -size.height/2, width: size.width, height: size.height))
            
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return newImage!
        }
        
        var body: some View {
            Group {
                
#if os(watchOS)
                if widgetFamily == .accessoryCorner {
                    PrivacySensitiveWidgetGroup {
                        currentDataText()
//                        currentDataGauge(includeFreshnessLevel: false)
                    }
                    .widgetCurvesContent()
                    .widgetLabel {
                        if entry.entryType == .placeholder {
                            Text("XXX XXX XXX")
                                .redacted(reason: .placeholder)
                        } else if entry.entryType == .expired {
                            PrivacySensitiveWidgetGroup {
                                Text("Expired")
                            }
                        } else if entry.entryType == .normal {
                            PrivacySensitiveWidgetGroup {
                                Text("\(elapsedMinutes)m Ago")
                            }
                        }
                    }
                }
#endif
#if os(iOS)
                if widgetFamily == .systemExtraLarge {
                    Text("systemExtraLarge")
                } else if widgetFamily == .systemLarge {
                    Text("systemLarge")
                } else if widgetFamily == .systemMedium {
                    Text("systemMedium")
                } else if widgetFamily == .systemSmall {
                    let labelColor = Color(cgColor: UIColor.label.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark)).cgColor)
                    let bgColor = Color(cgColor: UIColor.systemBackground.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark)).cgColor)
                    
                    VStack {
                        Spacer()
                        PrivacySensitiveWidgetGroup {
                            currentDataGauge(includeFreshnessLevel: true)
#if os(watchOS)
                                .frame(width: 60, height: 60)
#endif
                        }
                        VStack {
                            if entry.entryType == .placeholder {
                                VStack {
                                    Text("xxxxxx")
                                        .font(.headline)
                                    Text("xxx xxx")
                                        .font(.subheadline)
                                }
                                .redacted(reason: .placeholder)
                            } else if entry.entryType == .expired {
                                VStack {
                                    Text("expired")
                                        .font(.headline)
                                    Text(">\(elapsedMinutes)m ago")
                                        .font(.subheadline)
                                }
                            } else if entry.entryType == .normal {
                                PrivacySensitiveWidgetGroup {
                                    VStack {
                                        if currentError != nil {
                                            Text(currentText)
                                                .font(.system(size: 10))
                                        } else {
                                            Text("\(currentEpisode?.rawValue ?? "unknown")")
                                                .font(.headline)
                                            Text("\(elapsedMinutes)m ago")
                                                .font(.subheadline)
                                        }
                                    }
                                }
                            }
                        }
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .background(bgColor)
                    .foregroundColor(labelColor)
                }
#endif
                if widgetFamily == .accessoryInline {
                    if entry.entryType == .expired {
                        Text("Expired")
                    } else if entry.entryType == .placeholder {
                        Text("XXX mg/dL, 42m Ago")
                            .redacted(reason: .placeholder)
                    } else if entry.entryType == .normal {
                        PrivacySensitiveWidgetGroup {
                            HStack {
                                //Image(uiImage: freshnessImage)
                                Text("\(currentText) @ \(elapsedMinutes)m ago")
                            }
                        }
                    }
                } else if widgetFamily == .accessoryCircular {
                    PrivacySensitiveWidgetGroup {
                        //currentDataView(includeFreshnessLevel: true)
                        currentDataGauge(includeFreshnessLevel: true)
                    }
                } else if widgetFamily == .accessoryRectangular {
#if os(iOS)
                    if entry.entryType == .placeholder {
                        GeometryReader { geom in
                            ZStack {
                                VStack(alignment: .center, spacing: 0) {
                                    Spacer()
                                    Text("333")
                                        .font(.system(size: 35, weight: .bold))
                                        .padding(0)
                                    Spacer()
                                }
                                .padding(.bottom, 5)
                                .frame(height: geom.size.height)
                                VStack {
                                    Spacer()
                                    ProgressView(value: entry.freshnessLevel)
                                }
                                .frame(height: geom.size.height)
                            }
                        }
                        .redacted(reason: .placeholder)
                    } else if entry.entryType == .expired {
                        GeometryReader { geom in
                            ZStack {
                                VStack(alignment: .center, spacing: 0) {
                                    Spacer()
                                    Text("EXPIRED")
                                        .font(.system(size: 35, weight: .bold))
                                        .padding(0)
                                    Spacer()
                                }
                                .padding(.bottom, 5)
                                .frame(height: geom.size.height)
                                VStack {
                                    Spacer()
                                    ProgressView(value: entry.freshnessLevel)
                                }
                                .frame(height: geom.size.height)
                            }
                        }
                    } else if entry.entryType == .normal {
                        PrivacySensitiveWidgetGroup {
                            GeometryReader { geom in
                                ZStack {
                                    VStack(alignment: .center, spacing: 0) {
                                        Spacer()
                                        if currentError != nil {
                                            Text(currentText)
                                                .font(.system(size: 100))
                                        } else {
                                            Text(currentShortText)
                                                .font(.system(size: 65, weight: .bold))
                                                .padding(0)
                                        }
                                        Spacer()
                                    }
                                    .padding(.bottom, 5)
                                    .frame(height: geom.size.height)
                                    VStack {
                                        Spacer()
                                        ProgressView(value: entry.freshnessLevel)
                                    }
                                    .frame(height: geom.size.height)
                                }
                            }
                        }
                    }
#endif
#if os(watchOS)
                    HStack(spacing: 12) {
                        VStack {
                            Spacer()
                            PrivacySensitiveWidgetGroup {
                                currentDataGauge(includeFreshnessLevel: true)
                                    .frame(width: 60, height: 60)
                            }
                            Spacer()
                        }
                        VStack(alignment: .leading) {
                            if entry.entryType == .placeholder {
                                VStack(alignment: .leading) {
                                    Text("xxxxxx")
                                        .font(.headline)
                                    Text("xxx xxx")
                                        .font(.subheadline)
                                }
                                .redacted(reason: .placeholder)
                            } else if entry.entryType == .expired {
                                VStack(alignment: .leading) {
                                    Text("expired")
                                        .font(.headline)
                                    Text("\(elapsedMinutes)m ago")
                                        .font(.subheadline)
                                }
                            } else if entry.entryType == .normal {
                                PrivacySensitiveWidgetGroup {
                                    VStack(alignment: .leading) {
                                        if currentError != nil {
                                            Text(currentText)
                                                .font(.system(size: 10))
                                        } else {
                                            Text("\(currentEpisode?.rawValue ?? "unknown")")
                                                .font(.headline)
                                            Text("\(elapsedMinutes)m ago")
                                                .font(.subheadline)
                                        }
                                    }
                                }
                            }
                        }
                    }
#endif
                }
            }
            .containerBackground(.background, for: .widget)
        }
    }
    
    var body: some WidgetConfiguration {
        Self.provider.body
            .contentMarginsDisabled()
    }
}

#Preview("Placeholder", as: .accessoryRectangular) {
    CurrentGlucoseWidget()
} timeline: {
    Entry.placeholder()
}
#Preview("Expired", as: .accessoryRectangular) {
    CurrentGlucoseWidget()
} timeline: {
    Entry.expired()
}
#Preview("accessoryRectangular", as: .accessoryRectangular) {
    CurrentGlucoseWidget()
} timeline: {
    Entry.preview
}
#Preview("accessoryCircular", as: .accessoryCircular) {
    CurrentGlucoseWidget()
} timeline: {
    Entry.preview
}

#if os(watchOS)
#Preview("accessoryCorner", as: .accessoryCorner) {
    CurrentGlucoseWidget()
} timeline: {
    Entry.preview
}
#endif
