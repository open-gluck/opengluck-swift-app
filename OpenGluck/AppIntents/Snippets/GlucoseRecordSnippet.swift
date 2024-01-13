import SwiftUI
import OG

struct GlucoseRecordSnippet: View {
    let glucoseRecord: OpenGluckGlucoseRecord
    var body: some View {
        RecordSnippet {
            GlucoseRecordView(glucoseRecord: .constant(glucoseRecord))
                .font(.title2)
        }
    }
}

#Preview("123") {
    GlucoseRecordSnippet(glucoseRecord: OpenGluckGlucoseRecord(timestamp: Date().addingTimeInterval(-6*60), mgDl: 123, recordType: "scan"))
}
