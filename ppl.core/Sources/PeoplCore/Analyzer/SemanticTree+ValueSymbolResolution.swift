protocol ValueDefinitionChecker {
    func getValueDeclarations() -> [Syntax.ValueDefinition]
    func resolveValueSymbols(
        context: borrowing Semantic.Context
    ) -> (
        valueDefinitions: [Semantic.ScopedIdentifier: Semantic.Expression],
        valueLookup: [Semantic.ScopedIdentifier: Syntax.ValueDefinition],
        errors: [ValueSemanticError]
    )
}

extension ValueDefinitionChecker {
    func resolveValueSymbols(
        context: borrowing Semantic.Context
    ) -> (
        valueDefinitions: [Semantic.ScopedIdentifier: Semantic.Expression],
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



        fatalError("value definition checker not impemented")
    }
}
