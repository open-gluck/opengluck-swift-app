import Foundation
import Charts
import SwiftUI
import OG
import OGUI

fileprivate struct GlucoseGraphUI {
    static let fadeColor: Color = Color(red: 200/256, green: 200/256, blue: 205/256)
#if os(iOS)
    static let systemGray2 = Color(cgColor: UIColor.systemGray2.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark)).cgColor)
#else
    static  let systemGray2 = Color(red: 99/256, green: 99/256, blue: 102/256)
#endif
}

class InsulinCollapser {
    enum ItemTextPlacement {
        case unknown
        case primary
        case alternative
        case hidden
        
        var reversed: ItemTextPlacement {
            switch self {
            case .alternative: return .primary
            case .primary: return .alternative
            case .hidden: return .hidden
            case .unknown: return .unknown
            }
        }
    }
    
    struct Item: Hashable {
        let timestamp: Date
        let text: String
        let textPlacement: ItemTextPlacement
        let textAgo: String
        let mgDl: Int?
    }

    init(collapseInsulinUnitsInterval: TimeInterval = 15 * 60) {
        self.collapseInsulinUnitsInterval = collapseInsulinUnitsInterval
    }
    
    // this is copied and pasted from GlucoseGraph
    // LATER factorize
    
    let collapseInsulinUnitsInterval: TimeInterval
    private func collapsingUnits(atTimestamp: Date, hides: Date) -> Bool {
        if hides >= atTimestamp {
            return false
        }
        // FIXME or the other way around?
        return atTimestamp.timeIntervalSince(hides) < collapseInsulinUnitsInterval
    }
    
    public func isInsulinHiddenByPrevious(insulinRecords: [OpenGluckInsulinRecord], atTimestamp: Date) -> Bool {
        return insulinRecords
            .filter { !$0.deleted}
            .contains(where: { collapsingUnits(atTimestamp: atTimestamp, hides: $0.timestamp) })
    }
    
    public func getCollapsedInsulinText(insulinRecords: [OpenGluckInsulinRecord], atTimestamp: Date) -> String {
        let matchingRecords = getMatchingCollapsedRecords(insulinRecords: insulinRecords, atTimestamp: atTimestamp)
        let matchingData: [String] = matchingRecords
            .map {
                return "\($0.units)"
            }
        return matchingData.joined(separator: "﹢")
    }
    
    private func getMatchingCollapsedRecords(insulinRecords: [OpenGluckInsulinRecord], atTimestamp: Date) -> [OpenGluckInsulinRecord] {
        var matchingRecordsIds: Set<UUID> = Set()
        func findMatchingRecords(inRecords insulinRecords: [OpenGluckInsulinRecord], atTimestamp: Date, matchingRecordsIds: inout Set<UUID>) {
            // find recursive matching records
            for record in (insulinRecords
                .filter ({ $0.timestamp == atTimestamp || self.collapsingUnits(atTimestamp: $0.timestamp, hides: atTimestamp) })
                .sorted(by: { $0.timestamp < $1.timestamp })) {
                if !matchingRecordsIds.contains(record.id) {
                    matchingRecordsIds.insert(record.id)
                    findMatchingRecords(inRecords: insulinRecords, atTimestamp: record.timestamp, matchingRecordsIds: &matchingRecordsIds)
                }
            }
        }
        findMatchingRecords(inRecords: insulinRecords, atTimestamp: atTimestamp, matchingRecordsIds: &matchingRecordsIds)
        let matchingRecords = insulinRecords
            .filter { matchingRecordsIds.contains($0.id) }
            .sorted(by: { $0.timestamp < $1.timestamp })
        return matchingRecords
    }
    
    public func getCollapsedInsulinAgoText(insulinRecords: [OpenGluckInsulinRecord], atTimestamp: Date, now: Date) -> String {
        let matchingRecords = getMatchingCollapsedRecords(insulinRecords: insulinRecords, atTimestamp: atTimestamp)
        let matchingElapsed: [TimeInterval] = matchingRecords
            .map {
                return now.timeIntervalSince($0.timestamp)
            }
        let elapsed = matchingElapsed.reduce(0, +) / TimeInterval(matchingElapsed.count)
        let elapsedMinutes = Int(round(elapsed / 60))
        guard abs(elapsedMinutes) > 1 else {
            return ""
        }
        if matchingElapsed.count == 1 {
            return "\(elapsedMinutes)m"
        } else {
            return "~\(elapsedMinutes)m"
        }
    }
    
    private func getMgDl(forGlucoseRecords glucoseRecords: [OpenGluckGlucoseRecord], atTimestamp timestamp: Date) -> Int? {
        let sortedGlucoseRecords = glucoseRecords.sorted(by: { $0.timestamp < $1.timestamp })
        let justBefore = sortedGlucoseRecords.filter { $0.timestamp < timestamp }.last
        let justAfter = sortedGlucoseRecords.filter { $0.timestamp > timestamp }.first
        guard let justBefore else {
            return justAfter?.mgDl
        }
        guard let justAfter else {
            return justBefore.mgDl
        }
        let interval: TimeInterval = justAfter.timestamp.timeIntervalSince(justBefore.timestamp)
        let beforeMgDl = justBefore.mgDl
        let afterMgDl = justAfter.mgDl
        let pct: Double = timestamp.timeIntervalSince(justBefore.timestamp) / interval
        return Int(round(Double(beforeMgDl) + pct * Double(afterMgDl - beforeMgDl)))
    }
    
