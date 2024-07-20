import SwiftUI
import OG

class AddLowButtonData: ObservableObject, CustomStringConvertible {
    var description: String { "isShow=\(isShown), valueString=\(valueString)" }
    
    @Published var valueString: String = ""
    @Published var isShown: Bool = false
    @Published var getSugarFromValue: ((Double) -> Double)? = nil
    @Published var formatValue: ((String) -> String)? = nil
    
    private func uploadLowToOpenGlück(openGlückConnection: OpenGluckConnection, sugarInGrams: Double) async throws {
        guard let client = openGlückConnection.getClient() else {
            fatalError("No client")
        }
        let lowRecords: [OpenGluckLowRecord] = [
            OpenGluckLowRecord(id: UUID(), timestamp: Date(), sugarInGrams: sugarInGrams, deleted: false)
        ]
        _ = try await client.upload(lowRecords: lowRecords)
    }
    
    fileprivate func addLow(value: Double, sugarInGrams: Double, openGlückConnection: OpenGluckConnection, sheetStatusOptions: SheetStatusViewOptions) {
        let valueString: String = abs(value - round(value)) < .ulpOfOne ? "\(Int(round(value)))" : "\(round(value * 10) / 10)"
        let statusTask = Task {
            do {
                try await Task.sleep(for: .seconds(1))
            } catch {
                return
            }
            sheetStatusOptions.state = SheetStatusViewState.inProgress
            sheetStatusOptions.status = self.formatValue!(valueString)
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
                print("upload to OG sugarInGrams=\(sugarInGrams)")
                try await uploadLowToOpenGlück(openGlückConnection: openGlückConnection, sugarInGrams: sugarInGrams)
                sheetStatusOptions.subStatus1 = "Done!"
                NotificationCenter.default.post(name: Notification.Name.refreshOpenGlück, object: nil)
            } catch {
                sheetStatusOptions.pushError(message: error.localizedDescription)
            }
        }
    }
}

struct AddLowButtonSnooze: View {
    @ObservedObject var addLowButtonData: AddLowButtonData
    @EnvironmentObject var openGlückConnection: OpenGluckConnection
    @EnvironmentObject var sheetStatusOptions: SheetStatusViewOptions
    let onOpen: () -> Void
    
    var body: some View {
        Button {
            onOpen()
            addLowButtonData.addLow(value: 0, sugarInGrams: 0, openGlückConnection: openGlückConnection, sheetStatusOptions: sheetStatusOptions)
        } label: {
            Image(systemName: "flag")
        }
    }
}

struct AddLowButtonSugar: View {
    @ObservedObject var addLowButtonData: AddLowButtonData
    let onOpen: () -> Void
    
    var body: some View {
        AddLowButton(
            addLowButtonData: addLowButtonData,
            getSugarFromValue: { $0 },
            formatValue: { "\($0)g" },
            label: {
                Text("Sugar")
            },
            onOpen: onOpen
        )
    }
}

struct AddLowButtonSmallSugarCube: View {
    @ObservedObject var addLowButtonData: AddLowButtonData
    let onOpen: () -> Void
    
    static private let weightSmallSugarCubeInGrams = 4.0
    static let textSmallSugar = "◇"
    
    var body: some View {
        AddLowButton(
            addLowButtonData: addLowButtonData,
            getSugarFromValue: { $0 * Self.weightSmallSugarCubeInGrams },
            formatValue: { "\($0) \(Self.textSmallSugar)" },
            label: {
                Text("Small Sugar Cubes")
            },
            onOpen: onOpen
        )
    }
}

struct AddLowButtonLargeSugarCube: View {
    @ObservedObject var addLowButtonData: AddLowButtonData
    let onOpen: () -> Void
    
    static private let weightLargeSugarCubeInGrams = 5.95
    static let textLargeSugar = "▭"
    
    var body: some View {
        AddLowButton(
            addLowButtonData: addLowButtonData,
            getSugarFromValue: { $0 * Self.weightLargeSugarCubeInGrams },
            formatValue: { "\($0) \(Self.textLargeSugar)" },
            label: {
                Text("Large Sugar Cubes")
            },
            onOpen: onOpen
        )
    }
}

