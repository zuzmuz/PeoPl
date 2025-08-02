public protocol ValueDefinitionChecker {
    func getValueDeclarations() -> [Syntax.Definition]
    func resolveValueSymbols(
        typeDeclarations: borrowing Semantic.TypeDeclarationsMap,
        contextValueDeclarations: borrowing Semantic.ValueDeclarationsMap
    ) -> (
        valueDeclarations: Semantic.ValueDeclarationsMap,
        valueLookup: Semantic.ValueLookupMap,
        functionExpressions: [Semantic.FunctionSignature: Syntax.Expression],
        errors: [Semantic.Error]
    )
}

extension Syntax.Expression {
    func getSignature(
        identifier: Semantic.QualifiedIdentifier
    ) throws(Semantic.Error) -> Semantic.ExpressionSignature {
        switch self {
        case let .function(function):
            guard let signature = function.signature else {
                throw .notImplemented(
                    "do not support signatureless function",
                    location: function.location)
            }
            return .function(
                try signature.getSignature(identifier: identifier))
        default:
            throw .notImplemented(
                "we do not support compile time expressions yet",
                location: .nowhere)
        }
    }

    func getType() throws(Semantic.Error) -> Semantic.TypeSpecifier {
        switch self {
        case let .function(function):
            guard let signature = function.signature else {
                throw .notImplemented(
                    "do not support signatureless function",
                    location: function.location)
            }
            // TODO: think about the type of the expression (shouldn't be a function)
            return try signature.outputType.getSemanticType()
        default:
            throw .notImplemented(
                "\(self) do not support compile time expressions yet, should calculate expression at compile time",
                location: .nowhere)
        }
    }
}

extension Syntax.FunctionType {
    func getSignature(
        identifier: Semantic.QualifiedIdentifier
    ) throws(Semantic.Error) -> Semantic.FunctionSignature {
        let inputType: (tag: Semantic.Tag, type: Semantic.TypeSpecifier) =
            switch self.inputType {
            case let .typeSpecifier(typeSpecifier):
                (tag: .input, type: try typeSpecifier.getSemanticType())
            case let .taggedTypeSpecifier(taggedTypeSpecifier):
                if let typeSpecifier = taggedTypeSpecifier.typeSpecifier {
                    (
                        tag: .named(taggedTypeSpecifier.tag),
                        type: try typeSpecifier.getSemanticType()
                    )
                } else {
                    throw .taggedTypeSpecifierRequired
                }
            case let .homogeneousTypeProduct(homogeneousTypeProduct):
                (
                    tag: .input,
                    type: .raw(
                    .record(
                        try [
                            Syntax.TypeField.homogeneousTypeProduct(
                                homogeneousTypeProduct)
                        ].getProductSemanticTypes()))
                )

            case .none:
                (
                    tag: .input,
                    type: .nothing
                )
            }
        let arguments = try self.arguments.getProductSemanticTypes()

        if let inputTypeField = self.inputType,
            arguments[inputType.tag] != nil
        {
            throw Semantic.Error.duplicateFieldName(
                field: inputTypeField)
        }
        return .init(
            identifier: identifier,
            inputType: inputType,
            arguments: arguments)
    }
}

extension ValueDefinitionChecker {
    public func resolveValueSymbols(
        typeDeclarations: borrowing Semantic.TypeDeclarationsMap,
        contextValueDeclarations: borrowing Semantic.ValueDeclarationsMap
    ) -> (
        valueDeclarations: Semantic.ValueDeclarationsMap,
        valueLookup: Semantic.ValueLookupMap,
        functionExpressions: [Semantic.FunctionSignature: Syntax.Expression],
        errors: [Semantic.Error]
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
        }.map { Semantic.Error.typeNotInScope(type: $0) }

        // verifying value redeclarations
        var valuesLocations:
            [Semantic.ExpressionSignature:
                [Syntax.ValueDefinition]] = [:]
        var signatureErrors: [Semantic.Error] = []
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
                return Semantic.Error.valueRedeclaration(values: valueLocations)
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
        var typeSpecifierErrors: [Semantic.Error] = []

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
    public func getValueDeclarations() -> [Syntax.ValueDefinition] {
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
    public func getValueDeclarations() -> [Syntax.ValueDefinition] {
        return self.modules.values.flatMap { module in
            module.getValueDeclarations()
        }
    }
}
