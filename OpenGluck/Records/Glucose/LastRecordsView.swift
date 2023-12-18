import SwiftUI
import OG

struct LastRecordsView: View {
    @EnvironmentObject var openGlückUpdater: OpenGluckEnvironment
    @EnvironmentObject var openGlückConnection: OpenGluckConnection
    #if os(iOS)
    @EnvironmentObject var appDelegate: PhoneAppDelegate
    private var sheetStatusOptions: SheetStatusViewOptions { appDelegate.sheetStatusOptions }
    #endif

    enum Record: Hashable, Identifiable {
        case glucose(id: UUID, glucoseRecord: OpenGluckGlucoseRecord)
        case insulin(id: UUID, insulinRecord: OpenGluckInsulinRecord)
        case low(id: UUID, lowRecord: OpenGluckLowRecord)
        
        var id: UUID {
            switch self {
            case .glucose(id: let id, _): id
            case .insulin(id: _, let insulinRecord): insulinRecord.id
            case .low(id: _, let lowRecord): lowRecord.id
            }
        }
        
        var timestamp: Date {
            switch self {
            case .glucose(_, glucoseRecord: let glucoseRecord): glucoseRecord.timestamp
            case .insulin(_, insulinRecord: let insulinRecord): insulinRecord.timestamp
            case .low(_, lowRecord: let lowRecord): lowRecord.timestamp
            }
        }
        
        func hash(into hasher: inout Hasher) {
            switch self {
            case .glucose(_, glucoseRecord: let glucoseRecord): glucoseRecord.hash(into: &hasher)
            case .insulin(_, insulinRecord: let insulinRecord): insulinRecord.hash(into: &hasher)
            case .low(_, lowRecord: let lowRecord): lowRecord.hash(into: &hasher)
            }
        }
    }
    
    @State var records: [Record] = []
    @State var hiddenIds: Set<UUID> = Set()
    
    private func update() {
        var result: [Record] = []
        for insulinRecord in openGlückUpdater.lastInsulinRecords ?? [] {
            if !insulinRecord.deleted {
                result.append(Record.insulin(id: UUID(), insulinRecord: insulinRecord))
            }
        }
        for glucoseRecord in openGlückUpdater.lastGlucoseRecords ?? [] {
            result.append(Record.glucose(id: UUID(), glucoseRecord: glucoseRecord))
        }
        for lowRecord in openGlückUpdater.lastLowRecords ?? [] {
            if !lowRecord.deleted {
                result.append(Record.low(id: UUID(), lowRecord: lowRecord))
            }
        }
        records = result
            .sorted(by: { $0.timestamp > $1.timestamp })
            .filter { !hiddenIds.contains($0.id) }
    }
    
    #if os(iOS)
    private func deleteRecord(_ record: Record) {
        sheetStatusOptions.state = SheetStatusViewState.inProgress
        sheetStatusOptions.status = "Deleting…"
        sheetStatusOptions.subStatus1 = "Launching Task…"
        Task {
            sheetStatusOptions.subStatus1 = "Deleting…"
            defer { sheetStatusOptions.state = SheetStatusViewState.complete }

            do {
                switch record {
                case .glucose(glucoseRecord: _): fatalError("Don't know how to delete glucose record")
                case .low(lowRecord: _): fatalError("Don't know how to delete low record")
                case .insulin(_, insulinRecord: let insulinRecord): try await deleteInsulinRecord(insulinRecord)
                }
                
                sheetStatusOptions.subStatus1 = "Done!"
                NotificationCenter.default.post(name: Notification.Name.refreshOpenGlück, object: nil)
            } catch {
                hiddenIds = Set()
                sheetStatusOptions.pushError(message: error.localizedDescription)
            }
        }
    }
    
    private func deleteInsulinRecord(_ insulinRecord: OpenGluckInsulinRecord) async throws {
        print("TODO delete \(insulinRecord.units)")
        guard let client = openGlückConnection.getClient() else {
            fatalError("No client")
        }
        let insulinRecords: [OpenGluckInsulinRecord] = [
            OpenGluckInsulinRecord(id: insulinRecord.id, timestamp: insulinRecord.timestamp, units: insulinRecord.units, deleted: true)
        ]
        _ = try await client.upload(insulinRecords: insulinRecords)
    }
    #endif

    var body: some View {
        ForEach(Array(records), id: \.id) { record in
            switch record {
            case .glucose(_, glucoseRecord: let glucoseRecord):
                GlucoseRecordView(glucoseRecord: .constant(glucoseRecord))
                    .deleteDisabled(true)
            case .insulin(_, insulinRecord: let insulinRecord):
                InsulinRecordView(insulinRecord: .constant(insulinRecord))
            case .low(_, lowRecord: let lowRecord):
                LowRecordView(lowRecord: .constant(lowRecord))
                    .deleteDisabled(true)
            }
        }
#if os(iOS)
        .onDelete(perform: { indexSet in
            let recordsToDelete: [Record] = indexSet.map { records[$0] }
            recordsToDelete.forEach { record in
                hiddenIds.insert(record.id)
                deleteRecord(record)
            }
        })
#endif
        .onReceive(openGlückUpdater.$revision) { _ in
            withAnimation {
                update()
            }
        }
    }
}

struct LastRecordsView_Previews: PreviewProvider {
    static var previews: some View {
        OpenGluckEnvironmentUpdater {
            LastRecordsView()
        }
            .environmentObject(OpenGluckConnection())
    }
}
