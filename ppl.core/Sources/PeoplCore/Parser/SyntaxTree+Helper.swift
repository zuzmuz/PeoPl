extension Syntax.TypeSpecifier: Sequence {
    static func simpleNominalType(name: String) -> Syntax.TypeSpecifier {
        return .nominal(
            .init(chain: [name], location: .nowhere)
        )
    }
    static func nestedNominalType(names: [String]) -> Syntax.TypeSpecifier {
        return .nominal(
            .init(chain: names, location: .nowhere)
        )
    }
    static func simpleTuple(names: [String]) -> Syntax.TypeSpecifier {
        return .unnamedTuple(
            .init(
                types: names.map { name in
                    Syntax.TypeSpecifier.simpleNominalType(name: name)
                },
                location: .nowhere)
        )
    }
    static func simpleNamedTuple(
        names: [(String, String)]
    ) -> Syntax.TypeSpecifier {
        return .namedTuple(
            .init(
                types: names.map { argument, name in
                    Syntax.ParamDefinition(
                        name: argument,
                        type: Syntax.TypeSpecifier.simpleNominalType(
                            name: name),
                        location: .nowhere)
                },
                location: .nowhere)
        )
    }

    func makeIterator() -> TypeIdentifierIterator {
        return TypeIdentifierIterator(self)
    }

    func getNominalTypesFromIdentifier() -> [Syntax.NominalType] {
        // NOTE: this might not be efficient
        switch self {
        case let .nominal(nominal):
            return [nominal]
        case let .unnamedTuple(tuple):
            return tuple.types.flatMap { $0.getNominalTypesFromIdentifier() }
        case let .namedTuple(tuple):
            return tuple.types.flatMap {
                $0.type.getNominalTypesFromIdentifier()
            }
        default:
            return []
        }
    }
}

struct TypeIdentifierIterator: IteratorProtocol {
    private var content: [Syntax.TypeSpecifier]
    private var index: Int = 0

    init(_ typeIdentifier: Syntax.TypeSpecifier) {
        switch typeIdentifier {
        case .nothing, .never, .nominal:
            content = [typeIdentifier]
        case let .unnamedTuple(tuple):
            content = tuple.types
        case let .namedTuple(tuple):
            content = tuple.types.map { $0.type }
        }
    }

    mutating func next() -> Syntax.TypeSpecifier? {
        guard index < content.count else { return nil }
        defer { index += 1 }
        return content[index]
    }
}

extension Syntax.Expression {
    static let empty = Syntax.Expression(
        expressionType: .literal(.nothing),
        location: .nowhere)
    static let never = Syntax.Expression(
        expressionType: .literal(.never),
        location: .nowhere)
}