    public func getCollapsedItems(forInsulinRecords insulinRecords: [OpenGluckInsulinRecord], forGlucoseRecords glucoseRecords: [OpenGluckGlucoseRecord], now: Date) -> [Item] {
        var collapsed: [Item] = []
        if insulinRecords.contains(where: { $0.deleted }) {
            // we need to make sure we never handle with deleted records at this point
            // as we know we might have issues with getCollapsedItems and
            // isInsulinHiddenByPrevious failing to properly filtering
            // (we have added checks but this is important we don't get it wrong)
            fatalError("Unexpected to have deleted records at this point")
        }
        for insulinRecord in insulinRecords
            .filter({ !$0.deleted })
            .sorted(by: { $1.timestamp > $0.timestamp }) {
            guard !isInsulinHiddenByPrevious(insulinRecords: insulinRecords, atTimestamp: insulinRecord.timestamp) else {
                continue
            }
            let item = Item(
                timestamp: insulinRecord.timestamp,
                text: getCollapsedInsulinText(insulinRecords: insulinRecords, atTimestamp: insulinRecord.timestamp),
                textPlacement: .unknown,
                textAgo: getCollapsedInsulinAgoText(insulinRecords: insulinRecords, atTimestamp: insulinRecord.timestamp, now: now),
                mgDl: getMgDl(forGlucoseRecords: glucoseRecords, atTimestamp: insulinRecord.timestamp)
            )
            collapsed.append(item)
        }
        
        // loop through all items, and find the ones two old to display the text
        var itemsWithoutText: [Item] = []
        var itemsWithText: [Item] = []
        for i in collapsed.indices.reversed() {
            let item = collapsed[i]
            let elapsed = -item.timestamp.timeIntervalSince(now)
            if elapsed < GlucoseGraph.hideAgoForInsulinRecentThanInterval || elapsed > GlucoseGraph.hideAgoForInsulinOlderThanInterval {
                itemsWithoutText.append(.init(timestamp: item.timestamp, text: item.text, textPlacement: .hidden, textAgo: item.textAgo, mgDl: item.mgDl))
            } else {
                itemsWithText.append(.init(timestamp: item.timestamp, text: item.text, textPlacement: .primary, textAgo: item.textAgo, mgDl: item.mgDl))
            }
        }
        
        // hide all text that's neither the first nor the last
        if itemsWithText.count > 2 {
            for i in 1..<itemsWithText.count-1 {
                let item = itemsWithText[i]
                itemsWithText[i] = .init(timestamp: item.timestamp, text: item.text, textPlacement: .hidden, textAgo: item.textAgo, mgDl: item.mgDl)
            }
        }
        
        var result: [Item] = []
        result.append(contentsOf: itemsWithoutText)
        result.append(contentsOf: itemsWithText)
        result.sort(by: { $0.timestamp < $1.timestamp }) // sort by timestamp, ascending
        
        guard !result.isEmpty else { return result }
        
        // loop for each items, if there's any with text, and the next one is a lower mgDl, reverse the text to appear on top
        for i in 0..<result.count-1 {
            let item = result[i]
            guard item.textPlacement == .primary else {
                continue
            }
            let nextItem = result[i+1]
            if let itemMgDl = item.mgDl, let nextItemMgDl = nextItem.mgDl, itemMgDl > nextItemMgDl {
                result[i] = .init(timestamp: item.timestamp, text: item.text, textPlacement: .alternative, textAgo: item.textAgo, mgDl: item.mgDl)
            }
        }
        
        // loop for each items, if there's any with text, and the previous one is a lower mgDl, reverse the text to appear on top
        for i in 1..<result.count {
            let item = result[i]
            guard item.textPlacement == .primary else {
                continue
            }
            let previousItem = result[i-1]
            if let itemMgDl = item.mgDl, let previousItemMgDl = previousItem.mgDl, itemMgDl > previousItemMgDl {
                result[i] = .init(timestamp: item.timestamp, text: item.text, textPlacement: .alternative, textAgo: item.textAgo, mgDl: item.mgDl)
            }
        }
        
        return result
    }
}

fileprivate struct DownTriangleView: View {
    var body: some View {
        ZStack {
            Image(systemName: "arrowtriangle.down.fill")
                .foregroundColor(GlucoseGraphUI.fadeColor.opacity(0.5))
                .font(.system(size: 10))
//                .offset(x: 0, y: 3)
            Image(systemName: "arrowtriangle.down.fill")
                .foregroundColor(GlucoseGraphUI.systemGray2)
                .font(.system(size: 10))
                .offset(x: 0, y: -1)
//                .offset(x: 0, y: 2)
        }
    }
}

struct GlucoseGraphBackground: View {
#if os(iOS)
    static let systemGray4 = Color(cgColor: UIColor.systemGray4.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark)).cgColor)
    static let systemGray6 = Color(cgColor: UIColor.systemGray6.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark)).cgColor)
#else
    static let systemGray4 = Color(red: 28/256, green: 28/256, blue: 30/256)
    static let systemGray6 = Color(red: 58/256, green: 58/256, blue: 60/256)
#endif
    static let gradient: LinearGradient = .linearGradient(colors: [
        Self.systemGray6,
        Self.systemGray4
    ], startPoint: .bottom, endPoint: .top)
    var body: some View {
        Rectangle()
            .foregroundStyle(Self.gradient)
    }
}

struct GlucoseGraphImpl: View, Equatable {
#if !os(tvOS)
    @Environment(\.widgetRenderingMode) var widgetRenderingMode
#else
    let widgetRenderingMode: WidgetRenderingModePolyfill = .fullColor
#endif
//    @State var rerender: UUID = UUID()
    @State var angleLastToPreviousScanRecord: Double? = nil
    @State var trendLineLengthOnAXis: Double? = nil
    
    let now: Date
    let glucoseRecords: [OpenGluckGlucoseRecord]
    let insulinRecords: [OpenGluckInsulinRecord]
    let lowRecords: [OpenGluckLowRecord]
    let style: GlucoseGraph.Style
    let colorScheme: ColorScheme
    let showBackground: Bool
    
