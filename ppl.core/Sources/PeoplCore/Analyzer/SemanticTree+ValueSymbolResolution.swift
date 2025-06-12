protocol ValueDefinitionChecker {
    func getValueDeclarations() -> [Syntax.ValueDefinition]
    func resolveValueSymbols(
        typeDeclarations: borrowing Semantic.TypeDeclarationsMap,
        contextValueDeclarations: borrowing Semantic.ValueDeclarationsMap
    ) -> (
        valueDeclarations: Semantic.ValueDeclarationsMap,
        valueLookup: Semantic.ValueLookupMap,
        functionExpressions: [Semantic.FunctionSignature: Syntax.Expression],
        errors: [SemanticError]
    )
}

extension Syntax.Expression {
    func getSignature(
        identifier: Semantic.ScopedIdentifier
    ) throws(SemanticError) -> Semantic.ExpressionSignature {
        switch self.expressionType {
        case let .function(signature, _):
            guard let signature else {
                fatalError("do not support signatureless function")
            }
            return .function(
                try signature.getSignature(
                    identifier: identifier))
        default:
            fatalError("do not support compile time expressions yet")
        }
    }

    func getType() throws(SemanticError) -> Semantic.TypeSpecifier {
        switch self.expressionType {
        case let .function(signature, _):
            guard let signature else {
                fatalError("do not support signatureless function")
            }
            // TODO: think about the type of the expression (shouldn't be a function
            return try signature.outputType.getSemanticType()
        default:
            fatalError(
                "\(self) do not support compile time expressions yet, should calculate expression at compile time"
            )
        }
    }
}

extension Syntax.Function {
    func getSignature(
        identifier: Semantic.ScopedIdentifier
    ) throws(SemanticError) -> Semantic.FunctionSignature {
        let inputType = try self.inputType?.getSemanticType() ?? .nothing
        let arguments = try self.arguments.getProductSemanticTypes()
        return .init(
            identifier: identifier,
            inputType: inputType,
            arguments: arguments)
    }
}

extension ValueDefinitionChecker {
    func resolveValueSymbols(
        typeDeclarations: borrowing Semantic.TypeDeclarationsMap,
        contextValueDeclarations: borrowing Semantic.ValueDeclarationsMap
    ) -> (
        valueDeclarations: Semantic.ValueDeclarationsMap,
        valueLookup: Semantic.ValueLookupMap,
        functionExpressions: [Semantic.FunctionSignature: Syntax.Expression],
        errors: [SemanticError]
    ) {
        let declarations = self.getValueDeclarations()

        let allTypes = Set(Array(typeDeclarations.keys))

        // detecting invalid type identifiers
        let typesNotInScope = declarations.flatMap { value in
            if case let .function(signature, _) =
                value.expression.expressionType, let signature
            {
                let undefinedInputTypes =
                    signature.inputType?.undefinedTypes(
                        types: allTypes) ?? []

                let undefinedArgumentsTypes =
                    signature.arguments.flatMap { typeField in
                        typeField.undefinedTypes(
                            types: allTypes)
                    }

                let undefinedOutputTypes = signature.outputType.undefinedTypes(
                    types: allTypes)

                return undefinedInputTypes + undefinedArgumentsTypes
                    + undefinedOutputTypes
            }
            return []
        }.map { SemanticError.typeNotInScope(type: $0) }

        // verifying value redeclarations
        var valuesLocations:
            [Semantic.ExpressionSignature:
                [Syntax.ValueDefinition]] = [:]
        var signatureErrors: [SemanticError] = []
        for value in declarations {
            do {
                let signature = try value.expression.getSignature(
                    identifier: value.identifier.getSemanticIdentifier())
                valuesLocations[signature] =
                    (valuesLocations[signature] ?? []) + [value]
            } catch {
                signatureErrors.append(error)
            }
        }

        // detecting redeclarations
        // NOTE: for the future, interesting features to introduce are default arguments values and overloading
        let redeclarations = valuesLocations.compactMap { _, valueLocations in
            if valueLocations.count > 1 {
                return SemanticError.valueRedeclaration(values: valueLocations)
            } else {
                return nil
            }
        }

        let valueLookup = valuesLocations.compactMapValues { values in
            return values.first
        }

        let functionExpressions:
            [Semantic.FunctionSignature: Syntax.Expression] =
                valueLookup.reduce(into: [:]) { acc, pair in
                    switch (pair.key, pair.value.expression.expressionType) {
                    case let (.function(function), .function(_, expression)):
                        acc[function] = expression
                    default:
                        break
                    }
                }

        var valueDeclarations: Semantic.ValueDeclarationsMap = [:]
        var typeSpecifierErrors: [SemanticError] = []

        for (signature, value) in valueLookup {
            do {
                valueDeclarations[signature] = try value.expression.getType()
            } catch {
                typeSpecifierErrors.append(error)
            }
        }
        return (
            valueDeclarations: valueDeclarations,
            valueLookup: valueLookup,
            functionExpressions: functionExpressions,
            errors: typesNotInScope + signatureErrors + redeclarations
                + typeSpecifierErrors
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
