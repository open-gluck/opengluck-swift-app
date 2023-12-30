import SwiftUI
import OG

fileprivate struct AddLowCustomView: View {
    @Environment(\.dismiss) private var dismiss
    @State var sugarInGramsString: String = ""
    @State var isAdding: Bool = false
    @FocusState var isFocused: Bool
    let add: (Double) async -> Void
    
    private var isValid: Bool {
        Double(sugarInGramsString) != nil
    }
    
    var body: some View {
        VStack {
            HStack {
                LabeledContent("Sugar:") {
                    TextField("", text: $sugarInGramsString)
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
                                        guard let sugarInGrams: Double = Double(sugarInGramsString) else {
                                            return
                                        }
                                        isAdding = true
                                        defer { isAdding = false }
                                        await add(sugarInGrams)
                                        dismiss()
                                    }
                                }
                                .disabled(!isValid)
                            }
                        }
                }
                Text("g")
            }
            Spacer()
        }
        .disabled(isAdding)
    }
}

#Preview("AddLowCustomView") {
    NavigationStack {
        AddLowCustomView(add: { _ in })
    }
}

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
    
    fileprivate func interactiveAdd(sugarInGrams: Double) async {
        sheetStatusOptions.state = SheetStatusViewState.inProgress
        sheetStatusOptions.status = abs(round(sugarInGrams) - sugarInGrams) < Double.ulpOfOne ? "\(Int(round(sugarInGrams)))g" : "\(sugarInGrams)g"
        sheetStatusOptions.subStatus1 = "Launching Task…"
        defer { sheetStatusOptions.state = SheetStatusViewState.complete }
        sheetStatusOptions.subStatus1 = "Adding…"
        do {
            try await quickAddLow(sugarInGrams: sugarInGrams)
            sheetStatusOptions.subStatus1 = "Done!"
            NotificationCenter.default.post(name: Notification.Name.refreshOpenGlück, object: nil)
        } catch {
            sheetStatusOptions.pushError(message: error.localizedDescription)
        }
    }
    
    @State var label: String = "Add"
    var body: some View {
        Brick(title: nil, systemImage: nil) {
            HoldButton(label: "Record Sugar", systemImage: "takeoutbag.and.cup.and.straw")
                .navigationDestination(for: PhoneNavigationData.PathAddLow.self) { _ in
                    AddLowCustomView(add: { await interactiveAdd(sugarInGrams: $0) })
                }
                .contextMenu(ContextMenu(menuItems: {
                    NavigationLink("Custom…", value: PhoneNavigationData.PathAddLow())
                    Divider()
                    ForEach(Array(stride(from: 10.0, through: 30.0, by: 5)), id: \.self) { g in
                        Button("\(Int(round(g)))g") {
                            Task {
                                await interactiveAdd(sugarInGrams: g)
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
    NavigationStack {
        AddLowBrick()
    }
        .preferredColorScheme(.dark)
}