    static nonisolated func == (lhs: GlucoseGraphImpl, rhs: GlucoseGraphImpl) -> Bool {
        return lhs.now == rhs.now && lhs.glucoseRecords == rhs.glucoseRecords && lhs.insulinRecords == rhs.insulinRecords && lhs.lowRecords == rhs.lowRecords && lhs.style == rhs.style && lhs.colorScheme == rhs.colorScheme && lhs.showBackground == rhs.showBackground
    }
    
    var annotateAtMgDl: Int {
        switch style {
        case .normal:
#if os(watchOS)
            return 70
#else
            return 30
#endif
        case .small:
            return Int(round(0.32 * Double(maxMgDl + bonusMgDl)))
        }
    }
    
    var maxMgDlForAnnotation: Int {
#if os(iOS)
        return maxMgDl
#endif
#if os(watchOS)
        switch style {
        case .normal:
            return maxMgDl - 54
        case .small:
            return Int(round(0.45 * Double(maxMgDl + bonusMgDl)))
        }
#endif
#if os(tvOS)
        return maxMgDl
#endif
    }
    
    let annotateBottomAtMgDl = 32
    var bottomOfChartAtMgDl: Int { style == .normal ? -20 : 0 }
    var agoFont: Font { Font.system(size: style == .normal ? 11 : 10) }
    
    @Environment(\.redactionReasons) var redactionReasons
    
    let fadeColor: Color = GlucoseGraphUI.fadeColor
    let systemGray2: Color = GlucoseGraphUI.systemGray2
#if os(iOS)
    let labelColor = Color(cgColor: UIColor.label.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark)).cgColor)
    let systemGray = Color(cgColor: UIColor.systemGray.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark)).cgColor)
    let systemGray3 = Color(cgColor: UIColor.systemGray3.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark)).cgColor)
    let systemGray4 = Color(cgColor: UIColor.systemGray4.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark)).cgColor)
    let systemGray6 = Color(cgColor: UIColor.systemGray6.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark)).cgColor)
    let gray = Color(cgColor: UIColor.systemGray4.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark)).cgColor)
    let xAxisLineColor = Color(cgColor: UIColor.gray.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark)).cgColor)
    let secondarySystemBackground = Color(uiColor: .secondarySystemBackground)
#else
    let labelColor = Color.white
    let gray = Color.gray
    let systemGray = Color(red: 142/256, green: 142/256, blue: 147/256)
    let systemGray3 = Color(red: 72/256, green: 72/256, blue: 74/256)
    let systemGray4 = Color(red: 28/256, green: 28/256, blue: 30/256)
    let systemGray6 = Color(red: 58/256, green: 58/256, blue: 60/256)
    let xAxisLineColor = Color.gray
    let secondarySystemBackground = Color(red: 28/256, green: 28/256, blue: 30/256)
