
extension TypeIdentifier {
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
}
