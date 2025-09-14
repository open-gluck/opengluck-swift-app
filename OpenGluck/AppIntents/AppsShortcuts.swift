import AppIntents

struct AppsShortcuts: AppShortcutsProvider {
    @AppShortcutsBuilder
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: DeleteLastInsulinAppIntent(),
            phrases: [
                "\(.applicationName) delete last insulin",
                "Delete the last insulin in \(.applicationName)",
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
                "\(.applicationName) record insulin",
                "\(.applicationName) note insulin",
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
            intent: IncreaseLastInsulinByAppIntent(),
            phrases: [
                "\(.applicationName) add \(\.$unitsEnum) units",
                "\(.applicationName) augment \(\.$unitsEnum) unit",
                "\(.applicationName) increase \(\.$unitsEnum) units",
            ],
            shortTitle: "Increase last insulin",
            systemImageName: "cross.vial"
        )
        AppShortcut(
            intent: DecreaseLastInsulinByAppIntent(),
            phrases: [
                "\(.applicationName) remove \(\.$unitsEnum) units",
                "\(.applicationName) decrease \(\.$unitsEnum) unit",
            ],
            shortTitle: "Decrease last insulin",
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
                "\(.applicationName) note sugar",
                "\(.applicationName) add sugar",
                "\(\.$sugarInGramsEnum) grams of sugar in \(.applicationName)",
                "\(.applicationName) \(\.$sugarInGramsEnum) gram",
                "\(.applicationName) \(\.$sugarInGramsEnum) grams",
                "\(\.$sugarInGramsEnum) gram \(.applicationName)",
                "\(\.$sugarInGramsEnum) grams \(.applicationName)",
            ],
            shortTitle: "Add sugar",
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