#endif
    
    
    enum GraphRecordType: String, Plottable {
        case unknown
        case historic
        case scan
        static func fromRecordType(_ value: String?) -> GraphRecordType {
            if value == "historic" {
                return .historic
            } else if value == "scan" {
                return .scan
            } else {
                return .unknown
            }
        }
    }
    
    enum GlucoseRange: String, Plottable {
        case low
        case normal
        case high
        case veryHigh
        
        static func from(mgDl: Double) -> GlucoseRange {
            if mgDl < OGUI.thresholdNormalLow {
                return .low
            } else if mgDl <= OGUI.thresholdNormalHigh {
                return .normal
            } else if mgDl > OGUI.thresholdHighVeryHigh {
                return .veryHigh
            } else {
                return .high
            }
        }
        
        var color: Color {
            switch self {
            case GlucoseRange.low: OGUI.lowColor
            case GlucoseRange.normal: OGUI.normalColor
            case GlucoseRange.high: OGUI.highColor
            case GlucoseRange.veryHigh: OGUI.veryHighColor
            }
        }
    }
    
    private func previousHour(_ date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour], from: date)
        return calendar.date(from: components) ?? date
    }
    
    private func nextHour(_ date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour], from: date)
        let nextHour = components.hour! + 1
        let nextHourDate = calendar.date(from: DateComponents(year: components.year, month: components.month, day: components.day, hour: nextHour, minute: 0, second: 0))!
        return nextHourDate
    }
    
    func getHours(from startDate: Date, to endDate: Date) -> [Date] {
        var dates = [Date]()
        let calendar = Calendar.current
        var startDate = previousHour(startDate)
        while startDate <= previousHour(endDate) {
            let hour = calendar.date(bySettingHour: calendar.component(.hour, from: startDate), minute: 0, second: 0, of: startDate)!
            dates.append(hour)
            startDate = calendar.date(byAdding: .hour, value: 1, to: startDate)!
        }
        return dates
    }
    
    private func dateToString(_ date: Date) -> String {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
#if os(watchOS)
        return "\(hour)"
#else
        return "\(hour):00"
#endif
    }
    
    private func elapsedToString(_ elapsed: Double) -> String {
        let hours = Int(round(abs(elapsed))) / 3600
        guard hours > 0 else {
            return ""
        }
        return "\(hours)h"
    }
    
    private struct CachedOGUIColorGetter {
        // we cache the thresholds so as not to hammer SwiftUI with reading from app storage
        
        private let thresholdNormalLow: Double
        private let thresholdNormalHigh: Double
        private let thresholdLow: Double
        private let thresholdHigh: Double
        private let thresholdHighVeryHigh: Double
        
        private let lowColor: Color
        private let normalColor: Color
        private let veryHighColor: Color
        private let highColor: Color
        
        init() {
            thresholdNormalLow = OGUI.thresholdNormalLow
            thresholdNormalHigh = OGUI.thresholdNormalHigh
            thresholdLow = OGUI.thresholdLow
            thresholdHigh = OGUI.thresholdHigh
            thresholdHighVeryHigh = OGUI.thresholdHighVeryHigh
            lowColor = OGUI.lowColor
            normalColor = OGUI.normalColor
            veryHighColor = OGUI.veryHighColor
            highColor = OGUI.highColor
        }
        
        func getLineColor(mgDl: Double) -> Color {
            if mgDl < thresholdNormalLow {
                return lowColor
            } else if mgDl <= thresholdNormalHigh {
                return normalColor
            } else if mgDl > thresholdHighVeryHigh {
                return veryHighColor
            } else {
                return highColor
            }
        }
    }
    
    static func getLinearGradient(_ values: [(TimeInterval, Double)]) -> Gradient {
        let colorGetter = CachedOGUIColorGetter()
        let gradientFadeFactor = 0.005 // how much we fade between two colors, Double.ulpOfOne = no fade
        
        let values = values.sorted(by: { $0.0 < $1.0 })
        guard let first = values.first, let last = values.last else { return Gradient(stops: [] )}
        var stops: [Gradient.Stop] = []
        
        // find the cutoff points
        let totalDuration: TimeInterval = last.0 - first.0
        var lastColor: Color = colorGetter.getLineColor(mgDl: first.1)
        var lastMgDl: Double = first.1
        var lastTimestamp: Double = first.0
        stops.append(.init(color: lastColor, location: 0))
        
        for (timestamp, mgDl) in values[1..<values.count] {
            let elapsed = timestamp - lastTimestamp
            
            for delta in stride(from: 0, through: elapsed, by: 1) {
                let now = lastTimestamp + delta
                let location = (now - first.0) / totalDuration
                let color = colorGetter.getLineColor(mgDl: lastMgDl + (mgDl - lastMgDl) * (delta / elapsed))
                if color != lastColor {
                    stops.append(.init(color: lastColor, location: max(0, location - gradientFadeFactor)))
                    stops.append(.init(color: color, location: min(1, location + gradientFadeFactor)))
                    lastColor = color
                }
            }
            lastMgDl = mgDl
            lastTimestamp = timestamp
        }
        
        stops.append(.init(color: lastColor, location: 1))
        stops.sort(by: { $0.location < $1.location })
        return Gradient(stops: stops)
    }
    
    @ChartContentBuilder
    private var linePoint: some ChartContent {
        let historicGradient = Self.getLinearGradient(
            glucoseRecords
                .filter { $0.recordType == "historic" }
                .map { ($0.timestamp.timeIntervalSince1970, Double($0.mgDl) )}
        )
        let sortedGlucoseRecords: [OpenGluckGlucoseRecord] = glucoseRecords.sorted(by: { $0.timestamp < $1.timestamp })
        let sortedScanRecords = sortedGlucoseRecords.filter { $0.recordType == "scan" }
        let lastScanRecord: OpenGluckGlucoseRecord? = sortedScanRecords.count >= 2 ? sortedScanRecords[sortedScanRecords.count - 1] : nil
        ForEach(sortedGlucoseRecords, id: \.self) {
            if $0.recordType == "scan" {
                let isLast = $0.timestamp == lastScanRecord?.timestamp
                PointMark(
                    x: .value("Timestamp", $0.timestamp),
                    y: .value("BG", $0.mgDl)                    )
                .foregroundStyle(GlucoseRange.from(mgDl: Double($0.mgDl)).color)
                .symbol(.cross)
                .symbolSize(0)
                .annotation(position: .overlay, alignment: .center, spacing: 0) {
                    ZStack {
                        if isLast, let angleLastToPreviousScanRecord, let trendLineLengthOnAXis {
#if os(watchOS)
                            let colorStart: Color =  .white.opacity(0.6)
                            let colorEnd: Color = .white.opacity(0.05)
#else
                            let colorStart: Color = .white.opacity(0.3)
                            let colorEnd: Color = .white.opacity(0)
#endif
                            Rectangle()
                                .position(x: trendLineLengthOnAXis, y: 5)
                                .rotationEffect(.radians(Double.pi + angleLastToPreviousScanRecord))
                                .frame(width: trendLineLengthOnAXis, height: 10)
                                .foregroundStyle(.linearGradient(colors: [
                                    colorStart,
                                    colorEnd
                                ], startPoint: .leading, endPoint: .trailing))
                        }
                    }
                    .frame(height: 20)
                }
            }
        }
        ForEach(sortedGlucoseRecords, id: \.self) {
            if $0.recordType == "historic" {
                LineMark(
                    x: .value("Timestamp", $0.timestamp),
                    y: .value("BG", $0.mgDl),
                    series: .value("Series", "Value")
                )
                .lineStyle(StrokeStyle(lineWidth: 5, lineCap: .round))
                .foregroundStyle(.linearGradient(historicGradient, startPoint: .leading, endPoint: .trailing))
                LineMark(
                    x: .value("Timestamp", $0.timestamp),
                    y: .value("BG", $0.mgDl),
                    series: .value("Series", "Background")
                )
                .foregroundStyle(fadeColor.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 4, lineCap: .round))
                LineMark(
                    x: .value("Timestamp", $0.timestamp),
                    y: .value("BG", $0.mgDl),
                    series: .value("Series", "Background")
                )
                .foregroundStyle(fadeColor.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                //                    .blur(radius: 1)
            }
            if $0.recordType == "scan" {
                let color: Color = GlucoseRange.from(mgDl: Double($0.mgDl)).color
                PointMark(
                    x: .value("Timestamp", $0.timestamp),
                    y: .value("BG", $0.mgDl)                    )
                .foregroundStyle(GlucoseRange.from(mgDl: Double($0.mgDl)).color)
                .symbol(.cross)
                .symbolSize(0)
                .annotation(position: .overlay, alignment: .center, spacing: 0) {
                    ZStack {
                        Image(systemName: "cross.fill")
                            .foregroundStyle(color)
                            .rotationEffect(.degrees(45))
                            .font(.system(size: 10, weight: .bold))
                        Image(systemName: "cross.fill")
                            .foregroundStyle(.white.opacity(0.5))
                            .rotationEffect(.degrees(45))
                            .font(.system(size: 9, weight: .bold))
                    }
                    .frame(height: 20)
                }
            }
        }
    }
    
    @ChartContentBuilder
    private var lows: some ChartContent {
#if os(watchOS)
        let circleDiameter: CGFloat = 17
#else
        let circleDiameter: CGFloat = 20
#endif
        let lowsRecords = lowRecords
            .filter { !$0.deleted }
            .sorted(by: { $0.timestamp < $1.timestamp })
        ForEach(lowRecords.filter { !$0.deleted }, id: \.self) {
            let isMostRecent = $0.id == lowsRecords.last?.id
            let timestamp = $0.timestamp
            let isSnoozed = abs($0.sugarInGrams) < Double.ulpOfOne
            let elapsed = -timestamp.timeIntervalSince(now)
            let elapsedMinutes = Int(round(elapsed / 60))
            let agoString = { () -> String? in
                if elapsed < GlucoseGraph.hideAgoForLowRecentThanInterval || elapsed > GlucoseGraph.hideAgoForLowOlderThanInterval || !isMostRecent {
                    return nil
                } else {
                    return OpenGluckManager.minutesToText(elapsedMinutes: elapsedMinutes)
                }
            }()
            
            if !isSnoozed {
                RuleMark(x: .value("Minutes", timestamp))
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                    .foregroundStyle(.linearGradient(
                        colors: [OGUI.lowColor, OGUI.lowColor, OGUI.lowColor.opacity(0), OGUI.lowColor.opacity(0)],
                        startPoint: .bottom, endPoint: .top))
            }
            PointMark(
                x: .value("Minutes", timestamp),
                y: .value("Predicted", annotateAtMgDl)
            )
            .symbol(.cross)
            .annotation(position: .top, alignment: .center, spacing: 0) {
                ZStack {
                    VStack(spacing: 0) {
                        if let agoString {
                            switch widgetRenderingMode {
                            case .fullColor:
                                Text(agoString)
                                    .padding(2)
                                    .background(isSnoozed ? Color(uiColor: .darkGray) : OGUI.lowColor)
                                    .foregroundColor(OGUI.lowColorText)
                                    .clipShape(RoundedRectangle(cornerRadius: 4.0, style: .continuous))
                                    .font(agoFont)
                                    .offset(x: 0, y: 1)
                            default:
                                Text(agoString)
                                    .padding(2)
                                    .clipShape(RoundedRectangle(cornerRadius: 4.0, style: .continuous))
                                    .font(agoFont)
                                    .offset(x: 0, y: -1)
                            }
                        }
                        if widgetRenderingMode == .fullColor {
                            LowIconFill(isSnoozed: isSnoozed, isActive: true)
                                .frame(width: circleDiameter, height: circleDiameter)
                            
                        } else {
                            ZStack {
                                LowIconFill(isSnoozed: isSnoozed, isActive: true)
                            }
                            .frame(width: 17, height: 17)
                        }
                    }
                }
                .foregroundColor(OGUI.lowColorText)
                .offset(x: 0, y: 25)
                
            }
            .symbolSize(0)
            
        }
    }
    
    @ChartContentBuilder
    private var insulinUnits: some ChartContent {
        let insulinCollapser = InsulinCollapser(collapseInsulinUnitsInterval: style == .normal ? 15*60 : 26*60)
        ForEach(insulinCollapser.getCollapsedItems(forInsulinRecords: insulinRecords, forGlucoseRecords: glucoseRecords, now: now), id: \.self) { item in
            let timestamp = item.timestamp
            let collapsedInsulinText = item.text
            let mgDl = item.mgDl ?? annotateAtMgDl
            
            let textAgo: String? = {
                if item.textPlacement == .hidden {
                    return nil
                }
                return item.textAgo
            }()
            
            PointMark(
                x: .value("Timestamp", timestamp),
                y: .value("mg/dL", min(mgDl, maxMgDlForAnnotation))
            )
            .symbol(.asterisk)
            .annotation(position: .top, alignment: .center, spacing: 12.0) {
                VStack(spacing: 0) {
                    if style == .normal, let textAgo {
                        switch widgetRenderingMode {
                        case .fullColor:
                            Text(item.textPlacement == .alternative ? textAgo : " ")
                                .padding(.horizontal, 2)
                                .background(systemGray2.opacity(
                                    item.textPlacement == .alternative ? 1.0 : 0.0
                                ))
                                .foregroundColor(OGUI.lowColorText)
                                .clipShape(RoundedRectangle(cornerRadius: 4.0, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(fadeColor.opacity(item.textPlacement == .alternative ? 0.5 : 0.0), lineWidth: 0.5)
                                )
                                .font(agoFont)
                                .offset(x: 0, y: -4)
                        default:
                            Text(item.textPlacement == .alternative ? textAgo : " ")
                                .padding(.horizontal, 2)
                                .font(agoFont)
                                .offset(x: 0, y: -4)
                        }
                    }
                    HStack {
                        Spacer()
                        switch widgetRenderingMode {
                        case .fullColor:
                            VStack {
                                Text(collapsedInsulinText)
                                    .font(.system(size: 12))
                                    .foregroundColor(labelColor)
                            }
                            .padding(3)
                            .background(systemGray2)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(fadeColor.opacity(0.5), lineWidth: 0.5)
                            )
                        default:
                            VStack {
                                Text(collapsedInsulinText)
                                    .font(.system(size: 12))
                            }
                            .padding(4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(OGUI.lowColorText.opacity(0.5), lineWidth: 0.5)
                            )
                        }
                        Spacer()
                    }
#if !os(tvOS)
                    .frame(width: 100)
#endif
                    .padding(-4)
                    if let textAgo {
                        switch widgetRenderingMode {
                        case .fullColor:
                            Group {
                                if item.textPlacement == .primary || style != .normal {
                                    Text(textAgo)
                                } else {
                                    DownTriangleView()
                                        .offset(x: 0, y: -1)
                                }
                            }
                            .padding(.horizontal, 2)
                            .background(systemGray2.opacity(
                                item.textPlacement == .primary || style != .normal ? 1.0 : 0.0
                            ))
                            .foregroundColor(OGUI.lowColorText)
                            .clipShape(RoundedRectangle(cornerRadius: 4.0, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(fadeColor.opacity(item.textPlacement == .primary || style != .normal ? 0.5 : 0.0), lineWidth: 0.5)
                            )
                            .font(agoFont)
                            .offset(x: 0, y: 3)
                        default:
                            Group {
                                if item.textPlacement == .primary || style != .normal {
                                    Text(textAgo)
                                } else {
                                    DownTriangleView()
                                        .offset(x: 0, y: -1)
                                }
                            }
                            .padding(.horizontal, 2)
                            .font(agoFont)
                            .offset(x: 0, y: 3)
                        }
                    } else {
                        DownTriangleView()
                            .offset(x: 0, y: 3)
                    }
                }
            }
            .symbolSize(0)
        }
    }
    
    struct NowShape: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: (rect.maxY - rect.minY) / 2 + rect.minY))
            path.closeSubpath()
            return path
        }
    }
    
    var maxMgDl: Int {
        let showMgDl: Int
        switch style {
        case .normal:
            showMgDl = 350
        case .small:
            showMgDl = 250
        }
        return max(showMgDl, glucoseRecords.map { $0.mgDl }.max() ?? 0)
    }
    
    var bonusMgDl: Int {
        let bonusMgDl: Int
        switch style {
        case .normal:
            bonusMgDl = 0
        case .small:
#if os(watchOS)
            bonusMgDl = 100
#else
            bonusMgDl = 0
#endif
        }
        return bonusMgDl
    }
    
    //        var bodyDebug: some View {
    //            List {
    //                ForEach(insulinRecords, id: \.self) { record in
    //                    HStack {
    //                        Text("\(record.deleted ? "Deleted" : "OK")")
    //                        Text("\(record.timestamp.formatted(date: .numeric, time: .shortened))")
    //                        Text("\(record.units)")
    //                    }
    //                }
    //            }
    //        }
    
    private func filterDuplicateRecords(_ records: [OpenGluckGlucoseRecord]) -> [OpenGluckGlucoseRecord] {
        guard let last = records.last else { return [] }
        let allButLast = records[0..<records.count - 1]
        let filtered: [OpenGluckGlucoseRecord] = allButLast.filter {
            -$0.timestamp.timeIntervalSince(last.timestamp) > TimeInterval(60)
        } + [last]
        return filtered
    }
    
    @ViewBuilder
    var body: some View {
        let _ = Self._printChanges()
        let minTimestamp = now.addingTimeInterval(-GlucoseGraph.maxLookbehindInterval)
        let maxTimestamp = now
//        if rerender.uuidString.isEmpty {} // force re-render on appear, to make sure thresholds are OK
        Chart {
#if os(watchOS)
            let rectangleMarkBottom = bottomOfChartAtMgDl-60
#endif
#if os(iOS)
            let rectangleMarkBottom = bottomOfChartAtMgDl-30
#endif
#if os(tvOS)
            let rectangleMarkBottom = bottomOfChartAtMgDl-60
#endif
            RectangleMark(x: .value("Now", now), yStart: .value("", rectangleMarkBottom), yEnd: .value("", maxMgDl), width: 2)
                .foregroundStyle(GlucoseGraph.nowColor)
            RectangleMark(
                xStart: .value("Time start", minTimestamp),
                xEnd: .value("Time end", maxTimestamp),
                yStart: .value("Normal Low", OGUI.thresholdNormalLow),
                yEnd: .value("Normal High", OGUI.thresholdNormalHigh)
            )
            .foregroundStyle(Color({ () -> UIColor in
                var color = UIColor(Color(cgColor: OGUI.normalColor.cgColor!))
                let shiftBrightness = 0.2
                let shiftSaturation = 1.3
                let shiftAlpha = 3.0
                var H: CGFloat = 0, S: CGFloat = 0, B: CGFloat = 0, A: CGFloat = 0
                if color.getHue(&H, saturation: &S, brightness: &B, alpha: &A) {
                    //                        B += (shiftBrightness - 1.0)
                    B /= shiftBrightness
                    S /= shiftSaturation
                    A /= shiftAlpha
                    B = max(min(B, 1.0), 0.0)
                    S = max(min(S, 1.0), 0.0)
                    A = max(min(A, 1.0), 0.0)
                    color = UIColor(hue: H, saturation: S, brightness: B, alpha: A)
                }
                return color
            }()))
            //                .foregroundStyle(OGUI.normalColor.opacity(0.35))
            if style != .small || !redactionReasons.contains(.privacy) {
                linePoint
                insulinUnits
                lows
            }
        }
        //            .chartForegroundStyleScale([
        //                GlucoseRange.low: OGUI.lowColor,
        //                GlucoseRange.normal: OGUI.normalColor,
        //                GlucoseRange.high: OGUI.highColor,
        //                GlucoseRange.veryHigh: OGUI.veryHighColor,
        //            ])
        .chartOverlay { proxy in
            let sortedGlucoseRecords: [OpenGluckGlucoseRecord] = glucoseRecords.sorted(by: { $0.timestamp < $1.timestamp })
            
            let sortedScanRecords = filterDuplicateRecords(sortedGlucoseRecords.filter { $0.recordType == "scan" })
            // sometimes we have two scan records in the same minute; keep only the last
            let _ = {
                if sortedScanRecords.count < 2 {
                    Task {
                        angleLastToPreviousScanRecord = nil
                        trendLineLengthOnAXis = nil
                    }
                } else {
                    let firstScanRecord: OpenGluckGlucoseRecord = sortedScanRecords[0]
                    let lastScanRecord: OpenGluckGlucoseRecord = sortedScanRecords[sortedScanRecords.count - 1]
                    let previousToLastScanRecord: OpenGluckGlucoseRecord = sortedScanRecords[sortedScanRecords.count - 2]
                    
                    if
                        let x0 = proxy.position(forX: firstScanRecord.timestamp),
                        let x1 = proxy.position(forX: previousToLastScanRecord.timestamp),
                        let x2 = proxy.position(forX: lastScanRecord.timestamp),
                        let y0 = proxy.position(forY: firstScanRecord.mgDl),
                        let y1 = proxy.position(forY: previousToLastScanRecord.mgDl),
                        let y2 = proxy.position(forY: lastScanRecord.mgDl) {
                        let spanX = x2 - x0
                        let spanY = y2 - y0
                        let dx = x2 - x1
                        let dy = y2 - y1
                        let angle = atan2(dy, dx)
                        var newTrendLineLengthOnAXis = sqrt(spanX * spanX + spanY * spanY)
                        newTrendLineLengthOnAXis *= newTrendLineLengthOnAXis / spanX
                        newTrendLineLengthOnAXis *= 4
                        Task {
                            angleLastToPreviousScanRecord = angle
                            trendLineLengthOnAXis = newTrendLineLengthOnAXis
                        }
                    }
                }
            }()
            Rectangle().fill(.clear).contentShape(Rectangle())
        }
        .chartLegend(.hidden)
        .chartXScale(domain: minTimestamp...maxTimestamp)
        .chartYScale(domain: bottomOfChartAtMgDl...maxMgDl+bonusMgDl)
        .chartYAxis {
            AxisMarks(values: .stride(by: 50)) { value in
                // skip showing label for mgDl == 0
                if let mgDl = value.as(Int.self), mgDl > 0, mgDl <= maxMgDl {
                    if mgDl % 100 == 0 {
                        AxisValueLabel {
                            switch style {
                            case .normal:
                                if mgDl > 0 {
                                    Text(BloodGlucose.localize(mgDl, style: BloodGlucose.Style.short))
                                        .foregroundColor(labelColor)
                                }
                            case .small:
                                Text("     ")
                            }
                        }
                        
                        AxisGridLine(stroke: StrokeStyle(dash: [3, 5]))
                        AxisTick(stroke: StrokeStyle(lineWidth: 1.5))
                    } else {
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 5]))
#if !os(watchOS)
                        AxisTick(stroke: StrokeStyle(lineWidth: 0.5))
#endif
                    }
                }
            }
        }
        .chartXAxis {
            let gridLinesIntervals: [TimeInterval] = [-60*60, -2*60*60, -3*60*60, -4*60*60]
            let gridLines: [Date] = gridLinesIntervals.map { now.addingTimeInterval($0) }
            AxisMarks(preset: .aligned, values: gridLines) { value in
                if let date = value.as(Date.self) {
                    let elapsed = date.timeIntervalSince(now)
                    AxisGridLine(centered: true, stroke: StrokeStyle(lineWidth: 0.4))
                        .foregroundStyle(xAxisLineColor)
                    AxisValueLabel {
                        Text("\(elapsedToString(elapsed))")
                            .foregroundColor(labelColor)
                    }
                }
            }
        }
        .chartBackground { _ in
            switch widgetRenderingMode {
            case .fullColor:
                if showBackground {
                    GlucoseGraphBackground()
                }
            default:
                EmptyView()
            }
        }
    }
}

