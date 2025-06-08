// MARK: - Symbol Resolution For Types
// ===================================

/// Protocol for resolving type symbols
protocol TypeDeclarationsChecker {
    /// Return all type declarations defined in module
    func getTypeDeclarations() -> [Syntax.TypeDefinition]

    /// Return resolved type definitions
    /// Maps scoped identifiers to semantic raw type specifiers
    /// Returns list of errors if found
    func resolveTypeSymbols(
        typeDeclarations: borrowing Semantic.TypeDeclarationsMap
    ) -> (
        typeDeclarations: Semantic.TypeDeclarationsMap,
        typeLookup: [Semantic.ScopedIdentifier: Syntax.TypeDefinition],
        errors: [TypeSemanticError]
    )
}

extension Syntax.ScopedIdentifier {
    /// Create a semantic scoped identifier from self
    func getSemanticIdentifier() -> Semantic.ScopedIdentifier {
        return .init(chain: self.chain)
    }
}

extension Syntax.TypeField {

    /// Retrieve all scoped identifier defined in this type field
    /// It represents the names of types used to define the type specifier of this type field
    func getTypeIdentifiers( /* namespace */
    ) -> [Syntax.ScopedIdentifier] {
        switch self {
        case let .typeSpecifier(typeSpecifier):
            return typeSpecifier.getTypeIdentifiers()
        case let .taggedTypeSpecifier(taggedTypeSpecifier):
            return taggedTypeSpecifier.type.getTypeIdentifiers()
        case let .homogeneousTypeProduct(homogeneousTypeProduct):
            return homogeneousTypeProduct.typeSpecifier.getTypeIdentifiers()
        }
    }

    /// Return all scoped identifiers from the type specifier
    /// that do not belong in current type definitions
    /// nor in the context provided
    func undefinedTypes(
        typeLookup: borrowing Semantic.TypeLookupMap,
        typeDeclarations: borrowing Semantic.TypeDeclarationsMap
    ) -> [Syntax.ScopedIdentifier] {
        self.getTypeIdentifiers().filter { typeIdentifier in
            let semanticIdentifier = typeIdentifier.getSemanticIdentifier()
            return typeLookup[semanticIdentifier] == nil
                && typeDeclarations[semanticIdentifier] == nil
        }
    }
}

extension Syntax.TypeSpecifier {

    /// Retrieve all scoped identifier defined in this type
    /// It represents the names of types used to define the type specifier
    func getTypeIdentifiers( /* TODO: handle namespacing */
    ) -> [Syntax.ScopedIdentifier] {
        switch self {
        case .nothing, .never:
            return []
        case let .nominal(nominal):
            return [nominal.identifier]
        case let .product(product):
            return product.typeFields.flatMap { $0.getTypeIdentifiers() }
        case let .sum(sum):
            return sum.typeFields.flatMap { $0.getTypeIdentifiers() }
        case let .function(function):
            return (function.inputType?.getTypeIdentifiers() ?? [])
                + function.arguments.flatMap { $0.getTypeIdentifiers() }
                + function.outputType.getTypeIdentifiers()
        default:  // TODO: all other types
            fatalError()
        }
    }

    /// Return all scoped identifiers from the type specifier
    /// that do not belong in current type definitions
    /// nor in the context provided
    func undefinedTypes(
        typeLookup: borrowing Semantic.TypeLookupMap,
        typeDeclarations: borrowing Semantic.TypeDeclarationsMap
    ) -> [Syntax.ScopedIdentifier] {
        self.getTypeIdentifiers().filter { typeIdentifier in
            let semanticIdentifier = typeIdentifier.getSemanticIdentifier()
            return typeLookup[semanticIdentifier] == nil
                && typeDeclarations[semanticIdentifier] == nil
        }
    }

