public protocol SemanticChecker:
    TypeDeclarationsChecker,
    FunctionDefinitionsChecker
{
    func semanticCheck() -> Result<
        Semantic.DefinitionsContext, Semantic.ErrorList
    >
}

extension SemanticChecker {
    public func semanticCheck() -> Result<
        Semantic.DefinitionsContext, Semantic.ErrorList
    > {
        let intrinsicDeclarations = Semantic.getIntrinsicDeclarations()

        // Getting type declarations
        let (typeDeclarations, typeLookup, typeErrors) =
            self.resolveTypeSymbols(
                contextTypeDeclarations: intrinsicDeclarations.typeDeclarations)

        let allTypeDeclarations = intrinsicDeclarations.typeDeclarations
            .merging(typeDeclarations) { $1 }

        // Getting function decalrations
        let (
            functionDeclarations,
            functionBodyExpressions,
            functionLookup,
            functionErrors
        ) =
            self.resolveFunctionSymbols(
                typeLookup: typeLookup,
                typeDeclarations: allTypeDeclarations,
                contextFunctionDeclarations:
                    intrinsicDeclarations.functionDeclarations)

        let allFunctionDeclarations = intrinsicDeclarations.functionDeclarations
            .merging(functionDeclarations) { $1 }

        let context = Semantic.DeclarationsContext(
            typeDeclarations: allTypeDeclarations,
            functionDeclarations: allFunctionDeclarations,
            operatorDeclarations: intrinsicDeclarations.operatorDeclarations)

        let expressionDefinitions:
            [Result<
                (Semantic.FunctionSignature, Semantic.Expression),
                Semantic.Error
            >] = functionBodyExpressions.compactMap { signature, expression in

                guard let outputType = functionDeclarations[signature] else {
                    return nil
                }

                do throws(Semantic.Error) {
                    let checkedExpression = try signature.checkBody(
                        body: expression,
                        outputType: outputType,
                        context: context)

                    return .success(
                        (
                            signature,
                            checkedExpression
                        )
                    )

                } catch {
                    return .failure(error)
                }
            }

        let typeCheckingErrors = expressionDefinitions.compactMap { result in
            if case let .failure(error) = result {
                return error
            }
            return nil
        }

        let allErrors = typeErrors + functionErrors + typeCheckingErrors
        if allErrors.count > 0 {
            return .failure(.init(errors: allErrors))
        }

        let functionDefinitions: Semantic.FunctionDefinitionsMap =
            Dictionary(
                uniqueKeysWithValues:
                    expressionDefinitions.compactMap { result in
                        if case let .success((signature, expression)) = result {
                            return (signature, expression)
                        }
                        return nil
                    })
        // NOTE: I might need to send only function to code gen
        return .success(
            .init(
                functionDefinitions: functionDefinitions,
                typeDefinitions: typeDeclarations))
    }
}

extension Syntax.Module: SemanticChecker {}
extension Syntax.Project: SemanticChecker {}
