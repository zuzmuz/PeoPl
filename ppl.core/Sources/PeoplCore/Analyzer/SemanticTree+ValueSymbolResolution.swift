protocol ValueDeclarationChecker {
    func resolveValueSymbols(
        context: borrowing Semantic.Context
    ) -> (
        valueDefinitions: [Semantic.ScopedIdentifier: Semantic.Expression],
        valueLookup: [Semantic.ScopedIdentifier: Syntax.ValueDefinition],
        errors: [ValueSemanticError]
    )
}
