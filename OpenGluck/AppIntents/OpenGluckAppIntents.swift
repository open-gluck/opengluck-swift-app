import AppIntents
import SwiftUI
import OG
import OGUI

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
    static let title: LocalizedStringResource = "Open Add Low"
    static let description: LocalizedStringResource = "Open the Add Sugar screen."
    static let openAppWhenRun = true
    
    @MainActor
    func perform() async throws -> some IntentResult {
        await UIApplication.shared.open(PhoneNavigationData.urlAddLow)
        return .result()
    }
}

struct GoAddInsulinAppIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Add Insulin"
    static let description: LocalizedStringResource = "Open the Add Insulin screen."
    static let openAppWhenRun = true
    
    @MainActor
    func perform() async throws -> some IntentResult {
        await UIApplication.shared.open(PhoneNavigationData.urlAddInsulin)
        return .result()
    }
}

struct GoRecordsAppIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Records Tab"
    static let description: LocalizedStringResource = "Open the Records tab."
    static let openAppWhenRun = true
    
    @MainActor
    func perform() async throws -> some IntentResult {
        await UIApplication.shared.open(PhoneNavigationData.urlRecords)
        return .result()
    }
}
#endif

struct AddInsulinAppIntent: AppIntent {
    static let title: LocalizedStringResource = "Record Insulin"
    static let description: LocalizedStringResource = "Records some insulin units."

    // We provide two parameters, one used only for AppShortcuts with a limited value of options,
    // and an open value that can be used programatically with Shortcuts and also on the times that
    // Siri fails to understand a value, to ask the user for something more precise.
    @Parameter(title: "Units", description: "How many insulin units?", requestValueDialog: "How much insulin?")
    var unitsEnum: InsulinUnitEnum?

    @Parameter(title: "Units", description: "How many insulin units?")
    var unitsInt: Int?

    static var parameterSummary: some ParameterSummary {
        Summary("Record \(\.$unitsInt) units of insulin") {
        }
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let connection = OpenGluckConnection()
        guard let client = connection.getClient() else {
            throw AppIntentError.message("Could not get a client, have you configured a valid OpenGlück server and token in the app?")
        }
        let units = if let value = self.unitsEnum?.rawValue {
            Int(value)!
        } else if let unitsInt {
            unitsInt
        } else {
            try await self.$unitsInt.requestValue("How many insulin units?")
        }

        let insulinRecord = OpenGluckInsulinRecord(id: UUID(), timestamp: Date(), units: units, deleted: false)
        let _ = try await client.upload(insulinRecords: [insulinRecord])
        return .result(
            dialog: "\(units == 1 ? "Insulin one unit. Noted." : "Insulin \(units) units. Noted.")",
            view: InsulinRecordSnippet(insulinRecord: insulinRecord)
        )
    }
}

#if false
/// the same hack, with AppEntity
/// doesn't work on watchOS 10.4
struct AddInsulinShotAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Record Insulin"
    static var description: LocalizedStringResource = "Records some insulin units."

    // We provide two parameters, one used only for AppShortcuts with a limited value of options,
    // and an open value that can be used programatically with Shortcuts and also on the times that
    // Siri fails to understand a value, to ask the user for something more precise.
    @Parameter(title: "Units", description: "How many insulin units?")
    var units: InsulinAppEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Record \(\.$units) units of insulin") {
        }
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let connection = OpenGluckConnection()
        guard let client = connection.getClient() else {
            throw AppIntentError.message("Could not get a client, have you configured a valid OpenGlück server and token in the app?")
        }
        let units = if let units {
            units
        } else {
            try await self.$units.requestValue("How many insulin units?")
        }

        let insulinRecord = OpenGluckInsulinRecord(id: UUID(), timestamp: Date(), units: units.units, deleted: false)
        let _ = try await client.upload(insulinRecords: [insulinRecord])
        return .result(
            dialog: "\(units.units == 1 ? "Insulin one unit. Noted." : "Insulin \(units.units) units. Noted.")",
            view: InsulinRecordSnippet(insulinRecord: insulinRecord)
        )
    }
}
#endif


struct AddSnoozedLowAppIntent: AppIntent {
    static let title: LocalizedStringResource = "Snooze Sugar"
    static let description: LocalizedStringResource = "Snooze low."

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let connection = OpenGluckConnection()
        guard let client = connection.getClient() else {
            throw AppIntentError.message("Could not get a client, have you configured a valid OpenGlück server and token in the app?")
        }
        
        let lowRecord = OpenGluckLowRecord(id: UUID(), timestamp: Date(), sugarInGrams: 0, deleted: false)
        let _ = try await client.upload(lowRecords: [lowRecord])
        return .result(
            dialog: "Low snoozed.",
            view: LowRecordSnippet(lowRecord: lowRecord)
        )
    }
}

struct AddLowAppIntent: AppIntent {
    static let title: LocalizedStringResource = "Record Sugar"
    static let description: LocalizedStringResource = "Records some sugar."

    // We provide two parameters, one used only for AppShortcuts with a limited value of options,
    // and an open value that can be used programatically with Shortcuts and also on the times that
    // Siri fails to understand a value, to ask the user for something more precise.
    @Parameter(title: "Sugar choices", description: "How much sugar, as a set of limited options?")
    var sugarInGramsEnum: SugarInGramsEnum?

    @Parameter(title: "Sugar in grams", description: "How much sugar, as an open value?")
    var sugarInGramsDouble: Double?

