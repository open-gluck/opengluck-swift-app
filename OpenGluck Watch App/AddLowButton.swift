import SwiftUI
import OG

class AddLowButtonData: ObservableObject {
    @Published var showAddLow: Bool = false
    @Published var sugarInGramsString: String = ""
}

struct AddLowButton: View {
    @ObservedObject var addLowButtonData: AddLowButtonData

    struct Interface: View {
        @EnvironmentObject var openGlückConnection: OpenGluckConnection
        @EnvironmentObject var sheetStatusOptions: SheetStatusViewOptions
        @ObservedObject var addLowButtonData: AddLowButtonData
        
        private func uploadLowToOpenGlück(sugarInGrams: Double) async throws {
            guard let client = openGlückConnection.getClient() else {
                fatalError("No client")
            }
            let lowRecords: [OpenGluckLowRecord] = [
                OpenGluckLowRecord(id: UUID(), timestamp: Date(), sugarInGrams: sugarInGrams, deleted: false)
            ]
            _ = try await client.upload(lowRecords: lowRecords)
        }

        private func addLow(sugarInGrams: Double) {
            let sugarInGramsString: String = abs(sugarInGrams - round(sugarInGrams)) < .ulpOfOne ? "\(Int(round(sugarInGrams)))" : "\(round(sugarInGrams * 10) / 10)"
            sheetStatusOptions.state = SheetStatusViewState.inProgress
            sheetStatusOptions.status = "\(sugarInGramsString)g"
            sheetStatusOptions.subStatus1 = "Preparing…"
            sheetStatusOptions.state = .inProgress
            Task {
                defer { sheetStatusOptions.state = SheetStatusViewState.complete }
                sheetStatusOptions.subStatus1 = "Adding…"
                do {
                    try await uploadLowToOpenGlück(sugarInGrams: sugarInGrams)
                    sheetStatusOptions.subStatus1 = "Done!"
                    NotificationCenter.default.post(name: Notification.Name.refreshOpenGlück, object: nil)
                } catch {
                    sheetStatusOptions.pushError(message: error.localizedDescription)
                }
            }
        }
        
        var body: some View {
            DigiTextView(placeholder: "",
                         text: $addLowButtonData.sugarInGramsString,
                         presentingModal: $addLowButtonData.showAddLow,
                         style: .decimal,
                         onClose: {
            }, onConfirm: {
                Task {
                    await Task.yield()
                    if let sugarInGrams = Double(addLowButtonData.sugarInGramsString) {
                        addLow(sugarInGrams: sugarInGrams)
                    }
                }
            })
            .opacity(0)        }
    }
    
    var body: some View {
        Button {
            addLowButtonData.sugarInGramsString = ""
            addLowButtonData.showAddLow = true
        } label: {
            Image(systemName:"takeoutbag.and.cup.and.straw")
                .foregroundColor(.white)
        }
    }
}
