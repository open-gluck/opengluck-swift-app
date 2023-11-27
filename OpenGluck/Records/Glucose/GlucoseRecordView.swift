import SwiftUI
import OG
import OGUI

struct GlucoseRecordView: View {
    @Binding var glucoseRecord: OpenGluckGlucoseRecord

    var body: some View {
        HStack {
            BloodGlucose(mgDl: Double(glucoseRecord.mgDl))
            Spacer()
            TimestampView(mode: .minutesToText, timestamp: .constant(glucoseRecord.timestamp))
        }
        //.foregroundColor(.yellow)
        .foregroundColor(OGUI.glucoseColor(mgDl: Double(glucoseRecord.mgDl)))
    }
}

struct GlucoseRecordView_Previews: PreviewProvider {
    static var previews: some View {
        GlucoseRecordView(glucoseRecord: .constant(OpenGluckGlucoseRecord(timestamp: Date().addingTimeInterval(-(42+60)*60), mgDl: 50)))
            .previewDisplayName("50+old")
        GlucoseRecordView(glucoseRecord: .constant(OpenGluckGlucoseRecord(timestamp: Date().addingTimeInterval(-42*60), mgDl: 50)))
            .previewDisplayName("50")
        GlucoseRecordView(glucoseRecord: .constant(OpenGluckGlucoseRecord(timestamp: Date().addingTimeInterval(-42*60), mgDl: 120)))
            .previewDisplayName("120")
        GlucoseRecordView(glucoseRecord: .constant(OpenGluckGlucoseRecord(timestamp: Date().addingTimeInterval(-42*60), mgDl: 180)))
            .previewDisplayName("180")
        GlucoseRecordView(glucoseRecord: .constant(OpenGluckGlucoseRecord(timestamp: Date().addingTimeInterval(-42*60), mgDl: 260)))
            .previewDisplayName("260")
    }
}
