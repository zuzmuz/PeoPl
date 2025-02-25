struct LocalScope {
    let fields: [String: TypeIdentifier]
}

/// Contains the semantic context of a module
struct SemanticContext {
    let types: [NominalType: TypeDefinition]
    let functions: [FunctionDefinition: FunctionDefinition]
    let functionsIdentifiers: [FunctionIdentifier: [FunctionDefinition]]
    let functionsInputTypeIdentifiers: [TypeIdentifier: [FunctionDefinition]]
    let operators: [OperatorOverloadDefinition: OperatorOverloadDefinition]
}


protocol TypeDeclarationChecker {

    /// Returns all declared types in context
    /// Can contain duplicates, and illegal type definitions
    func getTypeDeclarations() -> [TypeDefinition]

    /// Sanitize type definitions by removing duplicate declarations
    /// Verify type definitions by detecting invalid types identifiers for members
    /// Detect circular dependencies in type definitions,
    /// because types are inline value types
    /// Types do not support indirection (without wrappers)
    /// - Paramerter environment: The existing semantic context,
    /// contains builtin (for now) TODO: extend with library packages
    /// - Returns: A tuple containing the sanitized type definitions and any errors that occurred
    func resolveTypeDefinitions(
        builtins: borrowing SemanticContext // TODO: builtins can be merged with expternals once we figure out namespacing
        // externals: borrowing [String: SemanticContext]
    ) -> (
        typesDefinitions: [NominalType: TypeDefinition],
        errors: [TypeSemanticError]
    )
}

enum NodeState {
    case visiting
    case visited
}

extension TypeDeclarationChecker {

    func resolveTypeDefinitions(
        builtins: borrowing SemanticContext
        // externals: borrowing [String: SemanticContext]
    ) -> (
        typesDefinitions: [NominalType: TypeDefinition],
        errors: [TypeSemanticError]
    ) {
        let declarations = self.getTypeDeclarations()

        let typesLocations = declarations.reduce(into: [:]) { acc, type in
            acc[type.identifier] = (acc[type.identifier] ?? []) + [type]
        }
        
        // detecting redeclarations
        let redeclarations = typesLocations.compactMap { _, typeLocations in
            if typeLocations.count > 1 {
                return TypeSemanticError.redeclaration(locations: typeLocations.map { $0.location })
            } else {
                return nil
            }
        }

        let types = typesLocations.compactMapValues { types in
            return types.first
        }

        // detecting shadowings
        let shadowings = types.compactMap { type, typeDefinition in
            if let exisitingType = builtins.types[type] {
                return TypeSemanticError.shadowing(
                    location: typeDefinition.location,
                    module: "builtin",
                    typeDefinition: exisitingType)
            // } else if let exisitingType = externals.values.compactMap({ $0.types[type] }).first {
            //     return TypeSemanticError.shadowing(
            //         location: typeDefinition.location,
            //         module: "someone", // TODO: I need to fix this so that I get the module name
            //         typeDefinition: exisitingType)
            } else {
                return nil
            }
        }

        // detecting invalid members types
        let typesNotInScope = types.flatMap { type, definition in
            return definition.allParams.flatMap { param in
                let errors: [TypeSemanticError] = param.type.getNominalTypesFromIdentifier().compactMap { paramType in
                    if let _ = types[paramType] ?? builtins.types[paramType] {
                        return nil
                    } else {
                    return TypeSemanticError.typeNotInScope(
                        location: param.location,
                        type: paramType,
                        typesInScope: types.keys)
                    }
                }
                return errors
            }
        }

        let cyclicalDependencies = checkCyclicalDependencies(types: types)    

        return (
            typesDefinitions: types,
            errors: redeclarations + shadowings + typesNotInScope + cyclicalDependencies
        )
    }

    private func checkCyclicalDependencies(types: [NominalType: TypeDefinition]) -> [TypeSemanticError] {
        
        var nodeStates: [NominalType: NodeState] = [:]
        var cycles: [TypeSemanticError] = []

        func checkCyclicalDependency(typeIdentifier: TypeIdentifier) {
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
            case let .union(union):
                union.types.forEach { typeIdentifier in
                    checkCyclicalDependency(typeIdentifier: typeIdentifier)
                }
            default:
                break
            }
        }

