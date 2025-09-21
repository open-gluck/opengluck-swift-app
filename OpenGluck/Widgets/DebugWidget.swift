import WidgetKit
import Intents
import WatchConnectivity
import SwiftUI
import OG

fileprivate struct DebugWidgetData {
    let url: String?
}

fileprivate final class DebugWidgetConfiguration: BaseWidgetConfiguration {
    static let kind = WidgetKinds.DebugWidget.rawValue
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
    static let configurationDisplayName = "Debug"
    static let description = "Shows debug data."
    
    static func getRefreshTimelineAfter() -> Date {
        return Date().addingTimeInterval(60)
    }

    static func getDataStartingDate(_ data: DebugWidgetData) -> Date? {
        return nil
    }
    
    static func getPreviewData() -> DebugWidgetData {
        return DebugWidgetData(url: OpenGluckManager.openglückUrl)
    }
    
    static func getData(forTimelineDate timelineDate: Date, date: Date) async throws -> DebugWidgetData {
        return DebugWidgetData(url: OpenGluckManager.openglückUrl)
    }
}


fileprivate typealias Entry = BaseWidgetProvider<DebugWidgetConfiguration, DebugWidget.WidgetView>.Entry

struct DebugWidget: Widget {
    fileprivate static let provider = BaseWidgetProvider<DebugWidgetConfiguration, WidgetView>(content: { entry in
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
        
//#if os(iOS)
//        let bgColor = Color(cgColor: UIColor.systemBackground.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark)).cgColor)
//#else
//        @Environment(\.widgetRenderingMode) var widgetRenderingMode
//        var bgColor: Color { widgetRenderingMode == .fullColor ? Color.black : .white.opacity(0) }
//#endif

        var body: some View {
            VStack {
                Text("Host: ")
                Text(entry.data?.url ?? "nil")
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
    DebugWidget()
} timeline: {
    Entry.placeholder()
}
#Preview("Expired", as: .systemLarge) {
    DebugWidget()
} timeline: {
    Entry.expired()
}
#Preview("systemLarge", as: .systemLarge) {
    DebugWidget()
} timeline: {
    Entry.preview
}
#endif
//
//#if os(watchOS)
//#Preview("⌚️Placeholder", as: .accessoryRectangular) {
//    DebugWidget()
//} timeline: {
//    Entry.placeholder()
//}
//#Preview("⌚️Expired", as: .accessoryRectangular) {
//    DebugWidget()
//} timeline: {
//    Entry.expired()
//}
//#Preview("⌚️systemLarge", as: .accessoryRectangular) {
//    DebugWidget()
//} timeline: {
//    Entry.preview
//}
//#endif
