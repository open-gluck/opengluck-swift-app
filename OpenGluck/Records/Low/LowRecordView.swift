import SwiftUI
import OG
import OGUI

struct LowRecordView: View {
    let now: Date
    @Binding var lowRecord: OpenGluckLowRecord

    var body: some View {
        HStack {
            SnackGram(sugarInGrams: lowRecord.sugarInGrams)
            Spacer()
            TimestampView(now: now, mode: .minutesToText, timestamp: .constant(lowRecord.timestamp))
        }
        .foregroundColor(SnackGram.foregroundColor(forTimestamp: lowRecord.timestamp))
    }
}

struct LowRecordView_Previews: PreviewProvider {
    static var previews: some View {
        let now = Date()
        LowRecordView(now: now, lowRecord: .constant(OpenGluckLowRecord(id: UUID(), timestamp: Date().addingTimeInterval(-(42+60)*60), sugarInGrams: 1, deleted: false)))
            .previewDisplayName("1")
        LowRecordView(now: now, lowRecord: .constant(OpenGluckLowRecord(id: UUID(), timestamp: Date().addingTimeInterval(-42*60), sugarInGrams: 2, deleted: false)))
            .previewDisplayName("2")
        LowRecordView(now: now, lowRecord: .constant(OpenGluckLowRecord(id: UUID(), timestamp: Date().addingTimeInterval(-42*60), sugarInGrams: .pi, deleted: false)))
            .previewDisplayName("3.14")
        LowRecordView(now: now, lowRecord: .constant(OpenGluckLowRecord(id: UUID(), timestamp: Date().addingTimeInterval(-42*60), sugarInGrams: 10, deleted: false)))
            .previewDisplayName("10")
        LowRecordView(now: now, lowRecord: .constant(OpenGluckLowRecord(id: UUID(), timestamp: Date().addingTimeInterval(-42*60), sugarInGrams: 20, deleted: false)))
            .previewDisplayName("20")
    }
}
