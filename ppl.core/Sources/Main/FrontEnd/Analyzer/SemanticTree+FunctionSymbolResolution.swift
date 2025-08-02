public protocol FunctionDefinitionChecker {
    func getFunctionDeclarations() -> [Syntax.Definition]
    func resolveFunctionSymbols(
        typeDeclarations: borrowing Semantic.TypeDeclarationsMap,
        contextFunctionDeclarations: borrowing Semantic.FunctionDeclarationsMap
    ) -> (
        functionDeclarations: Semantic.FunctionDeclarationsMap,
        functionLookup: Semantic.FunctionLookupMap,
        errors: [Semantic.Error]
    )
}

extension Syntax.Function {
    func getSignature(
        identifier: Semantic.QualifiedIdentifier
    ) throws(Semantic.Error) -> Semantic.FunctionSignature {
        guard let signature = self.signature else {
            throw .notImplemented(
                "do not support signatureless function",
                location: self.location)
        }
        return try signature.getSignature(identifier: identifier)
    }
}

extension Syntax.Expression {
    func getSignature(
        identifier: Semantic.QualifiedIdentifier
    ) throws(Semantic.Error) -> Semantic.ExpressionSignature {
        switch self {
        case let .function(function):
            return try .function(function.getSignature(identifier: identifier))
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

extension FunctionDefinitionChecker {
    public func resolveFunctionSymbols(
        typeDeclarations: borrowing Semantic.TypeDeclarationsMap,
        contextFunctionDeclarations: borrowing Semantic.FunctionDeclarationsMap
    ) -> (
        functionDeclarations: Semantic.FunctionDeclarationsMap,
        functionLookup: Semantic.FunctionLookupMap,
        errors: [Semantic.Error]
    ) {
        let declarations = self.getFunctionDeclarations()

        let allTypes = Set(Array(typeDeclarations.keys))

        // detecting invalid type identifiers
        let typesNotInScope = declarations.flatMap { definition in
            if case let .function(function) = definition.definition,
                let signature = function.signature
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

        // verifying function redeclarations
        var functionLocations:
            [Semantic.FunctionSignature:
                [Syntax.Definition]] = [:]
        var signatureErrors: [Semantic.Error] = []
        for declaration in declarations {
            do {
                switch declaration.definition {
                case let .function(function):
                    let signature = try function.getSignature(
                        identifier: declaration
                            .identifier
                            .getSemanticIdentifier())
                    functionLocations[signature] =
                        (functionLocations[signature] ?? []) + [declaration]
                default:
                    break
                }
            } catch {
                signatureErrors.append(error)
            }
        }

        // detecting redeclarations
        // NOTE: for the future, interesting features to introduce are default arguments values and overloading
        let redeclarations = functionLocations.compactMap { _, valueLocations in
            if valueLocations.count > 1 {
                return Semantic.Error.valueRedeclaration(values: valueLocations)
            } else {
                return nil
            }
        }

        let functionLookup = functionLocations.compactMapValues { values in
            return values.first
        }

        var functionDeclarations: Semantic.FunctionDeclarationsMap = [:]
        var typeSpecifierErrors: [Semantic.Error] = []

        for (signature, definition) in functionLookup {
            do {
                functionDeclarations[signature] =
                    try definition.definition.getType()
            } catch {
                typeSpecifierErrors.append(error)
            }
        }
        return (
            functionDeclarations: functionDeclarations,
            functionLookup: functionLookup,
            errors: typesNotInScope + signatureErrors + redeclarations
                + typeSpecifierErrors
        )
    }
}

extension Syntax.Module: FunctionDefinitionChecker {
    public func getFunctionDeclarations() -> [Syntax.Definition] {
        return self.definitions.filter { definition in
            switch definition.definition {
            case .function:
                return true
            default:
                return false
            }
        }
    }
}

extension Syntax.Project: FunctionDefinitionChecker {
    public func getFunctionDeclarations() -> [Syntax.Definition] {
        return self.modules.values.flatMap { module in
            module.getFunctionDeclarations()
        }
    }
}
