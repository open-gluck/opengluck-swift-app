import SwiftUI
import OG
import OGUI

struct LowRecordView: View {
    @Binding var lowRecord: OpenGluckLowRecord

    var body: some View {
        HStack {
            SnackGram(sugarInGrams: lowRecord.sugarInGrams)
            Spacer()
            TimestampView(mode: .minutesToText, timestamp: .constant(lowRecord.timestamp))
        }
        .foregroundColor(SnackGram.foregroundColor(forTimestamp: lowRecord.timestamp))
    }
}

struct LowRecordView_Previews: PreviewProvider {
    static var previews: some View {
        LowRecordView(lowRecord: .constant(OpenGluckLowRecord(id: UUID(), timestamp: Date().addingTimeInterval(-(42+60)*60), sugarInGrams: 1, deleted: false)))
            .previewDisplayName("1")
        LowRecordView(lowRecord: .constant(OpenGluckLowRecord(id: UUID(), timestamp: Date().addingTimeInterval(-42*60), sugarInGrams: 2, deleted: false)))
            .previewDisplayName("2")
        LowRecordView(lowRecord: .constant(OpenGluckLowRecord(id: UUID(), timestamp: Date().addingTimeInterval(-42*60), sugarInGrams: .pi, deleted: false)))
            .previewDisplayName("3.14")
        LowRecordView(lowRecord: .constant(OpenGluckLowRecord(id: UUID(), timestamp: Date().addingTimeInterval(-42*60), sugarInGrams: 10, deleted: false)))
            .previewDisplayName("10")
        LowRecordView(lowRecord: .constant(OpenGluckLowRecord(id: UUID(), timestamp: Date().addingTimeInterval(-42*60), sugarInGrams: 20, deleted: false)))
            .previewDisplayName("20")
    }
}
