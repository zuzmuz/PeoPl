protocol TypeDeclarationChecker {

    /// Returns all declared types in context
    /// Can contain duplicates, and illegal type definitions
    func getTypeDeclarations() -> [Syntax.TypeDefinition]

    /// Sanitize type definitions by removing duplicate declarations
    /// Verify type definitions by detecting invalid types identifiers for members
    /// Detect circular dependencies in type definitions,
    /// because types are inline value types
    /// Types do not support indirection (without wrappers)
    /// - Paramerter environment: The existing semantic context,
    /// contains builtin (for now) NOTE: extend with library packages
    /// - Returns: A tuple containing the sanitized type definitions and any errors that occurred
    func resolveTypeDefinitions(
        externals: borrowing [String: SemanticContext]
    ) -> (
        typesDefinitions: [Syntax.NominalType: Syntax.TypeDefinition],
        errors: [TypeSemanticError]
    )
}

private enum NodeState {
    case visiting
    case visited
}

extension Syntax.TypeSpecifier {
    func typeDefiniedInContext(
        typesDefinitions: [Typed.TypeIdentifier: Syntax.TypeDefinition],
        externals: borrowing [String: SemanticContext]
    ) -> [Syntax.NominalType] {
        self.getNominalTypesFromIdentifier().filter { type in
            typesDefinitions[type.typeName] == nil
                && externals.typeDefinedInContext(
                    typeName: type.typeName) == nil
        }
    }
}

extension [String: SemanticContext] {
    func typeDefinedInContext(
        typeName: Typed.TypeIdentifier
    ) -> [String: SemanticContext].Element? {
        self.first { _, externalTypes in
            externalTypes.types[typeName] != nil
        }
    }
}

extension TypeDeclarationChecker {

    func resolveTypeDefinitions(
        externals: borrowing [String: SemanticContext]
    ) -> (
        typesDefinitions: [Typed.TypeIdentifier: Syntax.TypeDefinition],
        errors: [TypeSemanticError]
    ) {
        let declarations = self.getTypeDeclarations()

        let typesLocations = declarations.reduce(into: [:]) { acc, type in
            // NOTE: namespacing not supported yet
            acc[type.identifier] = (acc[type.identifier] ?? []) + [type]
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

        // detecting shadowings
        let shadowings = types.compactMap { type, typeDefinition in

            if let shadowedModule = externals.typeDefinedInContext(
                typeName: type.typeName)?.key
            {
                return TypeSemanticError.shadowing(
                    type: typeDefinition,
                    module: shadowedModule)
            } else {
                return nil
            }
        }

        let typesDefinitions = types.reduce(into: [:]) { acc, type in
            acc[type.key.typeName] = type.value
        }

        // detecting invalid members types
        let typesNotInScope = types.flatMap { _, definition in
            return definition.allParams.flatMap { param in
                let errors: [TypeSemanticError] =
                    param.type.typeDefiniedInContext(
                        typesDefinitions: typesDefinitions,
                        externals: externals
                    ).map { nominalType in
                        TypeSemanticError.typeNotInScope(type: nominalType)
                    }
                return errors
            }
        }

        let cyclicalDependencies = checkCyclicalDependencies(
            types: types, externals: externals)

        return (
            typesDefinitions: typesDefinitions,
            errors: redeclarations + shadowings + typesNotInScope
                + cyclicalDependencies
        )
    }

    private func checkCyclicalDependencies(
        types: [Syntax.NominalType: Syntax.TypeDefinition],
        externals: [String: SemanticContext]
    ) -> [TypeSemanticError] {

        var nodeStates: [Typed.TypeIdentifier: NodeState] = [:]
        var cycles: [TypeSemanticError] = []

        func checkCyclicalDependency(typeSpecifier: Syntax.TypeSpecifier) {
            switch typeSpecifier {
            case let .nominal(nominal):
                checkCyclicalDependency(nominal: nominal)
            case let .unnamedTuple(tuple):
                tuple.types.forEach { typeIdentifier in
                    checkCyclicalDependency(typeSpecifier: typeIdentifier)
                }
            case let .namedTuple(tuple):
                tuple.types.forEach { tupleParam in
                    checkCyclicalDependency(typeSpecifier: tupleParam.type)
                }
            default:
                break
            }
        }

        func checkCyclicalDependency(nominal: Syntax.NominalType) {
            let typeName = nominal.typeName
            if nodeStates[typeName] == .visited {
                return
            }
            if nodeStates[typeName] == .visiting {
                cycles.append(.cyclicType(cyclicType: nominal))
                return
            }
            nodeStates[typeName] = .visiting
            guard
                let typeDefinition = types[nominal]
                    ?? externals.typeDefinedInContext(
                        typeName: typeName)?.value.types[typeName]
            else { return }

            switch typeDefinition {
            case let .simple(simple):
                simple.params.forEach { param in
                    checkCyclicalDependency(typeSpecifier: param.type)
                }
            case let .sum(sum):
                sum.cases.forEach { simpleCase in
                    simpleCase.params.forEach { param in
                        checkCyclicalDependency(typeSpecifier: param.type)
                    }
                }
            }
            nodeStates[typeName] = .visited
        }

        types.forEach { nominal, _ in
            checkCyclicalDependency(nominal: nominal)
        }

        return cycles
    }
}
