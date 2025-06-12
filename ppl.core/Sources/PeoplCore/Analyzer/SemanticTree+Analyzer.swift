protocol SemanticChecker: TypeDeclarationsChecker, ValueDefinitionChecker {
    func semanticCheck() -> Result<Semantic.Context, SemanticErrorList>
}

extension SemanticChecker {
    func semanticCheck() -> Result<Semantic.Context, SemanticErrorList> {
        let intrinsicDeclarations = getIntrinsicDeclarations()

        // Getting type declarations
        let (typeDeclarations, typeLookup, typeErrors) =
            self.resolveTypeSymbols(
                contextTypeDeclarations: intrinsicDeclarations.typeDeclarations)

        let allTypeDeclarations = intrinsicDeclarations.typeDeclarations
            .merging(typeDeclarations) { $1 }
        // Getting value decalrations
        let (valueDeclarations, valueLookup, functionExpressions, valueErrors) =
            self.resolveValueSymbols(
                typeDeclarations: allTypeDeclarations,
                contextValueDeclarations: intrinsicDeclarations
                    .valueDeclarations)

        let allValueDeclarations = intrinsicDeclarations.valueDeclarations
            .merging(valueDeclarations) { $1 }

        let valueDefinitionsResults:
            [Result<
                (Semantic.FunctionSignature, Semantic.Expression), SemanticError
            >] =
                functionExpressions.map { signature, expression in
                    do {
                        return .success(
                            (
                                signature,
                                try expression.checkType(
                                    with: signature.inputType,
                                    localScope: .init(),  // TODO: handle extra arguments
                                    context: .init(
                                        typeDeclarations: allTypeDeclarations,
                                        valueDeclarations: allValueDeclarations,
                                        operatorDeclarations:
                                            intrinsicDeclarations
                                            .operatorDeclarations
                                    ))
                            ))
                    } catch {
                        fatalError(
                            "Value definition resolution failed: \(error)")
                    }
                }

        let typeCheckingErrors = valueDefinitionsResults.compactMap { result in
            if case let .failure(error) = result {
                return error
            }
            return nil
        }

        let allErrors = typeErrors + valueErrors + typeCheckingErrors
        if allErrors.count > 0 {
            return .failure(.init(errors: allErrors))
        }

        let valueDefinitions: Semantic.ValueDefinitionsMap =
            Dictionary(
                uniqueKeysWithValues:
                    valueDefinitionsResults.compactMap { result in
                        if case let .success((signature, expression)) = result {
                            return (.function(signature), expression)
                        }
                        return nil
                    })
        // NOTE: I might need to send only function to code gen
        return .success(
            .init(definitions: .init(valueDefinitions: valueDefinitions)))  //, operators: [Semantic.OperatorField : Semantic.Expression])))
    }
}

extension Syntax.Module: SemanticChecker {}
extension Syntax.Project: SemanticChecker {}