    /// Create a semantic type specifier from self
    func getSemanticType() throws(TypeSemanticError) -> Semantic.TypeSpecifier {
        switch self {
        case .nothing:
            return .nothing
        case .never:
            return .never
        case let .product(product):
            var recordFields: [Semantic.Tag: Semantic.TypeSpecifier] = [:]
            var fieldCounter = UInt64(0)
            for typeField in product.typeFields {
                switch typeField {
                case let .typeSpecifier(typeSpecifier):
                    recordFields[.unnamed(fieldCounter)] =
                        try typeSpecifier.getSemanticType()
                    fieldCounter += 1
                case let .taggedTypeSpecifier(taggedTypeSpecifier):
                    recordFields[.named(taggedTypeSpecifier.identifier)] =
                        try taggedTypeSpecifier.type.getSemanticType()
                    fieldCounter += 1
                case let .homogeneousTypeProduct(homogeneousTypeProduct):
                    let semanticType = try homogeneousTypeProduct.typeSpecifier
                        .getSemanticType()
                    switch homogeneousTypeProduct.count {
                    case let .literal(value):
                        (0..<value).forEach { index in
                            recordFields[.unnamed(fieldCounter + index)] =
                                semanticType
                        }
                        fieldCounter += value
                    case .identifier:
                        fatalError("compile time values not supported yet")
                    }
                }
            }
            return .raw(.record(recordFields))
        case let .sum(sum):
            var recordFields: [Semantic.Tag: Semantic.TypeSpecifier] = [:]
            var fieldCounter = UInt64(0)
            for typeField in sum.typeFields {
                switch typeField {
                case let .typeSpecifier(typeSpecifier):
                    recordFields[.unnamed(fieldCounter)] =
                        try typeSpecifier.getSemanticType()
                    fieldCounter += 1
                case let .taggedTypeSpecifier(taggedTypeSpecifier):
                    recordFields[.named(taggedTypeSpecifier.identifier)] =
                        try taggedTypeSpecifier.type.getSemanticType()
                    fieldCounter += 1
                case .homogeneousTypeProduct:
                    throw .homogeneousTypeProductInSum(
                        type: self, field: typeField)
                }
            }
            return .raw(.choice(recordFields))
        case let .nominal(nominal):
            return .nominal(nominal.identifier.getSemanticIdentifier())
        default:
            fatalError("Other types are not implemented yet")
        }
    }
}

extension Semantic.TypeSpecifier {
    /// Get the semantic type definition from a type sepcifier.
    /// This will return the raw definition of nominal types from the type definition table lookup
    func getRawType(
        typeDeclarations: borrowing [Semantic.ScopedIdentifier:
            Semantic.TypeSpecifier]
    ) -> Semantic.RawTypeSpecifier {
        switch self {
        case let .nominal(indentifier):
            return typeDeclarations[indentifier]!.getRawType(
                typeDeclarations: typeDeclarations)
        case let .raw(rawTypeSpecifier):
            return rawTypeSpecifier
        }
    }
}

private enum NodeState {
    case visiting
    case visited
}

extension TypeDeclarationsChecker {
    func resolveTypeSymbols(
        typeDeclarations: borrowing Semantic.TypeDeclarationsMap
    ) -> (
        typeDeclarations: Semantic.TypeDeclarationsMap,
        typeLookup: Semantic.TypeLookupMap,
        errors: [TypeSemanticError]
    ) {
        let declarations = self.getTypeDeclarations()

        let typesLocations:
            [Semantic.ScopedIdentifier: [Syntax.TypeDefinition]] =
                declarations.reduce(into: [:]) { acc, type in
                    let semanticIdentifer = Semantic.ScopedIdentifier(
                        chain: type.identifier.chain)
                    acc[semanticIdentifer] =
                        (acc[semanticIdentifer] ?? []) + [type]
                }

        // detecting redeclarations
        let redeclarations = typesLocations.compactMap { _, typeLocations in
            if typeLocations.count > 1 {
                return TypeSemanticError.redeclaration(types: typeLocations)
            } else {
                return nil
            }
        }

        let typeLookup = typesLocations.compactMapValues { types in
            return types.first
        }

        // TODO: detecting shadowings

        // detecting invalid members types
        let typesNotInScope = typeLookup.flatMap { _, type in
            return type.definition.undefinedTypes(
                typeLookup: typeLookup, typeDeclarations: typeDeclarations)
        }.map { TypeSemanticError.typeNotInScope(type: $0) }

        // detecting cyclical dependencies
        let cyclicalDependencies = checkCyclicalDependencies(
            typeLookup: typeLookup, typeDeclarations: typeDeclarations)

        // get semantic type specifier from syntax type specifier
        var localTypeDeclarations:
            [Semantic.ScopedIdentifier: Semantic.TypeSpecifier] = [:]
        var typeSepcifierErrors: [TypeSemanticError] = []

        for (indentifier, typeDefinition) in typeLookup {
            do {
                localTypeDeclarations[indentifier] =
                    try typeDefinition.definition.getSemanticType()
            } catch {
                typeSepcifierErrors.append(error)
            }
        }

        return (
            typeDeclarations: localTypeDeclarations,
            typeLookup: typeLookup,
            errors: redeclarations
                + typesNotInScope
                + cyclicalDependencies
                + typeSepcifierErrors
        )
    }

