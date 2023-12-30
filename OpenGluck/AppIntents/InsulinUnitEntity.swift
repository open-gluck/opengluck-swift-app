import AppIntents

/* 
 For some reasons Siri won't parse integers in intents but is glad to parse an enum, so here we go.
 We've defined our custom entity so that it can be queried and resolved from int and doubles, so as to help the user using Shortcuts.
 */

public struct InsulinUnitEntity: AppEntity {
    public let id: Int

    public static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(stringLiteral: "Integer")
    }
    
    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(id)")
    }
    
    public var value: Int {
        id
    }

    static public var defaultQuery = InsulinUnitEntityQuery()

    @ResolverSpecificationBuilder<Self>
    public static var defaultResolverSpecification: some ResolverSpecification {
        InsulinUnitStringResolver()
        InsulinUnitDoubleResolver()
        InsulinUnitIntResolver()
    }
}

public struct InsulinUnitEntityQuery: EntityQuery {
    public init() { }

    public func suggestedEntities() async throws -> [InsulinUnitEntity] {
        // Siri doesn't actually understand more than 28 combinations,
        // and ask for confirmation after. As each entity we provide
        // count against the cardinality of 1000 max phrases per app,
        // we limit to 27 here.
        (1..<27).map { InsulinUnitEntity(id: $0) }
    }

    public func entities(for identifiers: [Int]) async throws -> [InsulinUnitEntity] {
        identifiers.map { InsulinUnitEntity(id: $0) }
    }
}

public struct InsulinUnitStringResolver: Resolver {
    public func resolve(from input: String, context: IntentParameterContext<InsulinUnitEntity>) async throws -> InsulinUnitEntity? {
        return InsulinUnitEntity(id: Int(input)!)
    }
    
    public typealias Input = String
    public typealias Output = InsulinUnitEntity
}

public struct InsulinUnitDoubleResolver: Resolver {
    public func resolve(from input: Double, context: IntentParameterContext<InsulinUnitEntity>) async throws -> InsulinUnitEntity? {
        return InsulinUnitEntity(id: Int(round(input)))
    }
    
    public typealias Input = Double
    public typealias Output = InsulinUnitEntity
}

public struct InsulinUnitIntResolver: Resolver {
    public func resolve(from input: Int, context: IntentParameterContext<InsulinUnitEntity>) async throws -> InsulinUnitEntity? {
        return InsulinUnitEntity(id: input)
    }
    
    public typealias Input = Int
    public typealias Output = InsulinUnitEntity
}

extension InsulinUnitEntity: EntityIdentifierConvertible {
    public var entityIdentifierString: String {
        "\(self.id)"
    }
    
    public static func entityIdentifier(for entityIdentifierString: String) -> InsulinUnitEntity? {
        if let id = Int(entityIdentifierString) {
            InsulinUnitEntity(id: id)
        } else {
            nil
        }
    }
}
