
extension Syntax.TypeIdentifier: Sequence {
    static func simpleNominalType(name: String) -> Syntax.TypeIdentifier {
        return .nominal(
            .init(chain: [.init(typeName: name, typeArguments: [], location: .nowhere)], location: .nowhere)
        )
    }
    static func nestedNominalType(names: [String]) -> Syntax.TypeIdentifier {
        return .nominal(
            .init(chain: names.map { name in
                Syntax.FlatNominalType(typeName: name, typeArguments: [], location: .nowhere)
            },
            location: .nowhere)
        )
    }
    static func simpleTuple(names: [String]) -> Syntax.TypeIdentifier {
        return .unnamedTuple(.init(
            types: names.map { name in
                Syntax.TypeIdentifier.simpleNominalType(name: name)
            },
            location: .nowhere)
        )
    }
    static func simpleNamedTuple(names: [(String, String)]) -> Syntax.TypeIdentifier {
        return .namedTuple(.init(
            types: names.map { argument, name in
                Syntax.ParamDefinition(
                    name: argument,
                    type: Syntax.TypeIdentifier.simpleNominalType(name: name),
                    location: .nowhere)
            },
            location: .nowhere)
        )
    }
    static func simpleLambda(inputs: [String], output: String) -> Syntax.TypeIdentifier {
        return .lambda( .init(
            input: inputs.map { Syntax.TypeIdentifier.simpleNominalType(name: $0) },
            output: [Syntax.TypeIdentifier.simpleNominalType(name: output)],
            location: .nowhere))
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
            return tuple.types.flatMap { $0.type.getNominalTypesFromIdentifier() }
        case let .lambda(lambda):
            return (lambda.input + lambda.output).flatMap { $0.getNominalTypesFromIdentifier() }
        case let .union(union):
            return union.types.flatMap { $0.getNominalTypesFromIdentifier() }
        default:
            return []
        }
    }
}

struct TypeIdentifierIterator: IteratorProtocol {
    private var content: [Syntax.TypeIdentifier]
    private var index: Int = 0

    init(_ typeIdentifier: Syntax.TypeIdentifier) {
        switch typeIdentifier {
        case .nothing, .never, .nominal, .lambda, .union:
            content = [typeIdentifier]
        case let .unnamedTuple(tuple):
            content = tuple.types
        case let .namedTuple(tuple):
            content = tuple.types.map { $0.type }
        }
    }

    mutating func next() -> Syntax.TypeIdentifier? {
        guard index < content.count else { return nil }
        defer { index += 1 }
        return content[index]
    }
}

extension Syntax.Expression {
    static let empty = Syntax.Expression(expressionType: .nothing, location: .nowhere)
    static let never = Syntax.Expression(expressionType: .never, location: .nowhere)
}
