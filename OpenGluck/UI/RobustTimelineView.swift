// A TimelineView that doesn't bug on macOS.
// (Basically it doesn't use TimelineView on macOS.) :funnyandsad:

import SwiftUI
import Combine

struct NaiveTimelineViewContext {
    let date: Date
}

@MainActor
fileprivate struct NaiveTimelineView<Schedule: TimelineSchedule, Content: View>: View {
    let schedule: Schedule
    let content: (NaiveTimelineViewContext) -> Content
    
    @State private var context: NaiveTimelineViewContext = NaiveTimelineViewContext(date: Date())
    
    init(_ schedule: Schedule, @ViewBuilder content: @escaping (NaiveTimelineViewContext) -> Content) {
        self.schedule = schedule
        self.content = content
    }
    
    var body: some View {
        content(context)
            .task {
                let startDate = Date().addingTimeInterval(-0.001)
                for date in schedule.entries(from: startDate, mode: TimelineScheduleMode.normal) {
                    try? await Task.sleep(nanoseconds: UInt64(max(0, date.timeIntervalSinceNow) * 1_000_000_000))
                    guard !Task.isCancelled else { return }
                    context = NaiveTimelineViewContext(date: date)
                }
            }
    }
}

#if os(watchOS)
typealias RobustTimelineView = TimelineView
#else
struct RobustTimelineView<Schedule: TimelineSchedule, Content: View>: View {
    //    static var enableWorkaround: Bool {
    //        // FIXME
    //        let enabled = FileManager.default.fileExists(atPath: "/tmp/swiftui-timeline-workaround")
    //        print("DEBUG WORKAROUND ENABLED", enabled)
    //        return enabled
    //    }
    //    static var enableDisplayLink: Bool { false }
    //
    let schedule: Schedule
    let content: (NaiveTimelineViewContext) -> Content
    
    // Detect if running on Mac at runtime
    @State private var isRunningOnMac: Bool = false
    
    //    // State for refresh mechanisms
    //    @State private var refreshTrigger = UUID()
    //    @State private var timer: AnyCancellable?
    //    @State private var displayLink: CADisplayLink?
    //    @State private var lastTimelineComputedContext = Date()
    //    @State private var lastTimelineComputedAt = Date()
    
    init(_ schedule: Schedule, @ViewBuilder content: @escaping (NaiveTimelineViewContext) -> Content) {
        self.schedule = schedule
        self.content = content
    }
    
    var body: some View {
        if isRunningOnMac {
            NaiveTimelineView(schedule) { context in
                content(context)
            }
        } else {
            SwiftUI.TimelineView(schedule) { context in
                content(NaiveTimelineViewContext(date: context.date))
                //                .task(id: context.date) {
                //                    if context.date > lastTimelineComputedAt {
                //                        lastTimelineComputedContext = context.date
                //                        lastTimelineComputedAt = Date()
                //                    }
                //                }
            }
            //        .id(isRunningOnMac ? "\(refreshTrigger)" : "standard")
            .onAppear {
                detectPlatform()
                //            if isRunningOnMac {
                //                setupMacRefreshMechanisms()
                //            }
            }
            //        .onDisappear {
            //            if isRunningOnMac {
            //                cleanupRefreshMechanisms()
            //            }
        }
    }
    
    private func detectPlatform() {
        // Check if we're on a Mac at runtime
        let processInfo = ProcessInfo.processInfo
        if processInfo.isMacCatalystApp || processInfo.isiOSAppOnMac {
            isRunningOnMac = true
        }
    }
    
    //    private func setupMacRefreshMechanisms() {
    //        // Timer-based backup (most reliable)
    //        timer = Timer.publish(every: 1.0, on: .main, in: .common)
    //            .autoconnect()
    //            .sink { _ in
    //                forceRefresh()
    //            }
    //
    //        // DisplayLink-based refresh
    //        setupDisplayLink()
    //    }
    //
    //    // We need to use NSObject for the target
    //    private class DisplayLinkTarget: NSObject {
    //        var callback: (() -> Void)?
    //
    //        @objc func fired() {
    //            callback?()
    //        }
    //    }
    //
    //
    //    private func setupDisplayLink() {
    //        guard Self.enableDisplayLink else { return }
    //
    //        let target = DisplayLinkTarget()
    //        target.callback = { forceRefresh() }
    //
    //        displayLink = CADisplayLink(target: target, selector: #selector(DisplayLinkTarget.fired))
    //        displayLink?.add(to: .main, forMode: .common)
    //
    //        // Store target to prevent deallocation
    //        objc_setAssociatedObject(self, "displayLinkTarget", target, .OBJC_ASSOCIATION_RETAIN)
    //    }
    //
    //    private func forceRefresh() {
    //        print("DEBUG TIMES \(-lastTimelineComputedAt.timeIntervalSinceNow) \(-lastTimelineComputedContext.timeIntervalSinceNow)")
    //        DispatchQueue.main.async {
    //            if Self.enableWorkaround {
    //                refreshTrigger = UUID()
    //            }
    //        }
    //    }
    //
    //    private func cleanupRefreshMechanisms() {
    //        timer?.cancel()
    //        timer = nil
    //
    //        displayLink?.invalidate()
    //        displayLink = nil
    //    }
}
#endif
//
//// Extension to ProcessInfo to detect platform at runtime
//extension ProcessInfo {
//    var isMacCatalystApp: Bool {
//        return isiOSAppOnMac || (ProcessInfo.processInfo.environment["CATALYST_RUNTIME_IDENTIFIER"] != nil)
//    }
//
//    var isiOSAppOnMac: Bool {
//        if #available(iOS 14.0, *) {
//            return ProcessInfo.processInfo.isiOSAppOnMac
//        }
//        return false
//    }
//}

