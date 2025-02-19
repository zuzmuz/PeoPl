
extension TypeIdentifier: Sequence {
    static func simpleNominalType(name: String) -> TypeIdentifier {
        return .nominal(
            .init(chain: [.init(typeName: name, typeArguments: [], location: .nowhere)], location: .nowhere)
        )
    }
    static func nestedNominalType(names: [String]) -> TypeIdentifier {
        return .nominal(
            .init(chain: names.map { name in
                FlatNominalType(typeName: name, typeArguments: [], location: .nowhere)
            }, location: .nowhere)
        )
    }
    static func simpleTuple(names: [String]) -> TypeIdentifier {
        return .unnamedTuple(.init(
            types: names.map { name in
                TypeIdentifier.simpleNominalType(name: name)
            },
            location: .nowhere)
        )
    }
    static func simpleNamedTuple(names: [(String, String)]) -> TypeIdentifier {
        return .namedTuple(.init(
            types: names.map { argument, name in
                ParamDefinition(
                    name: argument,
                    type: TypeIdentifier.simpleNominalType(name: name),
                    location: .nowhere)
            },
            location: .nowhere)
        )
    }
    static func simpleLambda(inputs: [String], output: String) -> TypeIdentifier {
        return .lambda( .init(
            input: inputs.map { TypeIdentifier.simpleNominalType(name: $0) },
            output: [TypeIdentifier.simpleNominalType(name: output)],
            location: .nowhere))
    }

    func makeIterator() -> TypeIdentifierIterator {
        return TypeIdentifierIterator(self)
    }

    func getNominalTypesFromIdentifier() -> [NominalType] {
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
    private var content: [TypeIdentifier]
    private var index: Int = 0

    init(_ typeIdentifier: TypeIdentifier) {
        switch typeIdentifier {
        case .unkown, .nothing, .never, .nominal, .lambda, .union:
            content = [typeIdentifier]
        case let .unnamedTuple(tuple):
            content = tuple.types
        case let .namedTuple(tuple):
            content = tuple.types.map { $0.type }
        }
    }

    mutating func next() -> TypeIdentifier? {
        guard index < content.count else { return nil }
        defer { index += 1 }
        return content[index]
    }
}

extension Expression {
    static let empty = Expression(expressionType: .nothing, location: .nowhere, typeIdentifier: .nothing())
    static let never = Expression(expressionType: .never, location: .nowhere, typeIdentifier: .never())
}
