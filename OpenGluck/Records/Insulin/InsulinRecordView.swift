import SwiftUI
import OG
import OGUI

struct InsulinRecordView: View {
    let now: Date
    @Binding var insulinRecord: OpenGluckInsulinRecord

    var body: some View {
        HStack {
            InsulinUnit(units: insulinRecord.units)
            Spacer()
            TimestampView(now: now, mode: .minutesToText, timestamp: .constant(insulinRecord.timestamp))
        }
        .foregroundColor(InsulinUnit.foregroundColor(forTimestamp: insulinRecord.timestamp))
    }
}

struct InsulinRecordView_Previews: PreviewProvider {
    static var previews: some View {
        let now = Date()
        InsulinRecordView(now: now, insulinRecord: .constant(OpenGluckInsulinRecord(id: UUID(), timestamp: Date().addingTimeInterval(-(42+60)*60), units: 1, deleted: false)))
            .previewDisplayName("1")
        InsulinRecordView(now: now, insulinRecord: .constant(OpenGluckInsulinRecord(id: UUID(), timestamp: Date().addingTimeInterval(-42*60), units: 2, deleted: false)))
            .previewDisplayName("2")
        InsulinRecordView(now: now, insulinRecord: .constant(OpenGluckInsulinRecord(id: UUID(), timestamp: Date().addingTimeInterval(-42*60), units: 3, deleted: false)))
            .previewDisplayName("3")
        InsulinRecordView(now: now, insulinRecord: .constant(OpenGluckInsulinRecord(id: UUID(), timestamp: Date().addingTimeInterval(-42*60), units: 10, deleted: false)))
            .previewDisplayName("10")
        InsulinRecordView(now: now, insulinRecord: .constant(OpenGluckInsulinRecord(id: UUID(), timestamp: Date().addingTimeInterval(-42*60), units: 20, deleted: false)))
            .previewDisplayName("20")
    }
}
