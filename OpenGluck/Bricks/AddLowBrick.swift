import SwiftUI
import OG

struct AddLowBrick: View {
    @EnvironmentObject var appDelegate: PhoneAppDelegate
    @EnvironmentObject var openGlückConnection: OpenGluckConnection
    private var sheetStatusOptions: SheetStatusViewOptions { appDelegate.sheetStatusOptions }
    
    private func quickAddLow(sugarInGrams: Double) async throws {
        guard let client = openGlückConnection.getClient() else {
            fatalError("No client")
        }
        let lowRecords: [OpenGluckLowRecord] = [
            OpenGluckLowRecord(id: UUID(), timestamp: Date(), sugarInGrams: sugarInGrams, deleted: false)
        ]
        _ = try await client.upload(lowRecords: lowRecords)
    }
    
    @State var label: String = "Add"
    var body: some View {
        Brick(title: nil, systemImage: nil) {
            HoldButton(label: "Record Sugar", systemImage: "takeoutbag.and.cup.and.straw")
                .contextMenu(ContextMenu(menuItems: {
                    ForEach(Array(stride(from: 10.0, through: 30.0, by: 5)), id: \.self) { g in
                        Button("\(Int(round(g)))g") {
                            sheetStatusOptions.state = SheetStatusViewState.inProgress
                            sheetStatusOptions.status = "\(g)g"
                            sheetStatusOptions.subStatus1 = "Launching Task…"
                            Task {
                                defer { sheetStatusOptions.state = SheetStatusViewState.complete }
                                sheetStatusOptions.subStatus1 = "Adding…"
                                do {
                                    try await quickAddLow(sugarInGrams: g)
                                    sheetStatusOptions.subStatus1 = "Done!"
                                    NotificationCenter.default.post(name: Notification.Name.refreshOpenGlück, object: nil)
                                } catch {
                                    sheetStatusOptions.pushError(message: error.localizedDescription)
                                }
                            }
                        }
                    }
                    
                }))
                .frame(width: .infinity)
        }
        .frame(maxHeight: BrickUI.extraSmallHeight)
    }
}

#Preview("AddLowBrick") {
    AddLowBrick()
        .preferredColorScheme(.dark)
}
