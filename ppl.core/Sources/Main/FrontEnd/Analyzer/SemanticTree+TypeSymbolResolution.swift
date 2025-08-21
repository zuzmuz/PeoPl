// MARK: - Symbol Resolution For Types

// ===================================

/// Protocol for resolving type symbols
public protocol TypeDeclarationsChecker {
	/// Return all type declarations defined in module
	func getTypeDeclarations() -> [Syntax.Definition]

	/// Return resolved type definitions
	/// Maps scoped identifiers to semantic raw type specifiers
	/// Returns list of errors if found
	func resolveTypeSymbols(
		contextTypeDeclarations: borrowing Semantic.TypeDeclarationsMap
	) -> (
		typeDeclarations: Semantic.TypeDeclarationsMap,
		typeLookup: [Semantic.QualifiedIdentifier: Syntax.Definition],
		errors: [Semantic.Error]
	)
}

extension Syntax.QualifiedIdentifier {
	/// Create a semantic scoped identifier from self
	func getSemanticIdentifier() -> Semantic.QualifiedIdentifier {
		return .init(chain: chain)
	}
}

extension Syntax.TypeField {
	/// Retrieve all scoped identifier defined in this type field
	/// It represents the names of types used to define the type specifier of this
	/// type field
	func getTypeIdentifiers( /* namespace */
	) -> [Syntax.QualifiedIdentifier] {
		switch self {
		case let .typeSpecifier(typeSpecifier):
			return typeSpecifier.getTypeIdentifiers()
		case let .taggedTypeSpecifier(taggedTypeSpecifier):
			// in the context of choice types, type specifier is nothing
			// in the context of generic types type specifier is Type (the type set
			// containing all types)
			return taggedTypeSpecifier.typeSpecifier?.getTypeIdentifiers() ?? []
		case let .homogeneousTypeProduct(homogeneousTypeProduct):
			return homogeneousTypeProduct.typeSpecifier.getTypeIdentifiers()
		}
	}

	/// Return all scoped identifiers from the type specifier
	/// that do not belong in current type definitions
	/// nor in the context provided
	func undefinedTypes(
		types: borrowing Set<Semantic.QualifiedIdentifier>,
	) -> [Syntax.QualifiedIdentifier] {
		getTypeIdentifiers().filter { typeIdentifier in
			let semanticIdentifier = typeIdentifier.getSemanticIdentifier()
			return !types.contains(semanticIdentifier)
		}
	}
}

extension [Syntax.TypeField] {
	func getProductSemanticTypes() throws(Semantic.Error) -> [Semantic.Tag:
		Semantic.TypeSpecifier]
	{
		var recordFields: [Semantic.Tag: Semantic.TypeSpecifier] = [:]
		var fieldCounter = UInt64(0)
		for typeField in self {
			switch typeField {
			case let .typeSpecifier(typeSpecifier):
				let fieldTag = Semantic.Tag.unnamed(fieldCounter)
				if recordFields[fieldTag] != nil {
					throw .init(
						location: typeField.location,
						errorChoice: .duplicateFieldName
					)
				}
				recordFields[fieldTag] =
					try typeSpecifier.getSemanticType()
				fieldCounter += 1
			case let .taggedTypeSpecifier(taggedTypeSpecifier):
				let fieldTag = Semantic.Tag.named(
					taggedTypeSpecifier.tag
				)
				if recordFields[fieldTag] != nil {
					throw .init(
						location: typeField.location,
						errorChoice: .duplicateFieldName
					)
				}
				guard
					let typeSpecifier =
					taggedTypeSpecifier.typeSpecifier
				else {
					throw .init(
						location: typeField.location,
						errorChoice: .taggedTypeSpecifierRequired
					)
				}
				recordFields[fieldTag] =
					try typeSpecifier.getSemanticType()
				fieldCounter += 1
			case let .homogeneousTypeProduct(homogeneousTypeProduct):
				let semanticType = try homogeneousTypeProduct.typeSpecifier
					.getSemanticType()
				switch homogeneousTypeProduct.count {
				case let .literal(value):
					for index in 0 ..< value {
						let fieldTag = Semantic.Tag.unnamed(
							fieldCounter + index
						)
						if recordFields[fieldTag] != nil {
							throw .init(
								location: typeField.location,
								errorChoice: .duplicateFieldName
							)
						}
						recordFields[fieldTag] =
							semanticType
					}
					fieldCounter += value
				case .identifier:
					throw .init(
						location: typeField.location,
						errorChoice: .notImplemented(
							"compile time values not supported yet"
						)
					)
				}
			}
		}
		return recordFields
	}

