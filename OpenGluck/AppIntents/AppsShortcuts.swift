import AppIntents

struct AppsShortcuts: AppShortcutsProvider {
    @AppShortcutsBuilder
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: DeleteLastInsulinAppIntent(),
            phrases: [
                "\(.applicationName) delete last insulin",
                "\(.applicationName) delete last insulin record",
                "Delete the last insulin in \(.applicationName)",
                "Delete the last insulin record in \(.applicationName)",
            ],
            shortTitle: "Delete Last Insulin",
            systemImageName: "trash.circle"
        )
        AppShortcut(
            intent: DeleteLastLowAppIntent(),
            phrases: [
                "\(.applicationName) delete last sugar",
                "Delete the last sugar in \(.applicationName)",
            ],
            shortTitle: "Delete Last Sugar",
            systemImageName: "trash.circle"
        )
        AppShortcut(
            intent: AddInsulinAppIntent(),
            phrases: [
                "\(.applicationName) unit",
                "\(.applicationName) record insulin",
            ],
            shortTitle: "Record insulin",
            systemImageName: "cross.vial"
        )
        AppShortcut(
            intent: AddInsulinAppIntent(),
            phrases: [
                "\(.applicationName) \(\.$unitsEnum) unit",
                "\(.applicationName) \(\.$unitsEnum) units",
            ],
            shortTitle: "Record some unit of insulin",
            systemImageName: "cross.vial"
        )
        AppShortcut(
            intent: IncreaseLastInsulinByAppIntent(),
            phrases: [
                "\(.applicationName) add \(\.$unitsEnum)",
                "\(.applicationName) increase \(\.$unitsEnum)",
            ],
            shortTitle: "Increase last insulin by some units",
            systemImageName: "cross.vial"
        )
        AppShortcut(
            intent: DecreaseLastInsulinByAppIntent(),
            phrases: [
                "\(.applicationName) remove \(\.$unitsEnum)",
                "\(.applicationName) decrease \(\.$unitsEnum)",
            ],
            shortTitle: "Decrease last insulin by some units",
            systemImageName: "cross.vial"
        )

        AppShortcut(
            intent: AddSnoozedLowAppIntent(),
            phrases: [
                "\(.applicationName) no sugar",
                "\(.applicationName) snooze sugar",
                "no sugar in \(.applicationName)",
                "zero gram of sugar in \(.applicationName)",
                "zero grams of sugar in \(.applicationName)",
                "\(.applicationName) zero gram",
                "\(.applicationName) zero grams",
                "no \(.applicationName)",
                "zero gram \(.applicationName)",
                "zero grams \(.applicationName)",
            ],
            shortTitle: "Snooze low",
            systemImageName: "flag"
        )
        AppShortcut(
            intent: AddLowAppIntent(),
            phrases: [
                "\(.applicationName) record sugar",
                "\(\.$sugarInGramsEnum) grams of sugar in \(.applicationName)",
                "\(.applicationName) \(\.$sugarInGramsEnum) gram",
                "\(.applicationName) \(\.$sugarInGramsEnum) grams",
                "\(\.$sugarInGramsEnum) gram \(.applicationName)",
                "\(\.$sugarInGramsEnum) grams \(.applicationName)",
            ],
            shortTitle: "Record sugar",
            systemImageName: "teddybear"
        )
        AppShortcut(
            intent: GetCurrentBloodGlucoseAppIntent(),
            phrases: [
                "\(.applicationName) get current blood glucose",
                "\(.applicationName) what's my blood glucose",
                "\(.applicationName) what's my current blood glucose",
                "what's my current blood glucose in \(.applicationName)",
                "what's my blood glucose in \(.applicationName)",
                "\(.applicationName) get",
                "get \(.applicationName)",
            ],
            shortTitle: "Get current blood glucose",
            systemImageName: "drop"
        )
    }
}
