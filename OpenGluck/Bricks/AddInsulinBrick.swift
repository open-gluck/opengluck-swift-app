import SwiftUI
import OG

struct AddInsulinBrick: View {
    @EnvironmentObject var appDelegate: PhoneAppDelegate
    @EnvironmentObject var openGlückConnection: OpenGluckConnection
    private var sheetStatusOptions: SheetStatusViewOptions { appDelegate.sheetStatusOptions }
    
    private func quickAddInsulin(units: Int) async throws {
        guard let client = openGlückConnection.getClient() else {
            fatalError("No client")
        }
        let insulinRecords: [OpenGluckInsulinRecord] = [
            OpenGluckInsulinRecord(id: UUID(), timestamp: Date(), units: units, deleted: false)
        ]
        _ = try await client.upload(insulinRecords: insulinRecords)
    }
    
    @State var label: String = "Add"
    var body: some View {
        Brick(title: "Insulin", systemImage: "cross.vial") {
            HoldButton(label: "Add Insulin")
                .contextMenu(ContextMenu(menuItems: {
                    ForEach(1...16, id: \.self) { n in
                        Button("\(n) IU") {
                            sheetStatusOptions.state = SheetStatusViewState.inProgress
                            sheetStatusOptions.status = "\(n) IU"
                            sheetStatusOptions.subStatus1 = "Launching Task…"
                            Task {
                                defer { sheetStatusOptions.state = SheetStatusViewState.complete }
                                sheetStatusOptions.subStatus1 = "Adding…"
                                do {
                                    try await quickAddInsulin(units: n)
                                    sheetStatusOptions.subStatus1 = "Done!"
                                    NotificationCenter.default.post(name: Notification.Name.refreshOpenGlück, object: nil)
                                } catch {
                                    sheetStatusOptions.pushError(message: error.localizedDescription)
                                }
                            }
                        }
                    }
                    
                }))
        }
        .frame(maxHeight: BrickUI.smallHeight)
    }
}

#Preview("AddInsulinBrick") {
    AddInsulinBrick()
        .preferredColorScheme(.dark)
}
