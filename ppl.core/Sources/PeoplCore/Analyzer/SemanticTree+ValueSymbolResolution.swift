protocol ValueDefinitionChecker {
    func getValueDeclarations() -> [Syntax.ValueDefinition]
    func resolveValueSymbols(
        typeDefinitions: borrowing [Semantic.ScopedIdentifier: Semantic
            .RawTypeSpecifier],
        typeLookup: borrowing [Semantic.ScopedIdentifier: Syntax
            .TypeDefinition],
        context: borrowing Semantic.Context
    ) -> (
        valueLookup: [Semantic.ScopedIdentifier: Syntax.ValueDefinition],
        errors: [ValueSemanticError]
    )
}

extension ValueDefinitionChecker {
    func resolveValueSymbols(
        typeDefinitions: borrowing [Semantic.ScopedIdentifier: Semantic
            .RawTypeSpecifier],
        typeLookup: borrowing [Semantic.ScopedIdentifier: Syntax
            .TypeDefinition],
        context: borrowing Semantic.Context
    ) -> (
        valueLookup: [Semantic.ScopedIdentifier: Syntax.ValueDefinition],
        errors: [ValueSemanticError]
    ) {
        let declarations = self.getValueDeclarations()

        let valuesLocations:
            [Semantic.ScopedIdentifier: [Syntax.ValueDefinition]] =
                declarations.reduce(into: [:]) { acc, type in
                    let semanticIdentifer = Semantic.ScopedIdentifier(
                        chain: type.identifier.chain)
                    acc[semanticIdentifer] =
                        (acc[semanticIdentifer] ?? []) + [type]
                }

        // detecting redeclarations
        // NOTE: not supporting function overloading
        // NOTE: for the future, interesting features to introduce are default arguments values and overloading
        let redeclarations = valuesLocations.compactMap { _, valueLocations in
            if valueLocations.count > 1 {
                return ValueSemanticError.redeclaration(values: valueLocations)
            } else {
                return nil
            }
        }

        let valueLookup = valuesLocations.compactMapValues { values in
            return values.first
        }

        // verify function value signature
        let typesNotInScope = valueLookup.flatMap { _, value in
            if case let .function(signature, _) =
                value.definition.expressionType, let signature
            {
                let undefinedInputTypes =
                    signature.inputType?.undefinedTypes(
                        typeLookup: typeLookup, context: context) ?? []

                let undefinedArgumentsTypes =
                    signature.arguments.flatMap { typeField in
                        typeField.undefinedTypes(
                            typeLookup: typeLookup, context: context)
                    }

                let undefinedOutputTypes = signature.outputType.undefinedTypes(
                    typeLookup: typeLookup, context: context)

                return undefinedInputTypes + undefinedArgumentsTypes
                    + undefinedOutputTypes
            }
            return []
        }.map { ValueSemanticError.typeNotInScope(type: $0) }

        return (
            valueLookup: valueLookup,
            errors: redeclarations + typesNotInScope
        )
    }
}

extension Syntax.Module: ValueDefinitionChecker {
    func getValueDeclarations() -> [Syntax.ValueDefinition] {
        return self.definitions.compactMap { statement in
            if case let .valueDefinition(typeDefinition) = statement {
                return typeDefinition
            } else {
                return nil
            }
        }
    }
}

extension Syntax.Project: ValueDefinitionChecker {
    func getValueDeclarations() -> [Syntax.ValueDefinition] {
        return self.modules.values.flatMap { module in
            module.getValueDeclarations()
        }
    }
}
