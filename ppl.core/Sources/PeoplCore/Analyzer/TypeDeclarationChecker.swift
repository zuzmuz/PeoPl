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
        builtins: borrowing SemanticContext // NOTE: builtins can be merged with expternals once we figure out namespacing
        // externals: borrowing [String: SemanticContext]
    ) -> (
        typesDefinitions: [Syntax.NominalType: Syntax.TypeDefinition],
        errors: [TypeSemanticError]
    )
}

fileprivate enum NodeState {
    case visiting
    case visited
}

extension TypeDeclarationChecker {

    func resolveTypeDefinitions(
        core: borrowing SemanticContext
        // externals: borrowing [String: SemanticContext]
    ) -> (
        typesDefinitions: [Typed.TypeIdentifier: Syntax.TypeDefinition],
        errors: [TypeSemanticError]
    ) {
        let declarations = self.getTypeDeclarations()

        let typesLocations = declarations.reduce(into: [:]) { acc, type in
            // NOTE: namespacing not supported yet
            acc[type.identifier.typeName] = (acc[type.identifier.typeName] ?? []) + [type]
        }
        
        // detecting redeclarations
        let redeclarations = typesLocations.compactMap { _, typeLocations in
            if typeLocations.count > 1 {
                return TypeSemanticError.redeclaration(locations: typeLocations)
            } else {
                return nil
            }
        }

        let types = typesLocations.compactMapValues { types in
            return types.first
        }

        // detecting shadowings
        let shadowings = types.compactMap { type, typeDefinition in
            
            if let exisitingType = core.types[type] {
                return TypeSemanticError.shadowing(
                    type: typeDefinition,
                    module: "core")
            // } else if let exisitingType = externals.values.compactMap({ $0.types[type] }).first {
            //     return TypeSemanticError.shadowing(
            //         location: typeDefinition.location,
            //         module: "someone", // NOTE: I need to fix this so that I get the module name
            //         typeDefinition: exisitingType)
            } else {
                return nil
            }
        }

        // detecting invalid members types
        let typesNotInScope = types.flatMap { type, definition in
            return definition.allParams.flatMap { param in
                let errors: [TypeSemanticError] = param.type.getNominalTypesFromIdentifier().compactMap { type in
                    let typeName = type.typeName
                    if types[typeName] != nil || core.types[typeName] != nil {
                        return nil
                    } else {
                        return .typeNotInScope(type: type)
                    }
                }
                return errors
            }
        }

        let cyclicalDependencies = checkCyclicalDependencies(types: types, core: core)

        return (
            typesDefinitions: types,
            errors: redeclarations + shadowings + typesNotInScope + cyclicalDependencies
        )
    }

    private func checkCyclicalDependencies(
        types: [Typed.TypeIdentifier: Syntax.TypeDefinition],
        core: SemanticContext
    ) -> [TypeSemanticError] {
        
        var nodeStates: [Typed.TypeIdentifier: NodeState] = [:]
        var cycles: [TypeSemanticError] = []

        func checkCyclicalDependency(typeIdentifier: Syntax.TypeSpecifier) {
            switch typeIdentifier {
            case let .nominal(nominal):
                checkCyclicalDependency(nominal: nominal)
            case let .unnamedTuple(tuple):
                tuple.types.forEach { typeIdentifier in
                    checkCyclicalDependency(typeIdentifier: typeIdentifier)
                }
            case let .namedTuple(tuple):
                tuple.types.forEach { tupleParam in
                    checkCyclicalDependency(typeIdentifier: tupleParam.type)
                }
            default:
                break
            }
        }

        func checkCyclicalDependency(typeName: Typed.TypeIdentifier) {
            if nodeStates[typeName] == .visited {
                return
            }
            if nodeStates[typeName] == .visiting {
                cycles.append(.cyclicType(cyclicType: nominal))
                return 
            }
            nodeStates[typeName] = .visiting
            guard let typeDefinition = types[typeName] ?? core.types[nominal] else { return /*type checker should catch this error*/ }

            switch typeDefinition {
            case let .simple(simple):
                simple.params.forEach { param in
                    checkCyclicalDependency(typeIdentifier: param.type)
                }
            case let .sum(sum):
                sum.cases.forEach { simpleCase in
                    simpleCase.params.forEach { param in
                        checkCyclicalDependency(typeIdentifier: param.type)
                    }
                }
            }
            nodeStates[typeName] = .visited
        }
        
        types.forEach { nominal, typeDefinition in
            checkCyclicalDependency(nominal: nominal)
        }

        return cycles
    }
}

