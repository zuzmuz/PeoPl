protocol SemanticChecker: TypeDefinitionChecker, ValueDefinitionChecker {
    func semanticCheck() -> Result<Semantic.Context, SemanticErrorList>
}

extension SemanticChecker {
    func semanticCheck() -> Result<Semantic.Context, SemanticErrorList> {
        let intrinsicContext = getIntrinsicContext()

        let (typeDefinitions, typeLookup, typeErrors) = self.resolveTypeSymbols(
            context: intrinsicContext)

        let (valueLookup, valueErrors) = self.resolve
        // if errors.count > 0 {
        //     return .failure(.init(errors: errors.map { .type($0) }))
        // }

        // let context = Semantic.Context(
        //     typeDefinitions: intrinsicContext.typeDefinitions.merging(
        //         typeDefinitions
        //     ) { $1 },
        //     valueDefinitions: intrinsicContext.valueDefinitions,
        //     typeLookup: intrinsicContext.typeLookup.merging(typeLookup) { $1 },
        //     valueLookup: intrinsicContext.valueLookup,
        //     operators: intrinsicContext.operators)

        // NOTE: leaving contexts separate

        return .success(
            .init(
                typeDefinitions: typeDefinitions,
                valueDefinitions: [:],
                typeLookup: typeLookup,
                valueLookup: [:],
                operators: [:]))
    }
}

extension Syntax.Module: SemanticChecker {}
extension Syntax.Project: SemanticChecker {}
