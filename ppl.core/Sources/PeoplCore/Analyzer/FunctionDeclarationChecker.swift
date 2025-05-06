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

extension FunctionDeclarationChecker {

    static func getTypeCheckErrors(
        functions: [Syntax.FunctionDefinition: Syntax.FunctionDefinition],
        typesDefinitions: [Typed.TypeIdentifier: Syntax.TypeDefinition],
        externals: borrowing [String: SemanticContext]
    ) -> [FunctionSemanticError] {
        functions.flatMap { function, _ in
            let inputTypeNotInScopeErrors: [FunctionSemanticError] =
                if let input = function.inputType {
                    input.getNominalTypesFromIdentifier().compactMap { type in
                        if typesDefinitions[type.typeName] != nil
                            || externals.typeDefinedInContext(
                                typeName: type.typeName) != nil
                        {
                            return nil
                        } else {
                            return FunctionSemanticError.typeNotInScope(
                                location: type.location,
                                type: type,
                                typesInScope: typesDefinitions.keys)
                        }
                    }
                } else { [] }

            let paramsTypesNotInScopeErrors = function.params.flatMap { param in
                let errors: [FunctionSemanticError] = param.type
                    .getNominalTypesFromIdentifier().compactMap { type in
                        if typesDefinitions[type.typeName] != nil
                            || externals.typeDefinedInContext(
                                typeName: type.typeName) != nil
                        {
                            return nil
                        } else {
                            return FunctionSemanticError.typeNotInScope(
                                location: type.location,
                                type: type,
                                typesInScope: typesDefinitions.keys)
                        }
                    }
                return errors
            }

            let outputTypeNotInScopeErrors: [FunctionSemanticError] = function
                .outputType.getNominalTypesFromIdentifier().compactMap { type in
                    if (typesDefinitions[type] ?? builtins.types[type]) != nil {
                        return nil
                    } else {
                        return FunctionSemanticError.typeNotInScope(
                            location: type.location,
                            type: type,
                            typesInScope: typesDefinitions.keys)
                    }
                }

            return inputTypeNotInScopeErrors + paramsTypesNotInScopeErrors
                + outputTypeNotInScopeErrors
        }

    }
    func resolveFunctionDefinitions(
        typesDefinitions: borrowing [Typed.TypeIdentifier: Syntax
            .TypeDefinition],
        externals: borrowing [String: SemanticContext]
    ) -> Typed.FunctionDefinitionContext {

        let functionDeclarations = self.getFunctionDeclarations()
        let (functions, functionsRedeclarations) = resolveDefinitions(
            declarations: functionDeclarations,
            typesDefinitions: typesDefinitions)

        let operatorsDeclarations = self.getOperatorOverloadDeclarations()
        let (operators, operatorsRedeclarations) = resolveDefinitions(
            declarations: operatorsDeclarations,
            typesDefinitions: typesDefinitions)

        let functionsIdentifiers = functions.reduce(into: [:]) { acc, element in
            acc[element.key.identifier] =
                (acc[element.key.identifier] ?? []) + [element.key]
        }

        let functionsInputTypeIdentifiers = functions.reduce(
            into: [:]
        ) { acc, element in
            acc[element.key.inputType] =
                (acc[element.key.inputType] ?? []) + [element.key]
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
            operators: operators,
            errors:
                functionsRedeclarations + functionTypeCheckErrors
                + operatorsRedeclarations + operatorTypeCheckErrors
        )
    }

    private func resolveDefinitions<Declaration>(
        declarations: [Declaration],
        typesDefinitions: borrowing [Typed.TypeIdentifier: Syntax
            .TypeDefinition]
    ) -> (
        definitions: [Declaration: Declaration],
        errors: [FunctionSemanticError]
    ) where Declaration: Hashable, Declaration: Syntax.SyntaxNode {

        let locations = declarations.reduce(into: [:]) { acc, declaration in
            acc[declaration] = (acc[declaration] ?? []) + [declaration]
        }

        let redeclarations = locations.compactMap { _, locations in
            if locations.count > 1 {
                return FunctionSemanticError.redeclaration(
                    locations: locations.map { $0.location })
            } else {
                return nil
            }
        }

        // FIX: should handle builtin function redeclaration

        let definitions = locations.compactMapValues { definitions in
            return definitions.first
        }

        return (
            definitions: definitions,
            errors: redeclarations
        )
    }
}