	func getSumSemanticTypes() throws(Semantic.Error) -> [Semantic.Tag: Semantic
		.TypeSpecifier]
	{
		var recordFields: [Semantic.Tag: Semantic.TypeSpecifier] = [:]
		var fieldCounter = UInt64(0)
		for typeField in self {
			switch typeField {
			case let .typeSpecifier(typeSpecifier):
				recordFields[.unnamed(fieldCounter)] =
					try typeSpecifier.getSemanticType()
				fieldCounter += 1
			case let .taggedTypeSpecifier(taggedTypeSpecifier):
				recordFields[.named(taggedTypeSpecifier.tag)] =
					try taggedTypeSpecifier.typeSpecifier?.getSemanticType()
						?? .nothing
				fieldCounter += 1
			case .homogeneousTypeProduct:
				throw .init(
					location: typeField.location,
					errorChoice: .homogeneousTypeProductInSum
				)
			}
		}
		return recordFields
	}
}

extension Syntax.TypeSpecifier {
	/// Retrieve all scoped identifier defined in this type
	/// It represents the names of types used to define the type specifier
	func getTypeIdentifiers( /* TODO: handle namespacing */
	) -> [Syntax.QualifiedIdentifier] {
		switch self {
		case .nothing, .never:
			return []
		case let .nominal(nominal):
			return [nominal.identifier]
		case let .recordType(record):
			return record.typeFields.flatMap { $0.getTypeIdentifiers() }
		case let .choiceType(choice):
			return choice.typeFields.flatMap { $0.getTypeIdentifiers() }
		case let .function(function):
			return (function.inputType?.getTypeIdentifiers() ?? [])
				+ function.arguments.flatMap { $0.getTypeIdentifiers() }
				+ function.outputType.getTypeIdentifiers()
		}
	}

	/// Return all scoped identifiers from the type specifier
	/// that do not belong in current type definitions
	/// nor in the context provided
	func undefinedTypes(
		types: borrowing Set<Semantic.QualifiedIdentifier>,
	) -> [Syntax.QualifiedIdentifier] {
		getTypeIdentifiers().filter { typeIdentifier in
			let semanticIdentifier = typeIdentifier.getSemanticIdentifier()
			return !types.contains(semanticIdentifier)
		}
	}

	/// Create a semantic type specifier from self
	func getSemanticType() throws(Semantic.Error) -> Semantic.TypeSpecifier {
		switch self {
		case .nothing:
			return .nothing
		case .never:
			return .never
		case let .recordType(record):
			return try .raw(
				.record(record.typeFields.getProductSemanticTypes())
			)
		case let .choiceType(choice):
			return try .raw(.choice(choice.typeFields.getSumSemanticTypes()))
		case let .nominal(nominal):
			return .nominal(nominal.identifier.getSemanticIdentifier())
		case let .function(function):
			return .raw(
				.function(.init())
			)
		}
	}
}

