import AppIntents

struct AppsShortcuts: AppShortcutsProvider {
    @AppShortcutsBuilder
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddInsulinAppIntent(),
            phrases: [
                "\(.applicationName) \(\.$unitsEntity) insulin unit",
                "\(.applicationName) \(\.$unitsEntity) insulin units",
                "\(.applicationName) \(\.$unitsEntity) insulin",
                "\(.applicationName) \(\.$unitsEntity) insulins",
                "\(.applicationName) \(\.$unitsEntity) unit",
                "\(.applicationName) \(\.$unitsEntity) units",
            ],
            shortTitle: "Add insulin",
            systemImageName: "cross.vial"
        )
        AppShortcut(
            intent: AddLowAppIntent(),
            phrases: [
                "\(.applicationName) \(\.$sugarInGramsEntity) grams",
                "\(.applicationName) \(\.$sugarInGramsEntity) grams of sugar",
                "\(.applicationName) \(\.$sugarInGramsEntity) gram",
            ],
            shortTitle: "Add sugar",
            systemImageName: "takeoutbag.and.cup.and.straw"
        )
    }
}