struct GlucoseGraph: View {
    enum Style {
        case normal
        case small
    }
    
    let now: Date
    @Binding var glucoseRecords: [OpenGluckGlucoseRecord]
    @Binding var insulinRecords: [OpenGluckInsulinRecord]
    @Binding var lowRecords: [OpenGluckLowRecord]
    @State var style: Style = .normal
    var showBackground: Bool = true
    
    @Environment(\.colorScheme) var colorScheme
    
    static let maxLookbehindInterval: TimeInterval = 4.5*60.0*60.0
    static let hideAgoForLowOlderThanInterval: TimeInterval = 60*60
    static let hideAgoForLowRecentThanInterval: TimeInterval = 60
    static let hideAgoForInsulinOlderThanInterval: TimeInterval = 90*60
    static let hideAgoForInsulinRecentThanInterval: TimeInterval = 90
    static let alternateTextPlacementForInsulinNearInterval: TimeInterval = 45 * 60
    
    static let nowColor = Color(red: 0.6, green: 0.6, blue: 0.6)
    
    private func filteredGlucoseRecords(forDate date: Date) -> [OpenGluckGlucoseRecord] {
        let minTimestamp = date.addingTimeInterval(-GlucoseGraph.maxLookbehindInterval)
        return glucoseRecords.filter {
            $0.timestamp > minTimestamp
        }
    }
    
