import SwiftUI
import OG

class AddInsulinButtonData: ObservableObject {
    @Published var showAddInsulin: Bool = false
    @Published var unitsString: String = ""
}

struct AddInsulinButton: View {
    @ObservedObject var addInsulinButtonData: AddInsulinButtonData

    struct Interface: View {
        @EnvironmentObject var openGlückConnection: OpenGluckConnection
        @EnvironmentObject var sheetStatusOptions: SheetStatusViewOptions
        @ObservedObject var addInsulinButtonData: AddInsulinButtonData
        
        private func uploadInsulinToOpenGlück(units: Int) async throws {
            guard let client = openGlückConnection.getClient() else {
                fatalError("No client")
            }
            let insulinRecords: [OpenGluckInsulinRecord] = [
                OpenGluckInsulinRecord(id: UUID(), timestamp: Date(), units: units, deleted: false)
            ]
            _ = try await client.upload(insulinRecords: insulinRecords)
        }

        private func addInsulin(units: Double) {
            let unitsString: String = abs(units - round(units)) < .ulpOfOne ? "\(Int(round(units)))" : "\(round(units * 10) / 10)"
            sheetStatusOptions.state = SheetStatusViewState.inProgress
            sheetStatusOptions.status = "\(unitsString) IU"
            sheetStatusOptions.subStatus1 = "Preparing…"
            sheetStatusOptions.state = .inProgress
            Task {
                defer { sheetStatusOptions.state = SheetStatusViewState.complete }
                sheetStatusOptions.subStatus1 = "Adding…"
                do {
                    try await uploadInsulinToOpenGlück(units: Int(round(units)))
                    sheetStatusOptions.subStatus1 = "Done!"
                    NotificationCenter.default.post(name: Notification.Name.refreshOpenGlück, object: nil)
                } catch {
                    sheetStatusOptions.pushError(message: error.localizedDescription)
                }
            }
        }
        
        var body: some View {
            DigiTextView(placeholder: "",
                         text: $addInsulinButtonData.unitsString,
                         presentingModal: $addInsulinButtonData.showAddInsulin, onClose: {
            }, onConfirm: {
                Task {
                    await Task.yield()
                    if let units = Double(addInsulinButtonData.unitsString) {
                        addInsulin(units: units)
                    }
                }
            })
            .opacity(0)        }
    }
    
    var body: some View {
        Button {
            addInsulinButtonData.unitsString = ""
            addInsulinButtonData.showAddInsulin = true
        } label: {
            Image(systemName:"cross.vial")
                .foregroundColor(.white)
        }
    }
}