struct AddLowButtonInterface: View {
    @EnvironmentObject var openGlückConnection: OpenGluckConnection
    @EnvironmentObject var sheetStatusOptions: SheetStatusViewOptions
    @ObservedObject var addLowButtonData: AddLowButtonData
    
    let onClose: () -> Void
    
    init(addLowButtonData: AddLowButtonData, onClose: @escaping () -> Void = {}) {
        self.addLowButtonData = addLowButtonData
        self.onClose = onClose
    }
        
    func addLowValue() async {
        await Task.yield()
        if let value = Double(addLowButtonData.valueString) {
            let sugarInGrams: Double = addLowButtonData.getSugarFromValue!(value)
            addLowButtonData.addLow(value: value, sugarInGrams: sugarInGrams, openGlückConnection: openGlückConnection, sheetStatusOptions: sheetStatusOptions)
        } else {
            addLowButtonData.addLow(value: 0, sugarInGrams: 0, openGlückConnection: openGlückConnection, sheetStatusOptions: sheetStatusOptions)
        }
    }
    
    var body: some View {
        DigiTextView(placeholder: addLowButtonData.formatValue?("0") ?? "", //addLowButtonData.getSugarFromValue?(0.0)),
                     text: $addLowButtonData.valueString,
                     confirmLabel: "Add Sugar",
                     labelMacro: addLowButtonData.formatValue?("%") ?? "",
                     presentingModal: $addLowButtonData.isShown,
                     style: .decimal,
                     onClose: self.onClose, onConfirm: {
            Task {
                await addLowValue()
            }
        })
    }
}

struct AddLowButton<LabelContent: View>: View {
    @ObservedObject var addLowButtonData: AddLowButtonData
    
    let getSugarFromValue: (Double) -> Double
    let formatValue: (String) -> String
    @ViewBuilder let label: () -> LabelContent
    let onOpen: () -> Void
    
    init(addLowButtonData: AddLowButtonData, getSugarFromValue: @escaping (Double) -> Double, formatValue: @escaping (String) -> String, label: @escaping () -> LabelContent, onOpen: @escaping () -> Void = {}) {
        self.addLowButtonData = addLowButtonData
        self.getSugarFromValue = getSugarFromValue
        self.formatValue = formatValue
        self.label = label
        self.onOpen = onOpen
    }
    
    private func open() {
        addLowButtonData.valueString = ""
        addLowButtonData.getSugarFromValue = getSugarFromValue
        addLowButtonData.formatValue = formatValue
        Task {
            try? await Task.sleep(for: .seconds(0.15))
            onOpen()
            addLowButtonData.isShown = true
        }
    }
    
    var body: some View {
        let _ = Self._printChanges()
        Button {
            open()
        } label: {
            label()
        }
    }
}

struct AddLowButtonMulti: View {
    @ObservedObject var addLowButtonData: AddLowButtonData
    
    @State var isPresented: Bool = false
    
    @State var isPresentedSugar: Bool = false
    @State var isPresentedSmallSugar: Bool = false
    @State var isPresentedLargeSugar: Bool = false
    
    var body: some View {
        ZStack {
            AddLowButtonInterface(addLowButtonData: addLowButtonData) {
                isPresented = false
            }
            Button {
                isPresented = true
            } label: {
                Label("Sugar", systemImage: "takeoutbag.and.cup.and.straw")
            }
        }
        .sheet(isPresented: $isPresented) {
            List {
                AddLowButtonSugar(addLowButtonData: addLowButtonData) {
                    isPresented = false
                }
                AddLowButtonSmallSugarCube(addLowButtonData: addLowButtonData) {
                    isPresented = false
                }
                AddLowButtonLargeSugarCube(addLowButtonData: addLowButtonData) {
                    isPresented = false
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    AddLowButtonSnooze(addLowButtonData: addLowButtonData) {
                        isPresented = false
                    }
                }
            }
        }
    }
}

fileprivate struct Preview: View {
    @StateObject var addLowButtonData: AddLowButtonData = AddLowButtonData()
    
    var body: some View {
        NavigationStack {
            TabView {
                Text("Body")
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    AddLowButtonMulti(addLowButtonData: addLowButtonData)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("X") {
                    }
                }
            }
        }
        .environmentObject(SheetStatusViewOptions())
        .environmentObject(OpenGluckConnection())
    }
}

#Preview {
    Preview()
}
