import SwiftUI

struct TimestampView: View {
    @State var mode: Mode
    @Binding var timestamp: Date
    
    enum Mode {
        case minutesToText
        case secondsToTextAgo
    }

    struct Impl: View {
        var mode: Mode
        var timestamp: Date
        var date: Date
        @Environment(\.scenePhase) var scenePhase
        @State var rerender = UUID()
        
        var when: String {
            switch mode {
            case .minutesToText:
                return whenMinutesToText
            case .secondsToTextAgo:
                return whenSecondsToTextAgo
            }
        }
        
        private var elapsed: TimeInterval {
            timestamp.timeIntervalSince(date)
        }
        
        private var elapsedMinutes: Int {
            Int(-elapsed / 60)

        }
        
        private var whenMinutesToText: String {
            if elapsedMinutes < 60 {
                return OpenGluckManager.minutesToText(elapsedMinutes: elapsedMinutes)
            } else {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "H:mm"
                return dateFormatter.string(from: timestamp)
            }
        }
        
        private var whenSecondsToTextAgo: String {
            return OpenGluckManager.secondsToTextAgo(elapsed)
        }
        
        var body: some View {
            if rerender.uuidString != "" {
                Text(when)
                    .onChange(of: scenePhase) {
                        // not sure this is actually needed; we wanted to make sure we
                        // display the correct time when we move out Always On
                        rerender = UUID()
                    }
            }
        }
    }
    
    var body: some View {
        TimelineView(.everyMinute) { context in
            Impl(mode: mode, timestamp: timestamp, date: context.date)
        }
    }
}

struct TimestampView_Previews: PreviewProvider {
    static var previews: some View {
        TimestampView(mode: .minutesToText, timestamp: .constant(Date().addingTimeInterval(-55)))
            .previewDisplayName("minutesToText")
        TimestampView(mode: .secondsToTextAgo, timestamp: .constant(Date().addingTimeInterval(-55)))
            .previewDisplayName("secondsToTextAgo")
    }
}
