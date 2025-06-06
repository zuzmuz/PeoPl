protocol TypeDefinitionChecker {
    func getTypeDeclarations() -> [Syntax.TypeDefinition]

    func resolveTypeSymbols(context: borrowing Semantic.Context) -> (
        typeDefinitions: [Semantic.ScopedIdentifier: (
            Syntax.TypeDefinition,
            Semantic.RawTypeSpecifier
        )],
        errors: [TypeSemanticError]
    )
}

extension Syntax.ScopedIdentifier {
    func getSemanticIdentifier() -> Semantic.ScopedIdentifier {
        return .init(chain: self.chain)
    }
}

extension Syntax.TypeSpecifier {
    func getTypeIdentifiers( /* TODO: handle namespacing */
    ) -> [Syntax.ScopedIdentifier] {
        switch self {
        case .nothing, .never:
            return []
        case let .nominal(nominal):
            return [nominal.identifier]
        case let .product(product):
            return product.typeFields.flatMap { $0.getTypeIdentifiers() }
        case let .sum(sum):
            return sum.typeFields.flatMap { $0.getTypeIdentifiers() }
        case let .function(function):
            return (function.inputType?.getTypeIdentifiers() ?? [])
                + function.arguments.flatMap { $0.getTypeIdentifiers() }
                + function.outputType.getTypeIdentifiers()
        default:  // TODO: all other types
            fatalError()
        }
    }

    func undefinedTypes(
        typeDefinitions: [Semantic.ScopedIdentifier: Syntax.TypeDefinition],
        context: borrowing Semantic.Context
    ) -> [Syntax.ScopedIdentifier] {
        self.getTypeIdentifiers().filter { typeIdentifier in
            let semanticIdentifier = typeIdentifier.getSemanticIdentifier()
            return typeDefinitions[semanticIdentifier] == nil
                && context.typeDefinitions[semanticIdentifier] == nil
        }
    }
}

extension Syntax.TypeField {
    func getTypeIdentifiers( /* namespace */
    ) -> [Syntax.ScopedIdentifier] {
        switch self {
        case let .typeSpecifier(typeSpecifier):
            return typeSpecifier.getTypeIdentifiers()
        case let .taggedTypeSpecifier(taggedTypeSpecifier):
            return taggedTypeSpecifier.type.getTypeIdentifiers()
        case let .homogeneousTypeProduct(homogeneousTypeProduct):
            return homogeneousTypeProduct.typeSpecifier.getTypeIdentifiers()
        }
    }
}

private enum NodeState {
    case visiting
    case visited
}

extension TypeDefinitionChecker {
    func resolveTypeSymbols(context: borrowing Semantic.Context) -> (
        typeDefinitions: Semantic.TypeDefinitionMap,
        errors: [TypeSemanticError]
    ) {
        let declarations = self.getTypeDeclarations()

        let typesLocations:
            [Semantic.ScopedIdentifier: [Syntax.TypeDefinition]] =
                declarations.reduce(into: [:]) { acc, type in
                    let semanticIdentifer = Semantic.ScopedIdentifier(
                        chain: type.identifier.chain)
                    acc[semanticIdentifer] =
                        (acc[semanticIdentifer] ?? []) + [type]
                }

        // detecting redeclarations
        let redeclarations = typesLocations.compactMap { _, typeLocations in
            if typeLocations.count > 1 {
                return TypeSemanticError.redeclaration(types: typeLocations)
            } else {
                return nil
            }
        }

        let types = typesLocations.compactMapValues { types in
            return types.first
        }

        // TODO: detecting shadowings

        // detecting invalid members types
        let typesNotInScope = types.flatMap { _, definition in
            return definition.definition.undefinedTypes(
                typeDefinitions: types, context: context)
        }.map { TypeSemanticError.typeNotInScope(type: $0) }

        // detecting cyclical dependencies
        let cyclicalDependencies = checkCyclicalDependencies(
            typeDefinitions: types, context: context)

        return (
            typeDefinitions: [:],
            errors: redeclarations + typesNotInScope + cyclicalDependencies
        )
    }

    private func checkCyclicalDependencies(
        typeDefinitions: [Semantic.ScopedIdentifier: Syntax.TypeDefinition],
        context: borrowing Semantic.Context
    ) -> [TypeSemanticError] {
        var nodeStates: [Syntax.ScopedIdentifier: NodeState] = [:]
        var errors: [TypeSemanticError] = []

        func checkCyclicalDependencies(typeSpecifier: Syntax.TypeSpecifier) {
            switch typeSpecifier {
            case .nothing, .never:
                break
            case let .nominal(nominal):
                checkCyclicalDependencies(
                    typeDefinition: typeDefinitions[
                        nominal.identifier.getSemanticIdentifier()]!)
            case let .product(product):
                product.typeFields.forEach { field in
                    switch field {
                    case let .typeSpecifier(typeSpecifier):
                        checkCyclicalDependencies(
                            typeSpecifier: typeSpecifier)
                    case let .taggedTypeSpecifier(taggedTypeSpecifier):
                        checkCyclicalDependencies(
                            typeSpecifier: taggedTypeSpecifier.type)
                    case let .homogeneousTypeProduct(homogeneousTypeProduct):
                        checkCyclicalDependencies(
                            typeSpecifier: homogeneousTypeProduct.typeSpecifier)
                    }
                }
            case let .sum(sum):
                sum.typeFields.forEach { field in
                    switch field {
                    case let .typeSpecifier(typeSpecifier):
                        checkCyclicalDependencies(
                            typeSpecifier: typeSpecifier)
                    case let .taggedTypeSpecifier(taggedTypeSpecifier):
                        checkCyclicalDependencies(
                            typeSpecifier: taggedTypeSpecifier.type)
                    case .homogeneousTypeProduct:
                        errors.append(
                            // TODO: consider cleaning up where this check is done
                            .homogeneousTypeProductInSum(
                                type: typeSpecifier, field: field))
                    }
                }
            default:
                fatalError()
            }
        }

        func checkCyclicalDependencies(typeDefinition: Syntax.TypeDefinition) {
            let typeIdentifier = typeDefinition.identifier
            if nodeStates[typeIdentifier] == .visited {
                return
            }
            if nodeStates[typeIdentifier] == .visiting {
                errors.append(
                    .cyclicType(
                        type: typeDefinition, cyclicType: typeIdentifier))
                return
            }
            nodeStates[typeIdentifier] = .visiting

            checkCyclicalDependencies(typeSpecifier: typeDefinition.definition)

        }

        typeDefinitions.forEach { _, typeDefinition in
            checkCyclicalDependencies(typeDefinition: typeDefinition)
        }

        return errors
    }
}
