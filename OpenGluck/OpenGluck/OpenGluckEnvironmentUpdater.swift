import Foundation
import SwiftUI
import OG

@MainActor
class OpenGluckEnvironment: ObservableObject
{
    static var enableAutoUpdate: Bool = true
    @Published var revision: Int64? = nil
    @Published var hasTimedOut: Bool = false
    @Published var currentGlucoseRecord: OpenGluckGlucoseRecord? = nil
    @Published var currentInstantGlucoseRecord: OpenGluckInstantGlucoseRecord? = nil
    @Published var lastHistoricGlucoseRecord: OpenGluckGlucoseRecord? = nil
    @Published var lastGlucoseRecords: [OpenGluckGlucoseRecord]? = nil
    @Published var cgmHasRealTimeData: Bool? = nil
    @Published var lastInsulinRecords: [OpenGluckInsulinRecord]? = nil
    @Published var lastLowRecords: [OpenGluckLowRecord]? = nil
    @Published var lastSuccessAt: Date? = nil
    @Published var lastAttemptAt: Date? = nil
    
    init(currentGlucoseRecord: OpenGluckGlucoseRecord? = nil, currentInstantGlucoseRecord: OpenGluckInstantGlucoseRecord? = nil, lastHistoricGlucoseRecord: OpenGluckGlucoseRecord? = nil, lastGlucoseRecords: [OpenGluckGlucoseRecord]? = nil, lastInsulinRecords: [OpenGluckInsulinRecord]? = nil, lastLowRecords: [OpenGluckLowRecord]? = nil, lastSuccessAt: Date? = nil, lastAttemptAt: Date? = nil) {
        self.currentGlucoseRecord = currentGlucoseRecord
        self.currentInstantGlucoseRecord = currentInstantGlucoseRecord
        self.lastHistoricGlucoseRecord = lastHistoricGlucoseRecord
        self.lastGlucoseRecords = lastGlucoseRecords
        self.lastInsulinRecords = lastInsulinRecords
        self.lastLowRecords = lastLowRecords
        self.lastSuccessAt = lastSuccessAt
        self.lastAttemptAt = lastAttemptAt
    }

    func clear(hideInterface: Bool) {
        self.currentGlucoseRecord = nil
        self.currentInstantGlucoseRecord = nil
        self.lastHistoricGlucoseRecord = nil
        self.lastGlucoseRecords = nil
        self.lastInsulinRecords = nil
        self.lastLowRecords = nil
        self.revision = nil
        if hideInterface {
            self.lastAttemptAt = nil
        }
    }
    
    var hasException: Bool {
        lastAttemptAt != nil && lastSuccessAt == nil
    }
    
    static func timedOutEnvironment(now: Date) -> OpenGluckEnvironment {
        OpenGluckEnvironment(lastSuccessAt: now, lastAttemptAt: now)
    }
}

extension Notification.Name {
    static let refreshOpenGlück = Notification.Name("OpenGluckEnvironmentUpdater.refreshOpenGlück")
}


@MainActor
struct OpenGluckEnvironmentUpdater<Content>: View where Content: View {
    private let debugSimulateTimeouts: Bool = false

    @ViewBuilder
    let content: () -> Content
    
    @EnvironmentObject var openGlückConnection: OpenGluckConnection
    @StateObject var environment: OpenGluckEnvironment = OpenGluckEnvironment()
    @State var rerender = UUID()
    let debugMode: Bool = false // if true, enable additional logging, useful when debugging previews
    
    static var refreshInterval: TimeInterval { 5 }
    let timer = Timer.publish(every: Self.refreshInterval, on: .main, in: .common).autoconnect()
    
    @State var refreshStep: String = ""
    @State var logText: String = "Log:\n"
    private func log(_ message: String) {
        logText += "\(message)\n"
    }
    
#if os(watchOS)
    @Environment(\.isLuminanceReduced) var isLuminanceReduced
#endif
    
    @ViewBuilder
    var bodyContent: some View {
        VStack {
            if debugMode {
                ScrollView {
                    Text("\(logText)")
                }
            }
            if rerender.uuidString == "" { EmptyView() }
            if !environment.hasTimedOut && environment.lastAttemptAt == nil && environment.currentGlucoseRecord == nil && OpenGluckConnection.client != nil {
                VStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(.circular)
                        .padding()
                    Text(refreshStep)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            } else {
                self.content()
            }
        }
        .onReceive(environment.$currentGlucoseRecord, perform: { _ in
            rerender = UUID()
        })
        .onReceive(environment.$currentInstantGlucoseRecord, perform: { _ in
            rerender = UUID()
        })
    }
    
    private func refreshUnlessStartedRecently() {
        let runRefresh: Bool
        if let elapsedSinceLastRefreshStarted = lastRefreshStartedAt?.timeIntervalSinceNow {
            runRefresh = -elapsedSinceLastRefreshStarted > Self.refreshInterval
        } else {
            runRefresh = true
        }
        if runRefresh {
            refresh()
        }
    }
        
    var body: some View {
        ZStack {
            // We use a TimelineView(.animation) as a hack to make sure that watchOS
            // will re-render our view as fast is it can. Since it displays information
            // about our glucose levels, we don't want this view to be stale.
            TimelineView(.animation) { context in
                let currentGlucoseRecord = environment.currentGlucoseRecord
                let freshnessLevel: Double? = if let currentGlucoseRecord { 1.0 - (-currentGlucoseRecord.timestamp.timeIntervalSince(context.date) / OpenGluckUI.maxGlucoseFreshnessTimeInterval) } else { nil }
                if let freshnessLevel, freshnessLevel < 0 {
                    bodyContent
                        .environmentObject(OpenGluckEnvironment.timedOutEnvironment(now: context.date))
                } else {
                    bodyContent
                        .environmentObject(environment)
                }
            }
        }
            .onReceive(timer) { _ in
                if OpenGluckEnvironment.enableAutoUpdate {
                    refreshUnlessStartedRecently()
                }
                if refreshing && -(lastRefreshStartedAt?.timeIntervalSinceNow ?? 0) > Self.refreshInterval {
                    refreshStep = "Still on it…"
                }
            }
            .onAppear {
                refreshUnlessStartedRecently()
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name.refreshOpenGlück)) { _ in
                print("Notification.Name.refreshOpenGlück")
                refresh()
            }
#if os(iOS)
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                print("UIApplication.didBecomeActiveNotification")
                refresh()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                print("UIApplication.willResignActiveNotification")
            }
