import AppIntents

struct AppsShortcuts: AppShortcutsProvider {
    @AppShortcutsBuilder
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: DeleteLastInsulinAppIntent(),
            phrases: [
                "Delete the last insulin in \(.applicationName)",
            ],
            shortTitle: "Delete Last Insulin",
            systemImageName: "trash.circle"
        )
        AppShortcut(
            intent: DeleteLastLowAppIntent(),
            phrases: [
                "Delete the last sugar in \(.applicationName)",
            ],
            shortTitle: "Delete Last Sugar",
            systemImageName: "trash.circle"
        )
        AppShortcut(
            intent: AddInsulinAppIntent(),
            phrases: [
                "\(.applicationName) insulin",
                "\(.applicationName) add insulin",
                "\(\.$unitsEnum) insulin units in \(.applicationName)",
                "\(.applicationName) \(\.$unitsEnum) unit",
                "\(.applicationName) \(\.$unitsEnum) units",
                "\(\.$unitsEnum) unit \(.applicationName)",
                "\(\.$unitsEnum) units \(.applicationName)",
            ],
            shortTitle: "Add insulin",
            systemImageName: "cross.vial"
        )

        AppShortcut(
            intent: AddLowAppIntent(),
            phrases: [
                "\(.applicationName) sugar",
                "\(\.$sugarInGramsEnum) grams of sugar in \(.applicationName)",
                "\(.applicationName) \(\.$sugarInGramsEnum) gram",
                "\(.applicationName) \(\.$sugarInGramsEnum) grams",
                "\(\.$sugarInGramsEnum) gram \(.applicationName)",
                "\(\.$sugarInGramsEnum) grams \(.applicationName)",
            ],
            shortTitle: "Add sugar",
            systemImageName: "takeoutbag.and.cup.and.straw"
        )
        AppShortcut(
            intent: GetCurrentBloodGlucoseAppIntent(),
            phrases: [
                "what's my current blood glucose in \(.applicationName)",
                "get \(.applicationName)",
            ],
            shortTitle: "Get current blood glucose",
            systemImageName: "drop"
        )
    }
}