    private func filteredInsulinRecords(forDate date: Date) -> [OpenGluckInsulinRecord] {
        let minTimestamp = date.addingTimeInterval(-GlucoseGraph.maxLookbehindInterval)
        return insulinRecords.filter {
            !$0.deleted &&
            $0.timestamp > minTimestamp
        }
    }
    
    private func filteredLowRecords(forDate date: Date) -> [OpenGluckLowRecord] {
        let minTimestamp = date.addingTimeInterval(-GlucoseGraph.maxLookbehindInterval)
        return lowRecords.filter {
            $0.timestamp > minTimestamp
        }
    }
    
    var body: some View {
        // round Date() at the start of the current minute, that is at time 10:01:40 it will return 10:01:00
        let now: Date = Date(timeIntervalSince1970: ceil(now.timeIntervalSince1970 / 60) * 60)
        GlucoseGraphImpl(
            now: now,
            glucoseRecords: filteredGlucoseRecords(forDate: now),
            insulinRecords: filteredInsulinRecords(forDate: now),
            lowRecords: filteredLowRecords(forDate: now),
            style: style,
            colorScheme: colorScheme,
            showBackground: showBackground
        )
        .equatable()
    }
}

struct GlucoseGraph_Previews: PreviewProvider {
    struct EmptyPreview: View {
        var body: some View {
            let glucoseRecords: [OpenGluckGlucoseRecord] = []
            let lowRecords: [OpenGluckLowRecord] = []
            let insulinRecords: [OpenGluckInsulinRecord] = []
            
            GlucoseGraph(now: Date(), glucoseRecords: .constant(glucoseRecords), insulinRecords: .constant(insulinRecords), lowRecords: .constant(lowRecords))
        }
    }
    
