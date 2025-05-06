import Foundation
import SwiftUI
@preconcurrency import OG // FIXME LATER TODO upgrade lib

@MainActor
class OpenGluckEnvironment: ObservableObject
{
    let debugMode: Bool = false // if set to true at compile-time, enable additional logging, useful when debugging previews
    
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
    
    @Published var refreshing: Bool = false
    @Published var lastRefreshStartedAt: Date? = nil
    @Published var logText: String = "Log:\n"
    @Published var refreshStep: String = ""
    
    var debugDescription: String {
        "revision=\(revision == nil ? "nil" : "\(revision!)"), hasTimedOut=\(hasTimedOut), lastSuccessAt=\(lastSuccessAt ?? Date()), lastAttemptAt=\(lastAttemptAt ?? Date()), refreshing=\(refreshing), lastRefreshStartedAt=\(lastRefreshStartedAt == nil ? "nil" : "\(lastRefreshStartedAt!)") refreshStep=\(refreshStep)"
    }
    
    var isRefreshStepShowable: Bool {
        !self.hasTimedOut && self.lastAttemptAt == nil && self.currentGlucoseRecord == nil && OpenGluckConnection.client != nil
    }
    
    var usableRefreshStep: String {
        return if isRefreshStepShowable {
            refreshStep
        } else {
            ""
        }
    }
    
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
    
    func copy(to: OpenGluckEnvironment, madeChanges: inout Bool) {
        madeChanges = false
        
        if to.revision != self.revision {
            to.revision = self.revision; madeChanges = true
        }
        if to.hasTimedOut != self.hasTimedOut {
            to.hasTimedOut = self.hasTimedOut; madeChanges = true
        }
        if to.currentGlucoseRecord != self.currentGlucoseRecord {
            to.currentGlucoseRecord = self.currentGlucoseRecord; madeChanges = true
        }
        if to.currentInstantGlucoseRecord != self.currentInstantGlucoseRecord {
            to.currentInstantGlucoseRecord = self.currentInstantGlucoseRecord; madeChanges = true
        }
        if to.lastHistoricGlucoseRecord != self.lastHistoricGlucoseRecord {
            to.lastHistoricGlucoseRecord = self.lastHistoricGlucoseRecord; madeChanges = true
        }
        if to.lastGlucoseRecords != self.lastGlucoseRecords {
            to.lastGlucoseRecords = self.lastGlucoseRecords; madeChanges = true
        }
        if to.cgmHasRealTimeData != self.cgmHasRealTimeData {
            to.cgmHasRealTimeData = self.cgmHasRealTimeData; madeChanges = true
        }
        if to.lastInsulinRecords != self.lastInsulinRecords {
            to.lastInsulinRecords = self.lastInsulinRecords; madeChanges = true
        }
        if to.lastLowRecords != self.lastLowRecords {
            to.lastLowRecords = self.lastLowRecords; madeChanges = true
        }
        if to.lastSuccessAt != self.lastSuccessAt {
            to.lastSuccessAt = self.lastSuccessAt; madeChanges = true
        }
        if to.lastAttemptAt != self.lastAttemptAt {
            to.lastAttemptAt = self.lastAttemptAt; madeChanges = true
        }
        
        if to.refreshing != self.refreshing {
            to.refreshing = self.refreshing; madeChanges = true
        }
        if to.lastRefreshStartedAt != self.lastRefreshStartedAt {
            to.lastRefreshStartedAt = self.lastRefreshStartedAt; madeChanges = true
        }
        if to.logText != self.logText {
            to.logText = self.logText; madeChanges = true }
        
        let usableRefreshStep = self.usableRefreshStep
        if to.refreshStep != usableRefreshStep {
            to.refreshStep = usableRefreshStep; madeChanges = true
        }
    }
    
    var hasException: Bool {
        lastAttemptAt != nil && lastSuccessAt == nil
    }
    
    static func timedOutEnvironment(now: Date) -> OpenGluckEnvironment {
        OpenGluckEnvironment(lastSuccessAt: now, lastAttemptAt: now)
    }
    
    func log(_ message: String) {
        if debugMode {
            print("DEBUG OpenGluckEnvironment log: \(message)")
            logText += "\(message)\n"
        }
    }
}

