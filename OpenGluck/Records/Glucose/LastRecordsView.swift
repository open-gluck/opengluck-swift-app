import SwiftUI

struct LastRecordsView: View {
    @EnvironmentObject var openGlückUpdater: OpenGluckEnvironment

    var body: some View {
        ForEach(openGlückUpdater.lastGlucoseRecords ?? [], id: \.self) { glucoseRecord in
            GlucoseRecordView(glucoseRecord: .constant(glucoseRecord))
        }
    }
}

struct LastRecordsView_Previews: PreviewProvider {
    static var previews: some View {
        OpenGluckEnvironmentUpdater {
            List {
                LastRecordsView()
            }
        }
            .environmentObject(OpenGluckConnection())
    }
}
