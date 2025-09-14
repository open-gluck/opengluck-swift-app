import AppIntents

/*
 For some reasons Siri won't parse integers in intents but is glad to parse an enum, so here we go.
 */

enum SugarInGramsEnum: String, Codable, Sendable {
    case value1 = "1"
    case value2 = "2"
    case value3 = "3"
    case value4 = "4"
    case value5 = "5"
    case value6 = "6"
    case value7 = "7"
    case value8 = "8"
    case value9 = "9"
    case value10 = "10"
    case value11 = "11"
    case value12 = "12"
    case value13 = "13"
    case value14 = "14"
    case value15 = "15"
    case value16 = "16"
    case value17 = "17"
    case value18 = "18"
    case value19 = "19"
    case value20 = "20"
    case value21 = "21"
    case value22 = "22"
    case value23 = "23"
    case value24 = "24"
    case value25 = "25"
    case value26 = "26"
    case value27 = "27"
    case value28 = "28"
    case value29 = "29"
}

extension SugarInGramsEnum: AppEnum {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = TypeDisplayRepresentation(stringLiteral: "Sugar in grams")
    
    static let caseDisplayRepresentations: [SugarInGramsEnum : DisplayRepresentation] = [
        .value1 : DisplayRepresentation(stringLiteral: "1"),
        .value2 : DisplayRepresentation(stringLiteral: "2"),
        .value3 : DisplayRepresentation(stringLiteral: "3"),
        .value4 : DisplayRepresentation(stringLiteral: "4"),
        .value5 : DisplayRepresentation(stringLiteral: "5"),
        .value6 : DisplayRepresentation(stringLiteral: "6"),
        .value7 : DisplayRepresentation(stringLiteral: "7"),
        .value8 : DisplayRepresentation(stringLiteral: "8"),
        .value9 : DisplayRepresentation(stringLiteral: "9"),
        .value10 : DisplayRepresentation(stringLiteral: "10"),
        .value11 : DisplayRepresentation(stringLiteral: "11"),
        .value12 : DisplayRepresentation(stringLiteral: "12"),
        .value13 : DisplayRepresentation(stringLiteral: "13"),
        .value14 : DisplayRepresentation(stringLiteral: "14"),
        .value15 : DisplayRepresentation(stringLiteral: "15"),
        .value16 : DisplayRepresentation(stringLiteral: "16"),
        .value17 : DisplayRepresentation(stringLiteral: "17"),
        .value18 : DisplayRepresentation(stringLiteral: "18"),
        .value19 : DisplayRepresentation(stringLiteral: "19"),
        .value20 : DisplayRepresentation(stringLiteral: "20"),
        .value21 : DisplayRepresentation(stringLiteral: "21"),
        .value22 : DisplayRepresentation(stringLiteral: "22"),
        .value23 : DisplayRepresentation(stringLiteral: "23"),
        .value24 : DisplayRepresentation(stringLiteral: "24"),
        .value25 : DisplayRepresentation(stringLiteral: "25"),
        .value26 : DisplayRepresentation(stringLiteral: "26"),
        .value27 : DisplayRepresentation(stringLiteral: "27"),
        .value28 : DisplayRepresentation(stringLiteral: "28"),
        .value29 : DisplayRepresentation(stringLiteral: "29"),
    ]
    
    static let allCases: [SugarInGramsEnum] = [
        .value1,
        .value2,
        .value3,
        .value4,
        .value5,
        .value6,
        .value7,
        .value8,
        .value9,
        .value10,
        .value11,
        .value12,
        .value13,
        .value14,
        .value15,
        .value16,
        .value17,
        .value18,
        .value19,
        .value20,
        .value21,
        .value22,
        .value23,
        .value24,
        .value25,
        .value26,
        .value27,
        .value28,
        .value29
    ]
}
