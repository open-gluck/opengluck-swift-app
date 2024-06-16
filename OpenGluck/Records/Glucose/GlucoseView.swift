import SwiftUI
import OG
import OGUI

struct GlucoseView: View {
    @Binding var glucoseRecord: OpenGluckGlucoseRecord
    @Binding var hasCgmRealTimeData: Bool?
    let font: Font
    let captionFont: Font
    
    enum Mode {
        case coloredBackground
        case transparent
        case vibrantAgo
        case vibrantAgoSmall
        case vibrant
    }
    let mode: Mode
    
    init(glucoseRecord: Binding<OpenGluckGlucoseRecord>, hasCgmRealTimeData: Binding<Bool?>, font: Font = .body, captionFont: Font = .caption, mode: Mode = .transparent) {
        self._glucoseRecord = glucoseRecord
        self._hasCgmRealTimeData = hasCgmRealTimeData
        self.font = font
        self.captionFont = captionFont
        self.mode = mode
    }
    
    private func tooOld(forDate date: Date) -> Bool {
        guard let hasCgmRealTimeData, hasCgmRealTimeData else {
            return false
        }

        let elapsed = glucoseRecord.timestamp.timeIntervalSince(date)
        let elapsedMinutes = Int(-elapsed / 60)

        return elapsedMinutes >= 30
    }
    
    private func backgroundColor(forDate date: Date) -> Color {
        guard !tooOld(forDate: date) else {
            return Color.gray
        }
        
        return OGUI.glucoseColor(mgDl: Double(glucoseRecord.mgDl))
    }
    
    private func foregroundColor(forDate date: Date) -> Color {
        guard !tooOld(forDate: date) else {
            return Color.gray
        }
        
        return OGUI.glucoseTextColor(mgDl: Double(glucoseRecord.mgDl))
    }
    
    @ViewBuilder var glucose: some View {
        Text(BloodGlucose.localize(glucoseRecord.mgDl, style: .short))
            .font(font)
    }
    
    @ViewBuilder func agoSmall(forDate date: Date) -> some View {
        HStack(spacing: 0) {
            TimestampView(mode: .minutesToText, timestamp: .constant(glucoseRecord.timestamp))
            if tooOld(forDate: date) {
                Text("⚠️")
            }
        }
        .font(captionFont)
    }
    
    @ViewBuilder func ago(forDate date: Date) -> some View {
        HStack(spacing: 0) {
            TimestampView(mode: .secondsToTextAgo, timestamp: .constant(glucoseRecord.timestamp))
            if tooOld(forDate: date) {
                Text("⚠️")
            }
        }
        .font(captionFont)
    }
    
    @ViewBuilder
    private func content(forDate date: Date) -> some View {
        VStack(spacing: 0) {
            if mode == .vibrantAgoSmall {
                agoSmall(forDate: date)
                glucose
            } else if mode == .vibrantAgo {
                ago(forDate: date)
                glucose
            } else {
                glucose
                ago(forDate: date)
            }
        }
        .padding(mode == .coloredBackground ? 20 : 0)
        .preferredColorScheme(.dark)
        .foregroundColor(mode == .vibrant || mode == .vibrantAgo ? nil : mode == .transparent ? backgroundColor(forDate: date) : foregroundColor(forDate: date))
        .background(mode != .coloredBackground ? Color.black.opacity(0) : backgroundColor(forDate: date))
    }
    
    var body: some View {
        TimelineView(.everyMinute) { context in
            if mode != .coloredBackground {
                content(forDate: context.date)
            } else {
                content(forDate: context.date)
                    .clipShape(Capsule())
            }
        }
    }
}

struct GlucoseView_Previews: PreviewProvider {
    static var previews: some View {
        GlucoseView(glucoseRecord: .constant(OpenGluckGlucoseRecord(timestamp: Date().addingTimeInterval(-300*60), mgDl: 123)), hasCgmRealTimeData: .constant(true))
            .previewDisplayName("Old")
        GlucoseView(glucoseRecord: .constant(OpenGluckGlucoseRecord(timestamp: Date().addingTimeInterval(-12*60), mgDl: 123)), hasCgmRealTimeData: .constant(true))
            .previewDisplayName("Normal")
        GlucoseView(glucoseRecord: .constant(OpenGluckGlucoseRecord(timestamp: Date().addingTimeInterval(-12*60), mgDl: 58)), hasCgmRealTimeData: .constant(true))
            .previewDisplayName("Low")
        GlucoseView(glucoseRecord: .constant(OpenGluckGlucoseRecord(timestamp: Date().addingTimeInterval(-12*60), mgDl: 190)), hasCgmRealTimeData: .constant(true), mode: .coloredBackground)
            .previewDisplayName("High, Colored")
        GlucoseView(glucoseRecord: .constant(OpenGluckGlucoseRecord(timestamp: Date().addingTimeInterval(-12*60), mgDl: 190)), hasCgmRealTimeData: .constant(true))
            .previewDisplayName("High")
        GlucoseView(glucoseRecord: .constant(OpenGluckGlucoseRecord(timestamp: Date().addingTimeInterval(-12*60), mgDl: 290)), hasCgmRealTimeData: .constant(true))
            .previewDisplayName("Very High")
    }
}
