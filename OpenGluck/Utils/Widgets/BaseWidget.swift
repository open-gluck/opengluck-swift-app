
import WidgetKit
import Intents
import WatchConnectivity
import SwiftUI
import OG

// Exposes a class to provide for a base widget that you can easily use to create widgets that automatically refresh and expire
// at a certain point of time.
// See the TimelineDebugWidget implementation for more ifno.

protocol BaseWidgetConfiguration {
    associatedtype Data
    
    static var kind: String { get }
    static var supportedWidgetFamilies: [WidgetFamily] { get }
    static var maximumValidityInterval: TimeInterval? { get }
    static var useSameDataForAllEntries: Bool { get }
    static var refreshInterval: TimeInterval { get }
    static var numberOfEntries: Int { get } // beware not too many, 100 seems fine, 200 sometimes not, 500 breaks
    static var configurationDisplayName: String { get }
    static var description: String { get }
    
    static func getRefreshTimelineAfter() -> Date
    static func getDataStartingDate(_ data: Data) -> Date?
    static func getPreviewData() -> Data
    static func getData(forTimelineDate timelineDate: Date, date: Date) async throws -> Data
}

@MainActor
class BaseWidgetProvider<Configuration, WidgetView> where Configuration: BaseWidgetConfiguration, WidgetView: View {
    let content: (Entry) -> WidgetView
    
    init(content: @escaping (Entry) -> WidgetView) {
        self.content = content
    }
    
    struct Provider: TimelineProvider {
        func placeholder(in context: Context) -> Entry {
            return Entry.placeholder()
        }
        
        private var entries: [Entry] {
            get async throws {
                var entries = [Entry]()
                let now = Date()
                
                let sameDataForAllEntry: Configuration.Data? = !Configuration.useSameDataForAllEntries ? nil : try await Configuration.getData(forTimelineDate: now, date: now)
                var foundExpiredData = false
                
                for n in 0...Configuration.numberOfEntries {
                    let date = now.addingTimeInterval(TimeInterval(n)*Configuration.refreshInterval)
                    
                    let data: Configuration.Data
                    if let sameDataForAllEntry {
                        data = sameDataForAllEntry
                    } else {
                        data = try await Configuration.getData(forTimelineDate: now, date: date)
                    }
                    let startingDate = Configuration.getDataStartingDate(data)

                    if let maximumValidityInterval = Configuration.maximumValidityInterval {
                        let elapsed = date.timeIntervalSince(startingDate ?? now)
                        if elapsed > maximumValidityInterval {
                            // we're now expired
                            entries.append(Entry(entryType: .expired, timelineDate: now, startingDate: startingDate, date: date, data: data))
                            foundExpiredData = true
                            break
                        }
                    }
                    
                    entries.append(Entry(entryType: .normal, timelineDate: now, startingDate: startingDate, date: date, data: data))
                }
                
                // automatically insert the expired entry after the last entry expired
                if !foundExpiredData, let maximumValidityInterval = Configuration.maximumValidityInterval {
                    entries = entries.filter {
                        $0.date.timeIntervalSince(now) < maximumValidityInterval
                    }
                    entries.append(Self.Entry.expired(forTimelineDate: now))
                }
                
                return entries
            }
        }
        
        @preconcurrency func getSnapshot(in context: Self.Context, completion: @escaping @Sendable (Self.Entry) -> Void) {
            Task {
                completion((try await entries).first!)
            }
        }
        
        @preconcurrency func getTimeline(in context: Self.Context, completion: @escaping @Sendable (Timeline<Self.Entry>) -> Void) {
            Task {
                var refreshTimelineAfter = Configuration.getRefreshTimelineAfter()
#if !DEBUG
                // when no in DEBUG mode, refresh every 30m at least, because of WidgetKit restrictions
                let in30m = Date().addingTimeInterval(30 * 60)
                if in30m > refreshTimelineAfter {
                    refreshTimelineAfter = in30m
                }
#endif
//                #if os(iOS)
//                // iOS 18 is very relunctant to refresh, even when we have enabled WidgetKit developer mode
//                let timeline = Timeline(entries: try await entries, policy: .atEnd)
//                #else
                let timeline = Timeline(entries: try await entries, policy: .after(refreshTimelineAfter))
//                #endif
                completion(timeline)
            }
        }
    }
    
    struct Entry: TimelineEntry {
        let entryType: EntryType
        let timelineDate: Date
        let startingDate: Date?
        let date: Date
        let data: Configuration.Data?
        
        enum EntryType: String {
            case normal
            case expired
            case placeholder
        }
        
        var elapsed: TimeInterval {
            date.timeIntervalSince(startingDate ?? timelineDate)
        }
        
        var expired: Bool {
            guard let maximumValidityInterval = Configuration.maximumValidityInterval else {
                return false
            }
            return elapsed >= maximumValidityInterval
        }
        
        static func expired(forTimelineDate timelineDate: Date? = nil) -> Entry {
            let now = Date()
            guard let maximumValidityInterval = Configuration.maximumValidityInterval else {
                fatalError("Cannot get expired entry for provider that does not expire")
            }
            return Entry(entryType: .expired, timelineDate: timelineDate ?? now, startingDate: nil, date: (timelineDate ?? now).addingTimeInterval(maximumValidityInterval), data: nil)
        }
        
        var freshnessLevel: Double? {
            min(1, max(0, 1.0 - (elapsed / Configuration.maximumValidityInterval!)))
        }
        
        static func placeholder(forTimelineDate timelineDate: Date? = nil, date: Date? = nil) -> Entry {
            let now = Date()
            return Entry(entryType: .placeholder, timelineDate: timelineDate ?? now, startingDate: nil, date: date ?? now, data: nil)
        }
        
        static var preview: Entry {
            let data = Configuration.getPreviewData()
            return Entry(entryType: .normal, timelineDate: Date(), startingDate: Configuration.getDataStartingDate(data), date: Date(), data: data)
        }
    }
    
    var configuration: Configuration.Type {
        Configuration.self
    }
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Configuration.kind, provider: Provider()) { entry in
            self.content(entry)
        }
        .configurationDisplayName(Configuration.configurationDisplayName)
        .description(Configuration.description)
        .supportedFamilies(Configuration.supportedWidgetFamilies)
    }
}