    struct Preview: View {
        @State var style: GlucoseGraph.Style = .normal
        
        var body: some View {
            let glucoseRecords: [OpenGluckGlucoseRecord] = [
                OpenGluckGlucoseRecord(timestamp: Date().addingTimeInterval(-3 * 60 * 60), mgDl: 130, recordType: "scan"),
                OpenGluckGlucoseRecord(timestamp: Date().addingTimeInterval(-6 * 60 * 60), mgDl: 350, recordType: "historic"),
                OpenGluckGlucoseRecord(timestamp: Date().addingTimeInterval(-50 * 60), mgDl: 280, recordType: "historic"),
                OpenGluckGlucoseRecord(timestamp: Date().addingTimeInterval(-22 * 60), mgDl: 160, recordType: "historic"),
                OpenGluckGlucoseRecord(timestamp: Date().addingTimeInterval(-17 * 60), mgDl: 150, recordType: "historic"),
                OpenGluckGlucoseRecord(timestamp: Date().addingTimeInterval(-12 * 60), mgDl: 120, recordType: "historic"),
                OpenGluckGlucoseRecord(timestamp: Date().addingTimeInterval(-5 * 60), mgDl: 110, recordType: "scan"),
                OpenGluckGlucoseRecord(timestamp: Date().addingTimeInterval(0 * 60), mgDl: 130, recordType: "scan")
            ]
            let lowRecords: [OpenGluckLowRecord] = [
                .init(id: UUID(), timestamp: Date().addingTimeInterval(-108*60), sugarInGrams: 0, deleted: false),
                .init(id: UUID(), timestamp: Date().addingTimeInterval(-62*60), sugarInGrams: 10, deleted: false),
                .init(id: UUID(), timestamp: Date().addingTimeInterval(-2*60), sugarInGrams: 20, deleted: false)
            ]
            let insulinRecords: [OpenGluckInsulinRecord] = [
                .init(id: UUID(), timestamp: Date().addingTimeInterval(-105*60), units: 2, deleted: false),
                .init(id: UUID(), timestamp: Date().addingTimeInterval(-100*60), units: 2, deleted: false),

                // FIXME why does one unit disappeared?
                .init(id: UUID(), timestamp: Date().addingTimeInterval(-35*60), units: 2, deleted: false),
                .init(id: UUID(), timestamp: Date().addingTimeInterval(-20*60), units: 2, deleted: false),
                .init(id: UUID(), timestamp: Date().addingTimeInterval(-5*60), units: 3, deleted: false),
            ]
            GlucoseGraph(now: Date(), glucoseRecords: .constant(glucoseRecords), insulinRecords: .constant(insulinRecords), lowRecords: .constant(lowRecords), style: style)
                .frame(maxHeight: 200)
        }
    }
    
