import AppIntents

/*
 For some reasons Siri won't parse integers in intents but is glad to parse an enum, so here we go.
 We've defined our custom entity so that it can be queried and resolved from int and doubles, so as to help the user using Shortcuts.
 */

public struct SugarInGramsEntityIdentifier: EntityIdentifierConvertible, Sendable, Identifiable {
    public let id: Double
    
    init(id: Double) {
        self.id = id
    }
    
    public static func entityIdentifier(for entityIdentifierString: String) -> SugarInGramsEntityIdentifier? {
        if let id = Double(entityIdentifierString) {
            return Self(id: id)
        } else {
            return nil
        }
    }
    
    public var entityIdentifierString: String {
        abs(round(id) - id) < Double.ulpOfOne ? "\(Int(round(id)))" : "\(id)"
    }
}

public struct SugarInGramsEntity: AppEntity {
    public let entityId: SugarInGramsEntityIdentifier
    
    init(id: Double) {
        self.entityId = SugarInGramsEntityIdentifier(id: id)
    }
    
    init(entityId: SugarInGramsEntityIdentifier) {
        self.entityId = entityId
    }
    
    public var id: String {
        entityId.entityIdentifierString
    }
    
    public var value: Double {
        entityId.id
    }

    public static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(stringLiteral: "Double")
    }
    
    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(id)")
    }
    
    static public var defaultQuery = SugarInGramsEntityQuery()

    @ResolverSpecificationBuilder<Self>
    public static var defaultResolverSpecification: some ResolverSpecification {
        SugarInGramsStringResolver()
        SugarInGramsDoubleResolver()
        SugarInGramsIntResolver()
    }
}

public struct SugarInGramsEntityQuery: EntityQuery {
    public init() { }

    public func suggestedEntities() async throws -> [SugarInGramsEntity] {
        stride(from: 5.0, through: 30.0, by: 5.0).map { SugarInGramsEntity(id: $0) }
    }

    public func entities(for identifiers: [String]) async throws -> [SugarInGramsEntity] {
        identifiers.map { SugarInGramsEntity(id: Double($0)!) }
    }
}

public struct SugarInGramsStringResolver: Resolver {
    public func resolve(from input: String, context: IntentParameterContext<SugarInGramsEntity>) async throws -> SugarInGramsEntity? {
        if let id = Double(input) {
            SugarInGramsEntity(id: id)
        } else {
            nil
        }
    }
    
    public typealias Input = String
    public typealias Output = SugarInGramsEntity
}

public struct SugarInGramsDoubleResolver: Resolver {
    public func resolve(from input: Double, context: IntentParameterContext<SugarInGramsEntity>) async throws -> SugarInGramsEntity? {
        return SugarInGramsEntity(id: Double(input))
    }
    
    public typealias Input = Double
    public typealias Output = SugarInGramsEntity
}

public struct SugarInGramsIntResolver: Resolver {
    public func resolve(from input: Int, context: IntentParameterContext<SugarInGramsEntity>) async throws -> SugarInGramsEntity? {
        return SugarInGramsEntity(id: Double(input))
    }
    
    public typealias Input = Int
    public typealias Output = SugarInGramsEntity
}

extension SugarInGramsEntity: EntityIdentifierConvertible {
    public var entityIdentifierString: String {
        "\(self.id)"
    }
    
    public static func entityIdentifier(for entityIdentifierString: String) -> SugarInGramsEntity? {
        if let id = Double(entityIdentifierString) {
            SugarInGramsEntity(id: id)
        } else {
            nil
        }
    }
}
