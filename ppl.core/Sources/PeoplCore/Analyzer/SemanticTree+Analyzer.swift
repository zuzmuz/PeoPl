protocol SemanticChecker: TypeDeclarationsChecker, ValueDefinitionChecker {
    func semanticCheck() -> Result<Semantic.Context, SemanticErrorList>
}

extension SemanticChecker {
    func semanticCheck() -> Result<Semantic.Context, SemanticErrorList> {
        let intrinsicDeclarations = getIntrinsicDeclarations()

        // TODO: calculating typeDeclarations can be done as a seperate step
        let (typeDeclarations, typeLookup, typeErrors) =
            self.resolveTypeSymbols(
                contextTypeDeclarations: intrinsicDeclarations.typeDeclarations)

        let (valueDeclarations, valueLookup, valueErrors) =
            self.resolveValueSymbols(
                typeDeclarations: typeDeclarations,
                contextValueDeclarations: intrinsicDeclarations.valueDeclarations)

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
        fatalError()
    }
}

extension Syntax.Module: SemanticChecker {}
extension Syntax.Project: SemanticChecker {}