extension OpenGluckEnvironment {
    static var refreshInterval: TimeInterval { 5 }
    private var debugSimulateTimeouts: Bool { false }
    
    private var textsGotResults: [String] {
        [
            "Got results…",
            "Diabeting…",
            "Mining Info…",
            "Excavating Data…",
            "Digging Records…"
        ]
    }
    
    func refreshUnlessStartedRecently(openGlückConnection: OpenGluckConnection) {
        refresh(openGlückConnection: openGlückConnection, unlessStartedRecently: true)
    }
    
    func refresh(openGlückConnection: OpenGluckConnection, unlessStartedRecently: Bool = false) {
        log("refresh()")
        Task { @MainActor in
            guard !refreshing else { return }
            guard !debugSimulateTimeouts && OpenGluckManager.openglückUrl != nil && OpenGluckManager.openglückToken != nil else {
                hasTimedOut = true
                return
            }
            if unlessStartedRecently {
                let isNeeded: Bool = if let elapsedSinceLastRefreshStarted = lastRefreshStartedAt?.timeIntervalSinceNow {
                    -elapsedSinceLastRefreshStarted > Self.refreshInterval
                } else {
                    true
                }
                guard isNeeded else {
                    return
                }
            }
            
            lastRefreshStartedAt = Date()
            refreshStep = "Refreshing…"
            refreshing = true
            
            defer {
                self.refreshing = false
            }
            
            let timeoutTask = Task {
                // allow the modal to stay 5 seconds, if we still don't have data, surrender, and let the
                // other view show a message telling the user this takes too much time
                do {
                    try await Task.sleep(for: .seconds(5))
                } catch {
                    return
                }
                hasTimedOut = true
            }
            
            defer { timeoutTask.cancel() }
            
            if let currentData = try? await openGlückConnection.getCurrentData(becauseUpdateOf: "openGlück.getCurrentData() returned data") {
                refreshStep = textsGotResults.randomElement()!
                log("environment.revision=\(String(describing: self.revision))")
                if self.revision == nil || currentData.revision != self.revision! {
                    let lastData: LastData?
                    let syncClient = await openGlückConnection.getSyncClient()
                    if self.revision == nil {
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
                            self.lastGlucoseRecords = lastGlucoseRecords
                        }
                        if let lastInsulinRecords = lastData.insulinRecords {
                            self.lastInsulinRecords = lastInsulinRecords
                        }
                        if let lastLowRecords = lastData.lowRecords {
                            self.lastLowRecords = lastLowRecords
                        }
                    } else {
                        log("Could not get last data")
                    }
                    
                    self.revision = currentData.revision
                    self.cgmHasRealTimeData = currentData.hasCgmRealTimeData
                    self.currentGlucoseRecord = currentData.currentGlucoseRecord
                    self.currentInstantGlucoseRecord = currentData.currentInstantGlucoseRecord
                    self.lastHistoricGlucoseRecord = currentData.lastHistoricGlucoseRecord
                    self.lastSuccessAt = Date()
                    log("Now at revision \(String(describing: self.revision)), with \(String(describing: self.lastGlucoseRecords?.count)) glucose records")
                }
            } else {
                log("openGlückConnection.getCurrentData() returned nil")
            }
            self.lastAttemptAt = Date()
            self.hasTimedOut = false
            log("refresh complete at \(Date())")
        }
    }
}

struct OpenGluckEnvironmentUpdaterRootView<Content: View>: View {
    @ViewBuilder
    var content: () -> Content
    @StateObject var environment: OpenGluckEnvironment = OpenGluckEnvironment()
    @StateObject var environmentCopy: OpenGluckEnvironment = OpenGluckEnvironment() // for some obscure reasons re-rendering the view does not re-render the children
    @EnvironmentObject var openGlückConnection: OpenGluckConnection
    let timer = Timer.publish(every: OpenGluckEnvironment.refreshInterval, on: .main, in: .common).autoconnect()
    
#if os(watchOS)
    @Environment(\.isLuminanceReduced) var isLuminanceReduced
#endif
    
