protocol FunctionDeclarationChecker {
    func getFunctionDeclarations() -> [Syntax.FunctionDefinition]
    func getOperatorOverloadDeclarations() -> [Syntax
        .OperatorOverloadDefinition]

    func resolveFunctionDefinitions(
        typesDefinitions: borrowing [Typed.TypeIdentifier: Syntax
            .TypeDefinition],
        externals: borrowing [String: SemanticContext]
    ) -> Typed.FunctionDefinitionContext
}

extension [String: SemanticContext] {
    func functionDefinedInContext(
        functionDeclaration: Typed.FunctionDeclaration
    ) -> [String: SemanticContext].Element? {
        self.first { _, externalFunctions in
            externalFunctions.functions[functionDeclaration] != nil
        }
    }
}

extension FunctionDeclarationChecker {

    static func getTypeCheckErrors(
        functions: [Typed.FunctionDeclaration: Syntax.FunctionDefinition],
        typesDefinitions: [Typed.TypeIdentifier: Syntax.TypeDefinition],
        externals: borrowing [String: SemanticContext]
    ) -> [FunctionSemanticError] {

        functions.flatMap { _, function in
            let inputTypeNotInScopeErrors: [FunctionSemanticError] =
                if let inputType = function.inputType {
                    inputType.typeDefiniedInContext(
                        typesDefinitions: typesDefinitions,
                        externals: externals
                    ).map { nominalType in
                        FunctionSemanticError.typeNotInScope(type: nominalType)
                    }
                } else { [] }

            let paramsTypesNotInScopeErrors = function.params.flatMap { param in
                param.type.typeDefiniedInContext(
                    typesDefinitions: typesDefinitions,
                    externals: externals
                ).map { nominalType in
                    FunctionSemanticError.typeNotInScope(type: nominalType)
                }
            }

            let outputTypeNotInScopeErrors = function.outputType
                .typeDefiniedInContext(
                    typesDefinitions: typesDefinitions,
                    externals: externals
                ).map { nominalType in
                    FunctionSemanticError.typeNotInScope(type: nominalType)
                }

            return inputTypeNotInScopeErrors
                + paramsTypesNotInScopeErrors
                + outputTypeNotInScopeErrors
        }
    }

    func resolveFunctionDefinitions(
        typesDefinitions: borrowing [Typed.TypeIdentifier: Syntax
            .TypeDefinition],
        externals: borrowing [String: SemanticContext]
    ) -> Typed.FunctionDefinitionContext {

        let functionDeclarations = self.getFunctionDeclarations()
        let (functions, functionsDeclarationErrors) = resolveDefinitions(
            functionDeclaration: functionDeclarations,
            typesDefinitions: typesDefinitions,
            externals: externals)

        // let operatorsDeclarations = self.getOperatorOverloadDeclarations()
        // let (operators, operatorsRedeclarations) = resolveDefinitions(
        //     operatorOverloadDeclarations: operatorsDeclarations,
        //     typesDefinitions: typesDefinitions)

        let functionsIdentifiers = functions.reduce(into: [:]) { acc, element in
            acc[element.key.identifier] =
                (acc[element.key.identifier] ?? []) + [element.value]
        }

        let functionsInputTypeIdentifiers = functions.reduce(
            into: [:]
        ) { acc, element in
            acc[element.key.inputType] =
                (acc[element.key.inputType] ?? []) + [element.value]
        }

        let functionTypeCheckErrors = Self.getTypeCheckErrors(
            functions: functions,
            typesDefinitions: typesDefinitions,
            externals: externals)

        // let operatorTypeCheckErrors = operators.flatMap { function, _ in
        //     let leftTypeNotInScopeErrors = function.left
        //         .getNominalTypesFromIdentifier().compactMap { type in
        //             if (typesDefinitions[type] ?? builtins.types[type]) != nil {
        //                 return FunctionSemanticError.typeNotInScope(
        //                     location: function.location,  // WARN: need to rethink node locations
        //                     type: type,
        //                     typesInScope: typesDefinitions.keys)
        //             } else {
        //                 return nil
        //             }
        //         }
        //
        //     let rightTypNotInScopeErrors = function.right
        //         .getNominalTypesFromIdentifier().compactMap { type in
        //             if (typesDefinitions[type] ?? builtins.types[type]) != nil {
        //                 return FunctionSemanticError.typeNotInScope(
        //                     location: function.location,  // WARN: need to rethink node locations
        //                     type: type,
        //                     typesInScope: typesDefinitions.keys)
        //             } else {
        //                 return nil
        //             }
        //         }
        //
        //     return leftTypeNotInScopeErrors + rightTypNotInScopeErrors
        // }
        return .init(
            functions: functions,
            functionsIdentifiers: functionsIdentifiers,
            functionsInputTypeIdentifiers: functionsInputTypeIdentifiers,
            // operators: operators,
            errors:
                functionsDeclarationErrors + functionTypeCheckErrors
                // + operatorsRedeclarations + operatorTypeCheckErrors
        )
    }

    private func resolveDefinitions(
        functionDeclaration: [Syntax.FunctionDefinition],
        typesDefinitions:
            borrowing [Typed.TypeIdentifier: Syntax.TypeDefinition],
        externals: borrowing [String: SemanticContext]
    ) -> (
        functions: [Typed.FunctionDeclaration: Syntax.FunctionDefinition],
        errors: [FunctionSemanticError]
    ) {

        let functionsLocations = functionDeclaration.reduce(
            into: [:]
        ) { acc, declaration in
            acc[declaration] = (acc[declaration] ?? []) + [declaration]
        }

        let redeclarations = functionsLocations.compactMap { _, locations in
            if locations.count > 1 {
                return FunctionSemanticError.functionRedeclaration(locations)
            } else {
                return nil
            }
        }

        let functions = functionsLocations.reduce(into: [:]) { acc, function in
            acc[
                Typed.FunctionDeclaration(
                    from: function.key
                )] = function.value.first
        }

        let shadowings = functions.compactMap { function, functionDefinition in
            if let shadowedModule = externals.functionDefinedInContext(
                functionDeclaration: function)?.key
            {
                return FunctionSemanticError.shadowing(
                    function: functionDefinition,
                    module: shadowedModule)
            } else {
                return nil
            }
        }

        return (
            functions: functions,
            errors: redeclarations + shadowings
        )
    }
}
