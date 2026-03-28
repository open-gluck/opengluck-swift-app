import AppIntents

enum InsulinUnitEnum: Int, Codable, Sendable, CaseIterable {
    case one = 1, two, three, four, five
    case six, seven, eight, nine, ten
    case eleven, twelve, thirteen, fourteen, fifteen
    case sixteen, seventeen, eighteen, nineteen, twenty
    case twentyOne, twentyTwo, twentyThree, twentyFour, twentyFive
    case twentySix, twentySeven, twentyEight, twentyNine

    var units: Int { rawValue }
}

extension InsulinUnitEnum: AppEnum {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Insulin Unit"

    static let caseDisplayRepresentations: [InsulinUnitEnum: DisplayRepresentation] = [
        .one: DisplayRepresentation(title: "one", synonyms: ["1"]),
        .two: DisplayRepresentation(title: "two", synonyms: ["2"]),
        .three: DisplayRepresentation(title: "three", synonyms: ["3"]),
        .four: DisplayRepresentation(title: "four", synonyms: ["4"]),
        .five: DisplayRepresentation(title: "five", synonyms: ["5"]),
        .six: DisplayRepresentation(title: "six", synonyms: ["6"]),
        .seven: DisplayRepresentation(title: "seven", synonyms: ["7"]),
        .eight: DisplayRepresentation(title: "eight", synonyms: ["8"]),
        .nine: DisplayRepresentation(title: "nine", synonyms: ["9"]),
        .ten: DisplayRepresentation(title: "ten", synonyms: ["10"]),
        .eleven: DisplayRepresentation(title: "eleven", synonyms: ["11"]),
        .twelve: DisplayRepresentation(title: "twelve", synonyms: ["12"]),
        .thirteen: DisplayRepresentation(title: "thirteen", synonyms: ["13"]),
        .fourteen: DisplayRepresentation(title: "fourteen", synonyms: ["14"]),
        .fifteen: DisplayRepresentation(title: "fifteen", synonyms: ["15"]),
        .sixteen: DisplayRepresentation(title: "sixteen", synonyms: ["16"]),
        .seventeen: DisplayRepresentation(title: "seventeen", synonyms: ["17"]),
        .eighteen: DisplayRepresentation(title: "eighteen", synonyms: ["18"]),
        .nineteen: DisplayRepresentation(title: "nineteen", synonyms: ["19"]),
        .twenty: DisplayRepresentation(title: "twenty", synonyms: ["20"]),
        .twentyOne: DisplayRepresentation(title: "twenty-one", synonyms: ["21"]),
        .twentyTwo: DisplayRepresentation(title: "twenty-two", synonyms: ["22"]),
        .twentyThree: DisplayRepresentation(title: "twenty-three", synonyms: ["23"]),
        .twentyFour: DisplayRepresentation(title: "twenty-four", synonyms: ["24"]),
        .twentyFive: DisplayRepresentation(title: "twenty-five", synonyms: ["25"]),
        .twentySix: DisplayRepresentation(title: "twenty-six", synonyms: ["26"]),
        .twentySeven: DisplayRepresentation(title: "twenty-seven", synonyms: ["27"]),
        .twentyEight: DisplayRepresentation(title: "twenty-eight", synonyms: ["28"]),
        .twentyNine: DisplayRepresentation(title: "twenty-nine", synonyms: ["29"]),
    ]
}