        func checkCyclicalDependency(nominal: NominalType) {
            if nodeStates[nominal] == .visited {
                return
            }
            if nodeStates[nominal] == .visiting {
                cycles.append(.cyclicType(cyclicType: nominal))
                return 
            }
            nodeStates[nominal] = .visiting
            guard let typeDefinition = types[nominal] else { return /*type checker should catch this error*/ }

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
            nodeStates[nominal] = .visited
        }
        
        types.forEach { nominal, typeDefinition in
            checkCyclicalDependency(nominal: nominal)
        }

        return cycles
    }
}

protocol FunctionDeclarationChecker {
    func getFunctionDeclarations() -> [FunctionDefinition]
    func getOperatorOverloadDeclarations() -> [OperatorOverloadDefinition]

    func resolveFunctionDefinitions(
        context: borrowing SemanticContext,
        builtins: borrowing SemanticContext
    ) -> (
        functions: [FunctionDefinition: FunctionDefinition],
        functionsIdentifiers: [FunctionIdentifier: [FunctionDefinition]],
        functionsInputTypeIdentifiers: [TypeIdentifier: [FunctionDefinition]],
        operators: [OperatorOverloadDefinition: OperatorOverloadDefinition],
        errors: [FunctionSemanticError]
    )
}

extension FunctionDeclarationChecker {
    func resolveFunctionDefinitions(
        context: borrowing SemanticContext,
        builtins: borrowing SemanticContext
    ) -> (
        functions: [FunctionDefinition: FunctionDefinition],
        functionsIdentifiers: [FunctionIdentifier: [FunctionDefinition]],
        functionsInputTypeIdentifiers: [TypeIdentifier: [FunctionDefinition]],
        operators: [OperatorOverloadDefinition: OperatorOverloadDefinition],
        errors: [FunctionSemanticError]
    ) {

        let functionDeclarations = self.getFunctionDeclarations()
        let (functions, functionsRedeclarations) = resolveDefinitions(
            declarations: functionDeclarations,
            context: context)



        let operatorsDeclarations = self.getOperatorOverloadDeclarations()
        let (operators, operatorsRedeclarations) = resolveDefinitions(
            declarations: operatorsDeclarations,
            context: context)

        
        let functionsIdentifiers = functions.reduce(into: [:]) { acc, element in
            acc[element.key.functionIdentifier] =
                (acc[element.key.functionIdentifier] ?? []) + [element.key]
        }
        let functionsInputTypeIdentifiers = functions.reduce(into: [:]) { acc, element in
            acc[element.key.inputType] = (acc[element.key.inputType] ?? []) + [element.key]
        }

        let functionTypeCheckErrors = functions.flatMap { function, _ in
            
            let inputTypeNotInScopeErrors: [FunctionSemanticError] = function.inputType.getNominalTypesFromIdentifier().compactMap { type in
                if let _ = context.types[type] ?? builtins.types[type] {
                    return nil
                } else {
                    return FunctionSemanticError.typeNotInScope(
                        location: type.location,
                        type: type,
                        typesInScope: context.types.keys)
                }
            }

            let paramsTypesNotInScopeErrors = function.params.flatMap { param in
                let errors: [FunctionSemanticError] = param.type.getNominalTypesFromIdentifier().compactMap { type in
                    if let _ = context.types[type] ?? builtins.types[type] {
                        return nil
                    } else {
                        return FunctionSemanticError.typeNotInScope(
                            location: type.location,
                            type: type,
                            typesInScope: context.types.keys)
                    }
                }
                return errors
            }

            let outputTypeNotInScopeErrors: [FunctionSemanticError] = function.outputType.getNominalTypesFromIdentifier().compactMap { type in
                if let _ = context.types[type] ?? builtins.types[type] {
                    return nil
                } else {
                    return FunctionSemanticError.typeNotInScope(
                        location: type.location,
                        type: type,
                        typesInScope: context.types.keys)
                }
            }

            return inputTypeNotInScopeErrors + paramsTypesNotInScopeErrors + outputTypeNotInScopeErrors
        }

        let operatorTypeCheckErrors = operators.flatMap { function, _ in
            let leftTypeNotInScopeErrors = function.left.type.getNominalTypesFromIdentifier().compactMap { type in
                if let _ = context.types[type] ?? builtins.types[type] {
                    return FunctionSemanticError.typeNotInScope(
                        location: type.location,
                        type: type,
                        typesInScope: context.types.keys)
                } else {
                    return nil
                }
            }

            let rightTypNotInScopeErrors = function.right.type.getNominalTypesFromIdentifier().compactMap { type in
                if let _ = context.types[type] ?? builtins.types[type] {
                    return FunctionSemanticError.typeNotInScope(
                        location: type.location,
                        type: type,
                        typesInScope: context.types.keys)
                } else {
                    return nil
                }
            }

            return leftTypeNotInScopeErrors + rightTypNotInScopeErrors
        }

        return (
            functions: functions,
            functionsIdentifiers: functionsIdentifiers,
            functionsInputTypeIdentifiers: functionsInputTypeIdentifiers,
            operators: operators,
            errors: 
                functionsRedeclarations +
                functionTypeCheckErrors +
                operatorsRedeclarations +
                operatorTypeCheckErrors
            )
    }

