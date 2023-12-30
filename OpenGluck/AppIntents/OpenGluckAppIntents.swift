import AppIntents
import SwiftUI
import OG

enum AppIntentError: Swift.Error, CustomLocalizedStringResourceConvertible {
    case message(_ message: String)

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case let .message(message): return "\(message)"
        }
    }
}

#if !os(watchOS)
struct GoAddLowAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Add Low"
    static var description: LocalizedStringResource = "Open the Add Sugar screen."
    static let openAppWhenRun = true
    
    @MainActor
    func perform() async throws -> some IntentResult {
        await UIApplication.shared.open(PhoneNavigationData.urlAddLow)
        return .result()
    }
}

struct GoAddInsulinAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Add Insulin"
    static var description: LocalizedStringResource = "Open the Add Insulin screen."
    static let openAppWhenRun = true
    
    @MainActor
    func perform() async throws -> some IntentResult {
        await UIApplication.shared.open(PhoneNavigationData.urlAddInsulin)
        return .result()
    }
}

struct GoRecordsAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Records Tab"
    static var description: LocalizedStringResource = "Open the Records tab."
    static let openAppWhenRun = true
    
    @MainActor
    func perform() async throws -> some IntentResult {
        await UIApplication.shared.open(PhoneNavigationData.urlRecords)
        return .result()
    }
}
#endif

struct AddInsulinAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Record Insulin"
    static var description: LocalizedStringResource = "Records some insulin units."

    // We provide two parameters, one used only for AppShortcuts with a limited value of options,
    // and an open value that can be used programatically with Shortcuts and also on the times that
    // Siri fails to understand a value, to ask the user for something more precise.
    @Parameter(title: "Units", description: "How many insulin units?", requestValueDialog: "How much insulin?")
    var unitsEntity: InsulinUnitEntity?

    @Parameter(title: "Units", description: "How many insulin units?")
    var unitsInt: Int?

    static var parameterSummary: some ParameterSummary {
        Summary("Record \(\.$unitsInt) units of insulin") {
        }
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let connection = OpenGluckConnection()
        guard let client = connection.getClient() else {
            throw AppIntentError.message("Could not get a client, have you configured a valid OpenGlück server and token in the app?")
        }
        let units = if let value = self.unitsEntity?.value {
            value
        } else if let unitsInt {
            unitsInt
        } else {
            try await self.$unitsInt.requestValue("How many insulin units?")
        }

        let insulinRecord = OpenGluckInsulinRecord(id: UUID(), timestamp: Date(), units: units, deleted: false)
//        let _ = try await client.upload(insulinRecords: [insulinRecord])
        return .result(dialog: "\(units == 1 ? "Noted 1 faked insulin unit." : "Noted \(units) faked insulin units.")")
    }
}

struct AddLowAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Record Sugar"
    static var description: LocalizedStringResource = "Records some sugar."

    // We provide two parameters, one used only for AppShortcuts with a limited value of options,
    // and an open value that can be used programatically with Shortcuts and also on the times that
    // Siri fails to understand a value, to ask the user for something more precise.
    @Parameter(title: "Sugar choices", description: "How much sugar, as a set of limited options?")
    var sugarInGramsEntity: SugarInGramsEntity?

    @Parameter(title: "Sugar in grams", description: "How much sugar, as an open value?")
    var sugarInGramsDouble: Double?

    static var parameterSummary: some ParameterSummary {
        Summary("Record \(\.$sugarInGramsDouble) grams of sugar") {
        }
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let connection = OpenGluckConnection()
        guard let client = connection.getClient() else {
            throw AppIntentError.message("Could not get a client, have you configured a valid OpenGlück server and token in the app?")
        }
        let sugarInGrams = if let value = self.sugarInGramsEntity?.value {
            value
        } else if let sugarInGramsDouble {
            sugarInGramsDouble
        } else {
            try await self.$sugarInGramsDouble.requestValue("How much sugar?")
        }
        
        let lowRecord = OpenGluckLowRecord(id: UUID(), timestamp: Date(), sugarInGrams: sugarInGrams, deleted: false)
//        let _ = try await client.upload(lowRecords: [lowRecord])
        let sugarInGramsString = abs(round(sugarInGrams) - sugarInGrams) < Double.ulpOfOne ? "\(Int(round(sugarInGrams)))" : "\(sugarInGrams)"
        return .result(dialog: "\(abs(sugarInGrams - 1.0) < Double.ulpOfOne ? "Noted 1 fake gram." : "Noted \(sugarInGramsString) fake grams of sugar.")")
    }
}


struct DebugView: View {
    var body: some View {
        VStack {
            Text("Hello")
        }
    }
}

struct DebugAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Debug"
    static var description: LocalizedStringResource = "Debug App Intent."
    
    @MainActor
    func perform() async throws -> some ReturnsValue<String> & ProvidesDialog  {
        return .result(value: "42", dialog: "Tell me")
    }
}