#endif
#if os(watchOS)
            .task(id: isLuminanceReduced) {
                print("isLuminanceReduced=\(isLuminanceReduced)")
                if(!isLuminanceReduced) {
                    refreshUnlessStartedRecently()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: WKApplication.didEnterBackgroundNotification)) { _ in
                print("WKApplication.didEnterBackgroundNotification")
                environment.clear(hideInterface: false)
            }
            .onReceive(NotificationCenter.default.publisher(for: WKApplication.willEnterForegroundNotification)) { _ in
                print("WKApplication.willEnterForegroundNotification")
                environment.clear(hideInterface: true)
            }
            .onReceive(NotificationCenter.default.publisher(for: WKApplication.didBecomeActiveNotification)) { _ in
                print("WKApplication.didBecomeActiveNotification")
                refresh()
            }
            .onReceive(NotificationCenter.default.publisher(for: WKApplication.willResignActiveNotification)) { _ in
                print("WKApplication.willResignActiveNotification")
}
#endif
    }
    
    @State var refreshing: Bool = false
    @State var lastRefreshStartedAt: Date? = nil
    private func setRefreshing(refreshing: Bool) {
        self.refreshing = refreshing
    }
    
    private let textsGotResults = [
        "Got results…",
        "Diabeting…",
        "Mining Info…",
        "Excavating Data…",
        "Digging Records…"
    ]
    
    private func refresh() {
        log("refresh()")
        Task {
            guard !refreshing else { return }
            guard !debugSimulateTimeouts && OpenGluckManager.openglückUrl != nil && OpenGluckManager.openglückToken != nil else {
                environment.hasTimedOut = true
                return
            }
            defer { Task { @MainActor in self.refreshing = false } }
            refreshStep = "Refreshing…"
            refreshing = true
            lastRefreshStartedAt = Date()

            let timeoutTask = Task {
                // allow the modal to stay 5 seconds, if we still don't have data, surrender, and let the
                // other view show a message telling the user this takes too much time
                do {
                    try await Task.sleep(for: .seconds(5))
                } catch {
                    return
                }
                environment.hasTimedOut = true
            }
            
            defer { timeoutTask.cancel() }

            if let currentData = try? await openGlückConnection.getCurrentData(becauseUpdateOf: "openGlück.getCurrentData() returned data") {
                refreshStep = textsGotResults.randomElement()!
                log("environment.revision=\(String(describing: environment.revision))")
                if environment.revision == nil || currentData.revision != environment.revision! {
                    let lastData: LastData?
                    let syncClient = await openGlückConnection.getSyncClient()
                    if environment.revision == nil {
                        log("Getting last data")
                        do {
                            lastData = try await syncClient.getLastData()
                        } catch {
                            log("Failed getting last data, ignoring: \(error)")
                            lastData = nil
                        }
                    } else {
                        log("Getting last data at revision")
                        do {
                            lastData = try await syncClient.getLastDataIfChanged()
                        } catch {
                            log("Failed getting last data from revision, ignoring: \(error)")
                            lastData = nil
                        }
                    }
                    if let lastData {
                        log("Got last data")
                        if let lastGlucoseRecords = lastData.glucoseRecords {
                            environment.lastGlucoseRecords = lastGlucoseRecords
                        }
                        if let lastInsulinRecords = lastData.insulinRecords {
                            environment.lastInsulinRecords = lastInsulinRecords
                        }
                        if let lastLowRecords = lastData.lowRecords {
                            environment.lastLowRecords = lastLowRecords
                        }
                    } else {
                        log("Could not get last data")
                    }

                    environment.revision = currentData.revision
                    environment.cgmHasRealTimeData = currentData.hasCgmRealTimeData
                    environment.currentGlucoseRecord = currentData.currentGlucoseRecord
                    environment.currentInstantGlucoseRecord = currentData.currentInstantGlucoseRecord
                    environment.lastHistoricGlucoseRecord = currentData.lastHistoricGlucoseRecord
                    environment.lastSuccessAt = Date()
                    log("Now at revision \(String(describing: environment.revision)), with \(String(describing: environment.lastGlucoseRecords?.count)) glucose records")
                }
            } else {
                log("openGlückConnection.getCurrentData() returned nil")
            }
            environment.lastAttemptAt = Date()
            environment.hasTimedOut = false
            log("Refresh complete")
        }
    }
}

struct OpenGluckEnvironmentUpdater_Previews: PreviewProvider {
    struct Preview: View {
        @EnvironmentObject var environment: OpenGluckEnvironment
        
        var body: some View {
            List {
                Text("\(String(describing: environment))")
                Text("\(String(describing: environment.currentGlucoseRecord))")
                Text("\(String(describing: environment.currentInstantGlucoseRecord))")
                Text("lastGlucoseRecords.count=\(String(describing: environment.lastGlucoseRecords?.count))")
            }
        }
    }
    static var previews: some View {
        OpenGluckEnvironmentUpdater {
            VStack {
                Preview()
            }
        }
        .environmentObject(OpenGluckConnection())
    }
}
