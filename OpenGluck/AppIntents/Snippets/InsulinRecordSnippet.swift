import SwiftUI
import OG

struct InsulinRecordSnippet: View {
    let insulinRecord: OpenGluckInsulinRecord
    var body: some View {
        RecordSnippet {
            InsulinRecordView(insulinRecord: .constant(insulinRecord))
                .font(.title)
                .strikethrough(insulinRecord.deleted)
        }
    }
}

#Preview("Normal") {
    InsulinRecordSnippet(insulinRecord: OpenGluckInsulinRecord(id: UUID(), timestamp: Date().addingTimeInterval(-3*60), units: 5, deleted: false))
}

#Preview("Deleted") {
    InsulinRecordSnippet(insulinRecord: OpenGluckInsulinRecord(id: UUID(), timestamp: Date().addingTimeInterval(-3*60), units: 5, deleted: true))
}

