public protocol FunctionDefinitionChecker {
    func getFunctionDeclarations() -> [Syntax.Definition]
    func resolveFunctionSymbols(
        typeLookup: borrowing Semantic.TypeLookupMap,
        typeDeclarations: borrowing Semantic.TypeDeclarationsMap,
        contextFunctionDeclarations: borrowing Semantic.FunctionDeclarationsMap
    ) -> (
        functionDeclarations: Semantic.FunctionDeclarationsMap,
        functionBodyExpressions: [Semantic.FunctionSignature: Syntax
            .Expression],
        functionLookup: Semantic.FunctionLookupMap,
        errors: [Semantic.Error]
    )
}

extension Syntax.Function {
    func getSignature(
        identifier: Semantic.QualifiedIdentifier
    ) throws(Semantic.Error) -> Semantic.FunctionSignature {
        guard let signature = self.signature else {
            throw .init(
                location: self.location,
                errorChoice: .notImplemented(
                    "do not support signatureless function"))
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
            throw .init(
                location: self.location,
                errorChoice: .notImplemented(
                    "we do not support compile time expressions yet"))
        }
    }

    func getType() throws(Semantic.Error) -> Semantic.TypeSpecifier {
        switch self {
        case let .function(function):
            guard let signature = function.signature else {
                throw .init(
                    location: self.location,
                    errorChoice: .notImplemented(
                        "do not support signatureless function"))
            }
            // TODO: think about the type of the expression (shouldn't be a function)
            return try signature.outputType.getSemanticType()
        default:
            throw .init(
                location: self.location,
                errorChoice: .notImplemented(
                    "\(self) do not support compile time expressions yet, should calculate expression at compile time"
                ))
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
                    throw .init(
                        location: taggedTypeSpecifier.location,
                        errorChoice: .taggedTypeSpecifierRequired)
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
            throw .init(
                location: inputTypeField.location,
                errorChoice: .duplicateFieldName)
        }
        return .init(
            identifier: identifier,
            inputType: inputType,
            arguments: arguments)
    }
}

extension FunctionDefinitionChecker {
    public func resolveFunctionSymbols(
        typeLookup: borrowing Semantic.TypeLookupMap,
        typeDeclarations: borrowing Semantic.TypeDeclarationsMap,
        contextFunctionDeclarations: borrowing Semantic.FunctionDeclarationsMap
    ) -> (
        functionDeclarations: Semantic.FunctionDeclarationsMap,
        functionBodyExpressions: [Semantic.FunctionSignature: Syntax
            .Expression],
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
        }.map { identifier in
            Semantic.Error.init(
                location: identifier.location,
                errorChoice: .typeNotInScope(identifier: identifier))
        }

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
        let redeclarations =
            functionLocations.flatMap { signature, functionLocations in
                if functionLocations.count > 1 {
                    let locations = functionLocations.map { $0.location }
                    return functionLocations.map { functionLocation in
                        Semantic.Error.init(
                            location: functionLocation.location,
                            errorChoice: .functionRedeclaration(
                                signature: signature,
                                otherLocations: locations))
                    }
                } else {
                    return []
                }
            }

        let functionLookup = functionLocations.compactMapValues { values in
            return values.first
        }

        // detection redeclarations of identifiers of types
        let typeRedeclaration =
            functionLookup.compactMap { signature, definition in
                if let typeDeclaration =
                    typeDeclarations[signature.identifier]
                {
                    if let typeLocation = typeLookup[signature.identifier] {
                        return Semantic.Error.init(
                            location: definition.location,
                            errorChoice: .functionRedeclaringType(
                                identifier: signature.identifier,
                                typeLocation: typeLocation.location)
                        )
                    }
                    // TODO: check for builtin shadowing
                }
                return nil
            }

        var functionDeclarations: Semantic.FunctionDeclarationsMap = [:]
        var functionBodyExpressions: [Semantic.FunctionSignature: Syntax
            .Expression] = [:]
        var typeSpecifierErrors: [Semantic.Error] = []

        for (signature, definition) in functionLookup {
            do {
                functionDeclarations[signature] =
                    try definition.definition.getType()

                // FIX: I'm doing this switch multiple times, I can do it from the start and filter that gradually
                switch definition.definition {
                case let .function(function):
                    functionBodyExpressions[signature] =
                        function.body
                default:
                    break
                }

            } catch {
                typeSpecifierErrors.append(error)
            }
        }
        return (
            functionDeclarations: functionDeclarations,
            functionBodyExpressions: functionBodyExpressions,
            functionLookup: functionLookup,
            errors: typesNotInScope + signatureErrors + redeclarations
                + typeSpecifierErrors + typeRedeclaration
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