    private func resolveDefinitions<Declaration>(
        declarations: [Declaration],
        context: borrowing SemanticContext
    ) -> (
        definitions: [Declaration: Declaration],
        errors: [FunctionSemanticError]
    ) where Declaration: Hashable, Declaration: SyntaxNode {

        let locations = declarations.reduce(into: [:]) { acc, declaration in
            acc[declaration] = (acc[declaration] ?? []) + [declaration]
        }

        let redeclarations = locations.compactMap { _, locations in
            if locations.count > 1 {
                return FunctionSemanticError.redeclaration(locations: locations.map { $0.location })
            } else {
                return nil
            }
        }

        let definitions = locations.compactMapValues { definitions in
            return definitions.first
        }

        return (
            definitions: definitions,
            errors: redeclarations
        )
    }
}


protocol ExpressionTypeChecker {
    func checkType(
        with input: Expression,
        localScope: LocalScope,
        context: borrowing SemanticContext
    ) throws(ExpressionSemanticError) -> Self
}

protocol FunctionSignatureChecker {
}


extension Project: TypeDeclarationChecker, FunctionDeclarationChecker {
    func getTypeDeclarations() -> [TypeDefinition] {
        return self.modules.flatMap { source, module in
            return module.getTypeDefinitions()
        }
    }

    func getFunctionDeclarations() -> [FunctionDefinition] {
        return self.modules.flatMap { source, module in
            return module.getFunctionDeclarations()
        }
    }

    func getOperatorOverloadDeclarations() -> [OperatorOverloadDefinition] {
        return self.modules.flatMap { source, module in
            return module.getOperatorOverloadDeclarations()
        }
    }
}

extension Module: TypeDeclarationChecker, FunctionDeclarationChecker {
    func getTypeDeclarations() -> [TypeDefinition] {
        return self.statements.compactMap { statement in
            if case let .typeDefinition(typeDefinition) = statement {
                return typeDefinition
            } else {
                return nil
            }
        }
    }

    func getFunctionDeclarations() -> [FunctionDefinition] {
        return self.statements.compactMap { statement in
            if case let .functionDefinition(functionDefinition) = statement {
                return functionDefinition
            } else {
                return nil
            }
        }
    }

    func getOperatorOverloadDeclarations() -> [OperatorOverloadDefinition] {
        return self.statements.compactMap { statement in
            if case let .operatorOverloadDefinition(definition) = statement {
                return definition
            } else {
                return nil
            }
        }
    }
}
// TODO: type checking steps