    private func checkCyclicalDependencies(
        typeLookup: borrowing Semantic.TypeLookupMap,
        typeDeclarations: borrowing Semantic.TypeDeclarationsMap 
    ) -> [TypeSemanticError] {

        var nodeStates: [Syntax.ScopedIdentifier: NodeState] = [:]
        var errors: [TypeSemanticError] = []

        func checkCyclicalDependencies(typeSpecifier: Syntax.TypeSpecifier) {
            switch typeSpecifier {
            case .nothing, .never:
                break
            case let .nominal(nominal):
                // NOTE: intrinsics don't have definition
                if let typeDefinition = typeLookup[
                    nominal.identifier.getSemanticIdentifier()]
                {
                    checkCyclicalDependencies(typeDefinition: typeDefinition)
                }
            case let .product(product):
                product.typeFields.forEach { field in
                    switch field {
                    case let .typeSpecifier(typeSpecifier):
                        checkCyclicalDependencies(
                            typeSpecifier: typeSpecifier)
                    case let .taggedTypeSpecifier(taggedTypeSpecifier):
                        checkCyclicalDependencies(
                            typeSpecifier: taggedTypeSpecifier.type)
                    case let .homogeneousTypeProduct(homogeneousTypeProduct):
                        checkCyclicalDependencies(
                            typeSpecifier: homogeneousTypeProduct.typeSpecifier)
                    }
                }
            case let .sum(sum):
                sum.typeFields.forEach { field in
                    switch field {
                    case let .typeSpecifier(typeSpecifier):
                        checkCyclicalDependencies(
                            typeSpecifier: typeSpecifier)
                    case let .taggedTypeSpecifier(taggedTypeSpecifier):
                        checkCyclicalDependencies(
                            typeSpecifier: taggedTypeSpecifier.type)
                    case .homogeneousTypeProduct:
                        errors.append(
                            // TODO: consider cleaning up where this check is done
                            .homogeneousTypeProductInSum(
                                type: typeSpecifier, field: field))
                    }
                }
            default:
                fatalError()
            }
        }

        func checkCyclicalDependencies(typeDefinition: Syntax.TypeDefinition) {
            let typeIdentifier = typeDefinition.identifier
            if nodeStates[typeIdentifier] == .visited {
                return
            }
            if nodeStates[typeIdentifier] == .visiting {
                errors.append(
                    .cyclicType(
                        type: typeDefinition, cyclicType: typeIdentifier))
                return
            }
            nodeStates[typeIdentifier] = .visiting

            checkCyclicalDependencies(typeSpecifier: typeDefinition.definition)

        }

        typeLookup.forEach { _, typeDefinition in
            checkCyclicalDependencies(typeDefinition: typeDefinition)
        }

        return errors
    }
}

extension Syntax.Module: TypeDeclarationsChecker {
    func getTypeDeclarations() -> [Syntax.TypeDefinition] {
        return self.definitions.compactMap { statement in
            if case let .typeDefinition(typeDefinition) = statement {
                return typeDefinition
            } else {
                return nil
            }
        }
    }
}

extension Syntax.Project: TypeDeclarationsChecker {
    func getTypeDeclarations() -> [Syntax.TypeDefinition] {
        return self.modules.values.flatMap { module in
            module.getTypeDeclarations()
        }
    }
}