extension Semantic.TypeSpecifier {
	/// Get the semantic type definition from a type sepcifier.
	/// This will return the raw definition of nominal types from the type
	/// definition table lookup
	func getRawType(
		typeDeclarations: borrowing [Semantic.QualifiedIdentifier:
			Semantic.TypeSpecifier]
	) -> Semantic.RawTypeSpecifier {
		switch self {
		case let .nominal(indentifier):
			return typeDeclarations[indentifier]!.getRawType(
				typeDeclarations: typeDeclarations
			)
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
	public func resolveTypeSymbols(
		contextTypeDeclarations: borrowing Semantic.TypeDeclarationsMap
	) -> (
		typeDeclarations: Semantic.TypeDeclarationsMap,
		typeLookup: Semantic.TypeLookupMap,
		errors: [Semantic.Error]
	) {
		let declarations = getTypeDeclarations()

		let typesLocations:
			[Semantic.QualifiedIdentifier: [Syntax.Definition]] =
			declarations.reduce(into: [:]) { acc, type in
				let semanticIdentifer =
					type.identifier.getSemanticIdentifier()
				acc[semanticIdentifer] =
					(acc[semanticIdentifer] ?? []) + [type]
			}

		// detecting redeclarations
		let redeclarations =
			typesLocations.flatMap { identifier, typeLocations in
				if typeLocations.count > 1 {
					let locations = typeLocations.map { $0.location }
					return typeLocations.map { typeLocation in
						Semantic.Error(
							location: typeLocation.location,
							errorChoice: .typeRedeclaration(
								identifier: identifier,
								otherLocations: locations
							)
						)
					}
				} else {
					return []
				}
			}

		let typeLookup = typesLocations.compactMapValues { types in
			types.first
		}

		let shadowing =
			typeLookup.compactMap { identifier, definition in
				if contextTypeDeclarations[identifier] != nil {
					return Semantic.Error(
						location: definition.location,
						errorChoice: .typeShadowing(
							identifier: identifier
						)
					)
				}
				return nil
			}

		let allTypes = Set(Array(typeLookup.keys)).union(
			Set(Array(contextTypeDeclarations.keys))
		)

		// detecting invalid members types
		let typesNotInScope = typeLookup.flatMap { _, definition in
			switch definition.definition {
			case let .typeSpecifier(typeSpecifier):
				return typeSpecifier.undefinedTypes(types: allTypes)
			default:
				return []
			}
		}.map {
			Semantic.Error(
				location: $0.location,
				errorChoice: .typeNotInScope(identifier: $0)
			)
		}

		// detecting cyclical dependencies
		let cyclicalDependencies = checkCyclicalDependencies(
			localTypeLookup: typeLookup
		)

		// get semantic type specifier from syntax type specifier
		var localTypeDeclarations:
			[Semantic.QualifiedIdentifier: Semantic.TypeSpecifier] = [:]
		var typeSepcifierErrors: [Semantic.Error] = []

		for (indentifier, typeDefinition) in typeLookup {
			do {
				if case let .typeSpecifier(typeSpecifier) =
					typeDefinition.definition
				{
					localTypeDeclarations[indentifier] =
						try typeSpecifier.getSemanticType()
				}
			} catch {
				typeSepcifierErrors.append(error)
			}
		}

		return (
			typeDeclarations: localTypeDeclarations,
			typeLookup: typeLookup,
			errors: redeclarations
				+ shadowing
				+ typesNotInScope
				+ cyclicalDependencies
				+ typeSepcifierErrors
		)
	}

	private func checkCyclicalDependencies(
		localTypeLookup: borrowing Semantic.TypeLookupMap
	) -> [Semantic.Error] {
		var nodeStates: [Syntax.QualifiedIdentifier: NodeState] = [:]
		var errors: [Semantic.Error] = []

		func checkCyclicalDependencies(
			typeSpecifier: Syntax.TypeSpecifier,
			stack: [Syntax.Definition]
		) {
			switch typeSpecifier {
			case .nothing, .never:
				break
			case let .nominal(nominal):
				// NOTE: intrinsics don't have definition
				if let typeDefinition = localTypeLookup[
					nominal.identifier.getSemanticIdentifier()
				] {
					checkCyclicalDependencies(
						typeDefinition: typeDefinition,
						stack: stack
					)
				}
			case let .recordType(record):
				for field in record.typeFields {
					switch field {
					case let .typeSpecifier(typeSpecifier):
						checkCyclicalDependencies(
							typeSpecifier: typeSpecifier,
							stack: stack
						)
					case let .taggedTypeSpecifier(taggedTypeSpecifier):
						if let typeSpecifier =
							taggedTypeSpecifier.typeSpecifier
						{
							checkCyclicalDependencies(
								typeSpecifier: typeSpecifier,
								stack: stack
							)
						} else {
							// NOTE: nil typeSpecifiers are not allowed in record types
							errors.append(
								.init(
									location: field.location,
									errorChoice: .taggedTypeSpecifierRequired
								)
							)
						}
					case let .homogeneousTypeProduct(homogeneousTypeProduct):
						checkCyclicalDependencies(
							typeSpecifier: homogeneousTypeProduct.typeSpecifier,
							stack: stack
						)
					}
				}
			case let .choiceType(choice):
				for field in choice.typeFields {
					switch field {
					case let .typeSpecifier(typeSpecifier):
						checkCyclicalDependencies(
							typeSpecifier: typeSpecifier,
							stack: stack
						)
					case let .taggedTypeSpecifier(taggedTypeSpecifier):
						if let typeSpecifier =
							taggedTypeSpecifier.typeSpecifier
						{
							checkCyclicalDependencies(
								typeSpecifier: typeSpecifier,
								stack: stack
							)
						}
					case .homogeneousTypeProduct:
						errors.append(
							.init(
								location: field.location,
								errorChoice: .homogeneousTypeProductInSum
							)
						)
					}
				}
			case .function:
				break
			}
		}

		func checkCyclicalDependencies(
			typeDefinition: Syntax.Definition,
			stack: [Syntax.Definition]
		) {
			let typeIdentifier = typeDefinition.identifier
			if nodeStates[typeIdentifier] == .visited {
				return
			}
			if nodeStates[typeIdentifier] == .visiting {
				for element in stack {
					errors.append(
						.init(
							location: typeIdentifier.location,
							errorChoice: .cyclicType(
								stack: stack
							)
						)
					)
				}
				return
			}
			nodeStates[typeIdentifier] = .visiting

			if case let .typeSpecifier(typeSpecifier) =
				typeDefinition.definition
			{
				checkCyclicalDependencies(
					typeSpecifier: typeSpecifier,
					stack: stack + [typeDefinition]
				)
				nodeStates[typeIdentifier] = .visited
			}
		}

		for (_, typeDefinition) in localTypeLookup {
			checkCyclicalDependencies(
				typeDefinition: typeDefinition,
				stack: []
			)
		}

		return errors
	}
}

extension Syntax.Module: TypeDeclarationsChecker {
	public func getTypeDeclarations() -> [Syntax.Definition] {
		return definitions.filter { definition in
			switch definition.definition {
			case .typeSpecifier:
				return true
			default:
				// TODO: if definition is nominal, it is an alias, either to a value or a type, it should be included if it is type alias (relevant for generics)
				return false
			}
		}
	}
}

extension Syntax.Project: TypeDeclarationsChecker {
	public func getTypeDeclarations() -> [Syntax.Definition] {
		return modules.values.flatMap { module in
			module.getTypeDeclarations()
		}
	}
}