    static var parameterSummary: some ParameterSummary {
        Summary("Record \(\.$sugarInGramsDouble) grams of sugar") {
        }
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let connection = OpenGluckConnection()
        guard let client = connection.getClient() else {
            throw AppIntentError.message("Could not get a client, have you configured a valid OpenGlück server and token in the app?")
        }
        let sugarInGrams = if let value = self.sugarInGramsEnum?.rawValue {
            Double(value)!
        } else if let sugarInGramsDouble {
            sugarInGramsDouble
        } else {
            try await self.$sugarInGramsDouble.requestValue("How much sugar?")
        }
        
        let lowRecord = OpenGluckLowRecord(id: UUID(), timestamp: Date(), sugarInGrams: sugarInGrams, deleted: false)
        let _ = try await client.upload(lowRecords: [lowRecord])
        let sugarInGramsString = abs(round(sugarInGrams) - sugarInGrams) < Double.ulpOfOne ? "\(Int(round(sugarInGrams)))" : "\(sugarInGrams)"
        return .result(
            dialog: "\(abs(sugarInGrams - 1.0) < Double.ulpOfOne ? "Sugar 1 gram. Noted." : "Sugar \(sugarInGramsString) grams. Noted.")",
            view: LowRecordSnippet(lowRecord: lowRecord)
        )
    }
}

struct DeleteLastInsulinAppIntent: ForegroundContinuableIntent {
    static let title: LocalizedStringResource = "Delete Last Insulin"
    static let description: LocalizedStringResource = "Delete the last insulin unit."

    static var parameterSummary: some ParameterSummary {
        Summary("Delete the last insulin unit.") {
        }
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let connection = OpenGluckConnection()
        guard let client = connection.getClient() else {
            throw AppIntentError.message("Could not get a client, have you configured a valid OpenGlück server and token in the app?")
        }
        let last = try await client.getLastData()
        guard let lastInsulinRecord = last?.insulinRecords?.sorted(by: { $0.timestamp > $1.timestamp }).filter({ !$0.deleted }).first else {
            return .result(dialog: "No recent insulin record found.")

        }
        let elapsed = lastInsulinRecord.timestamp.timeIntervalSinceNow
        guard -elapsed < 2*60 else {
            throw needsToContinueInForegroundError("The last insulin record was recorded \(OpenGluckManager.secondsToTextAgo(elapsed)) and needs to be deleted manually.")
        }

        let deletedRecord: OpenGluckInsulinRecord = OpenGluckInsulinRecord(id: lastInsulinRecord.id, timestamp: lastInsulinRecord.timestamp, units: lastInsulinRecord.units, deleted: true)
        let _ = try await client.upload(insulinRecords: [deletedRecord])
        return .result(dialog: "Insulin record deleted.", view: InsulinRecordSnippet(insulinRecord: deletedRecord))
    }
}

struct DeleteLastLowAppIntent: ForegroundContinuableIntent {
    static let title: LocalizedStringResource = "Delete Last Sugar"
    static let description: LocalizedStringResource = "Delete the last sugar."

    static var parameterSummary: some ParameterSummary {
        Summary("Delete the last sugar.") {
        }
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let connection = OpenGluckConnection()
        guard let client = connection.getClient() else {
            throw AppIntentError.message("Could not get a client, have you configured a valid OpenGlück server and token in the app?")
        }
        let last = try await client.getLastData()
        guard let lastLowRecord = last?.lowRecords?.sorted(by: { $0.timestamp > $1.timestamp }).filter({ !$0.deleted }).first else {
            return .result(dialog: "No recent sugar found.")

        }
        let elapsed = lastLowRecord.timestamp.timeIntervalSinceNow
        guard -elapsed < 2*60 else {
            throw needsToContinueInForegroundError("The last sugar was recorded \(OpenGluckManager.secondsToTextAgo(elapsed)) and needs to be deleted manually.")
        }

        let deletedRecord: OpenGluckLowRecord = OpenGluckLowRecord(id: lastLowRecord.id, timestamp: lastLowRecord.timestamp, sugarInGrams: lastLowRecord.sugarInGrams, deleted: true)
        let _ = try await client.upload(lowRecords: [deletedRecord])
        return .result(dialog: "Sugar deleted.", view: LowRecordSnippet(lowRecord: deletedRecord))
    }
}

struct GetCurrentBloodGlucoseAppIntent: ForegroundContinuableIntent {
    static let title: LocalizedStringResource = "Get Current Blood Glucose"
    static let description: LocalizedStringResource = "Return the current blood glucose."

    static var parameterSummary: some ParameterSummary {
        Summary("Get the current blood glucose.") {
        }
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let connection = OpenGluckConnection()
        guard let client = connection.getClient() else {
            throw AppIntentError.message("Could not get a client, have you configured a valid OpenGlück server and token in the app?")
        }
        let last = try await client.getLastData()
        guard let lastGlucoseRecord = last?.glucoseRecords?.sorted(by: { $0.timestamp > $1.timestamp }).first else {
            return .result(dialog: "No recent blood glucose found.")
        }
        let elapsed = lastGlucoseRecord.timestamp.timeIntervalSinceNow
        guard -elapsed < 10*60 else {
            throw needsToContinueInForegroundError("I found no recent blood glucose measurement. Last was recorded \(OpenGluckManager.secondsToTextAgo(elapsed)).")
        }

        let mgDl: Double = Double(lastGlucoseRecord.mgDl)
        let postfix = if mgDl < OGUI.thresholdNormalLow {
            ", low"
        } else if mgDl >= OGUI.thresholdHighVeryHigh {
            ", very high"
        } else if mgDl >= OGUI.thresholdNormalHigh {
            ", high"
        } else {
            ""
        }
        let dialog: String = "Current glucose \(BloodGlucose.localize(lastGlucoseRecord.mgDl, style: .short))\(postfix)"
        return .result(dialog: "\(dialog)", view: GlucoseRecordSnippet(glucoseRecord: lastGlucoseRecord))
    }
}