    @MainActor
    private func handleReceivedEnvironment() {
        var madeChanges: Bool = false
        withAnimation {
            environment.copy(to: environmentCopy, madeChanges: &madeChanges)
        }
    }
    @State var debugId: Int = 1
    @State var debugContentId: String = "\(UUID())"
    var body: some View {
        content()
            .environmentObject(environmentCopy)
            .onReceive(environment.$revision) { newValue in
                handleReceivedEnvironment()
            }
            .onReceive(environment.$currentGlucoseRecord) { newValue in
                handleReceivedEnvironment()
            }
            .onReceive(environment.$currentInstantGlucoseRecord) { newValue in
                handleReceivedEnvironment()
            }
            .onReceive(environment.$cgmHasRealTimeData) { newValue in
                handleReceivedEnvironment()
            }
            .onReceive(environment.$hasTimedOut) { newValue in
                handleReceivedEnvironment()
            }
            .onReceive(environment.$lastAttemptAt) { newValue in
                handleReceivedEnvironment()
            }
            .onReceive(environment.$lastGlucoseRecords) { newValue in
                handleReceivedEnvironment()
            }
            .onReceive(environment.$lastInsulinRecords) { newValue in
                handleReceivedEnvironment()
            }
            .onReceive(environment.$lastLowRecords) { newValue in
                handleReceivedEnvironment()
            }
            .onReceive(environment.$lastRefreshStartedAt) { newValue in
                handleReceivedEnvironment()
            }
            .onReceive(environment.$lastHistoricGlucoseRecord) { newValue in
                handleReceivedEnvironment()
            }
            .onReceive(timer) { _ in
                if OpenGluckEnvironment.enableAutoUpdate {
                    environment.refreshUnlessStartedRecently(openGlückConnection: openGlückConnection)
                }
                if environment.refreshing && -(environment.lastRefreshStartedAt?.timeIntervalSinceNow ?? 0) > OpenGluckEnvironment.refreshInterval {
                    environment.refreshStep = "Still on it…"
                }
            }
            .onAppear {
                environment.refreshUnlessStartedRecently(openGlückConnection: openGlückConnection)
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name.refreshOpenGlück)) { _ in
                print("Notification.Name.refreshOpenGlück")
                environment.refresh(openGlückConnection: openGlückConnection)
            }
#if os(iOS)
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                handleReceivedEnvironment()
                environment.refresh(openGlückConnection: openGlückConnection)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIScene.didActivateNotification)) { _ in
                // FIXME we have a weird bug where this does not filre on some occasion. When this bug occur, then
                // the interface is frozen.
                environment.refresh(openGlückConnection: openGlückConnection)
            }
#endif
#if os(watchOS)
            .task(id: isLuminanceReduced) {
                if(!isLuminanceReduced) {
                    environment.refreshUnlessStartedRecently(openGlückConnection: openGlückConnection)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: WKApplication.didEnterBackgroundNotification)) { _ in
                environment.clear(hideInterface: false)
            }
            .onReceive(NotificationCenter.default.publisher(for: WKApplication.willEnterForegroundNotification)) { _ in
                environment.clear(hideInterface: true)
            }
            .onReceive(NotificationCenter.default.publisher(for: WKApplication.didBecomeActiveNotification)) { _ in
                environment.refresh(openGlückConnection: openGlückConnection)
            }
#endif
    }
    
    private func setRefreshing(refreshing: Bool) {
        environment.refreshing = refreshing
    }
    
    private func log(_ message: String) {
        environment.log(message)
    }
    
}

extension Notification.Name {
    static let refreshOpenGlück = Notification.Name("OpenGluckEnvironmentUpdater.refreshOpenGlück")
}


@MainActor
struct OpenGluckEnvironmentUpdaterView<Content>: View where Content: View {
    @ViewBuilder
    let content: () -> Content
    
    // @State var rerender: Int = 0
    @EnvironmentObject var environment: OpenGluckEnvironment
    
    @ViewBuilder
    var bodyContent: some View {
        VStack {
            if !environment.hasTimedOut && environment.lastAttemptAt == nil && environment.currentGlucoseRecord == nil && OpenGluckConnection.client != nil {
                VStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(.circular)
                        .padding()
                    Text(environment.refreshStep)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            } else {
                self.content()
            }
        }
    }
    
    var body: some View {
        ZStack {
            bodyContent
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
        OpenGluckEnvironmentUpdaterView {
            VStack {
                Preview()
            }
        }
        .environmentObject(OpenGluckConnection())
    }
}