    #if false
    // LATER FIXME can't show live previews on widget
    struct LivePreview: View {
        @EnvironmentObject var openGlückEnvironment: OpenGluckEnvironment

        var body: some View {
            GlucoseGraph(
                glucoseRecords: .constant(openGlückEnvironment.lastGlucoseRecords ?? []),
                insulinRecords: .constant(openGlückEnvironment.lastInsulinRecords ?? []),
                lowRecords: .constant(openGlückEnvironment.lastLowRecords ?? [])
            )
        }
    }
    #endif

    static var previews: some View {
        Preview()
#if os(watchOS)
            .frame(maxHeight: 100)
#endif
            .preferredColorScheme(.dark)
            .previewDisplayName("Mock Data")
        EmptyPreview()
        Preview(style: .small)
#if os(watchOS)
            .frame(maxHeight: 45)
            .padding(.top, 25)
#endif
            .preferredColorScheme(.dark)
            .previewDisplayName("Mock Data Small")
        EmptyPreview()
#if os(watchOS)
            .frame(maxHeight: 100)
#endif
            .preferredColorScheme(.dark)
            .previewDisplayName("Empty Mock Data")

#if false
        // LATER FIXME can't show live previews on widget
        OpenGluckEnvironmentUpdaterView {
            LivePreview()
        }
#if os(watchOS)
        .frame(maxHeight: 100)
#endif
        .preferredColorScheme(.dark)
        .environmentObject(OpenGluckConnection())
        .previewDisplayName("Live Data")
#endif
    }
}
