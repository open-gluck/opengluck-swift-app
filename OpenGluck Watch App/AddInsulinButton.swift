import SwiftUI
import OG

class AddInsulinButtonData: ObservableObject {
    @Published var unitsString: String = "1"
}

struct AddInsulinButton: View {
    @ObservedObject var addInsulinButtonData: AddInsulinButtonData
    @Binding var isShown: Bool

    struct Interface: View {
        @EnvironmentObject var openGlückConnection: OpenGluckConnection
        @EnvironmentObject var sheetStatusOptions: SheetStatusViewOptions
        @ObservedObject var addInsulinButtonData: AddInsulinButtonData
        @Binding var isShown: Bool

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
            let statusTask = Task {
                do {
                    try await Task.sleep(for: .seconds(1))
                } catch {
                    return
                }
                sheetStatusOptions.state = SheetStatusViewState.inProgress
                sheetStatusOptions.status = "\(unitsString) IU"
                sheetStatusOptions.subStatus1 = "Preparing…"
                sheetStatusOptions.state = .inProgress
            }
            Task {
                defer {
                    statusTask.cancel()
                    sheetStatusOptions.state = SheetStatusViewState.complete
                }
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
            DigiTextView(placeholder: "0 IU",
                         text: $addInsulinButtonData.unitsString,
                         confirmLabel: "Add Insulin",
                         labelMacro: "% IU",
                         presentingModal: $isShown, onClose: {
            }, onConfirm: {
                Task {
                    await Task.yield()
                    if let units = Double(addInsulinButtonData.unitsString) {
                        addInsulin(units: units)
                    }
                }
            })
        }
    }
    
    var body: some View {
        Button {
            addInsulinButtonData.unitsString = ""
            isShown = true
        } label: {
            Image(systemName:"cross.vial")
                .foregroundColor(.white)
        }
    }
}
