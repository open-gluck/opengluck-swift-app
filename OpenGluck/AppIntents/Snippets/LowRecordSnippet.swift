import SwiftUI
import OG

struct LowRecordSnippet: View {
    let lowRecord: OpenGluckLowRecord
    var body: some View {
        RecordSnippet {
            LowRecordView(now: Date(), lowRecord: .constant(lowRecord))
                .font(.title)
                .strikethrough(lowRecord.deleted)
        }
    }
}

#Preview("Normal") {
    LowRecordSnippet(lowRecord: OpenGluckLowRecord(id: UUID(), timestamp: Date().addingTimeInterval(-6*60), sugarInGrams: 42, deleted: false))
}

#Preview("Deleted") {
    LowRecordSnippet(lowRecord: OpenGluckLowRecord(id: UUID(), timestamp: Date().addingTimeInterval(-6*60), sugarInGrams: 42, deleted: true))
}

