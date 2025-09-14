import SwiftUI
import OG

fileprivate struct AddInsulinCustomView: View {
    @Environment(\.dismiss) private var dismiss
    @State var unitsString: String = ""
    @State var isAdding: Bool = false
    @FocusState var isFocused: Bool
    let add: (Int) async -> Void
    
    private var isValid: Bool {
        Int(unitsString) != nil
    }
    
    var body: some View {
        VStack {
            HStack {
                LabeledContent("Insulin:") {
                    TextField("", text: $unitsString)
                        .multilineTextAlignment(.trailing)
                        .focused($isFocused)
                        .keyboardType(.numberPad)
                        .task {
                            isFocused = true
                        }
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Add") {
                                    Task {
                                        guard let units: Int = Int(unitsString) else {
                                            return
                                        }
                                        isAdding = true
                                        defer { isAdding = false }
                                        await add(units)
                                        dismiss()
                                    }
                                }
                                .disabled(!isValid)
                            }
                        }
                }
                Text("IU")
            }
            Spacer()
        }
        .disabled(isAdding)
    }
}

#Preview("AddInsulinCustomView") {
    NavigationStack {
        AddInsulinCustomView(add: { _ in })
    }
}


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
    
    fileprivate func interactiveAdd(units: Int) async {
        sheetStatusOptions.state = SheetStatusViewState.inProgress
        sheetStatusOptions.status = "\(units) IU"
        sheetStatusOptions.subStatus1 = "Launching Task…"
        defer { sheetStatusOptions.state = SheetStatusViewState.complete }
        sheetStatusOptions.subStatus1 = "Adding…"
        do {
            try await quickAddInsulin(units: units)
            sheetStatusOptions.subStatus1 = "Done!"
            NotificationCenter.default.post(name: Notification.Name.refreshOpenGlück, object: nil)
        } catch {
            sheetStatusOptions.pushError(message: error.localizedDescription)
        }
    }
    
    @State var label: String = "Add"
    var body: some View {
        Brick(title: nil, systemImage: nil) {
            HoldButton(label: "Record Insulin", systemImage: "cross.vial")
#if os(watchOS)
                .navigationDestination(for: PhoneNavigationData.PathAddInsulin.self) { _ in
                    AddInsulinCustomView(add: { await interactiveAdd(units: $0) })
                }
#endif
                .contextMenu(ContextMenu(menuItems: {
                    NavigationLink("Custom…", value: PhoneNavigationData.PathAddInsulin())
                    Divider()
                    ForEach(1...16, id: \.self) { n in
                        Button("\(n) IU") {
                            Task {
                                await interactiveAdd(units: n)
                            }
                        }
                    }
                    
                }))
        }
        .frame(maxHeight: BrickUI.extraSmallHeight)
    }
}

#Preview("AddInsulinBrick") {
    AddInsulinBrick()
        .preferredColorScheme(.dark)
}
