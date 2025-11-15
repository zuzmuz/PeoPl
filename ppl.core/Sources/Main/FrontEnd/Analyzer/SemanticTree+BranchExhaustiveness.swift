#if ANALYZER

extension Syntax.Expression {
	func getPattern(
		localScope: borrowing Semantic.LocalScope,
		context: borrowing Semantic.DeclarationsContext
	) throws(Semantic.Error) -> Semantic.Pattern {
		switch self {
		case .literal, .binary:
			return try .value(
				checkType(
					with: .nothing,
					localScope: localScope,
					context: context
				)
			)
		case let .nominal(nominal):
			if nominal.identifier.chain == ["_"] {
				return .wildcard
			} else {
				return try .value(
					checkType(
						with: .nothing,
						localScope: localScope,
						context: context
					)
				)
			}
		case let .unary(unary):
			if unary.op == .plus
				|| unary.op == .minus
				|| unary.op == .not
			{
				return try .value(
					checkType(
						with: .nothing,
						localScope: localScope,
						context: context
					)
				)
			} else {
				throw .init(
					location: location,
					errorChoice: .illegalUnaryInMatch(op: unary.op)
				)
			}
		case let .binding(binding):
			return .binding(.named(binding.identifier))
		case let .call(call):
			return try .destructor(
				call.arguments.getPattern(
					localScope: localScope, context: context
				)
			)
		case let .taggedExpression(taggedExpression):
			return try .constructor(
				tag: .named(taggedExpression.tag),
				pattern: taggedExpression.expression.getPattern(
					localScope: localScope, context: context
				)
			)
		default:
			throw .init(
				location: location,
				errorChoice: .notImplemented(
					"advanced pattern matching feature"
				)
			)
		}
	}
}

extension [Syntax.Expression] {
	func getPattern(
		localScope: borrowing Semantic.LocalScope,
		context: borrowing Semantic.DeclarationsContext
	) throws(Semantic.Error) -> [Semantic.Tag: Semantic.Pattern] {
		var patterns: [Semantic.Tag: Semantic.Pattern] = [:]
		var fieldCounter = UInt64(0)
		for expression in self {
			switch expression {
			case let .taggedExpression(taggedExpression):
				let expressionTag = Semantic.Tag.named(taggedExpression.tag)
				if patterns[expressionTag] != nil {
					throw .init(
						location: taggedExpression.location,
						errorChoice: .duplicatedExpressionFieldName
					)
				}
				patterns[expressionTag] =
					try taggedExpression.expression.getPattern(
						localScope: localScope,
						context: context
					)
			default:
				let expressionTag = Semantic.Tag.unnamed(fieldCounter)
				fieldCounter += 1
				// WARN: this might be buggy, I guess I should put this outside the switch
				// No actually this might be a great idea mainly because positional
				// arguments don't need to be in the correct place rather they just need to
				// be sequential
				if patterns[expressionTag] != nil {
					throw .init(
						location: expression.location,
						errorChoice: .duplicatedExpressionFieldName
					)
				}
				patterns[expressionTag] =
					try expression.getPattern(
						localScope: localScope,
						context: context
					)
			}
		}
		return patterns
	}
}

extension Semantic.Pattern {
	func getTypedCheckBindings(
		with input: Semantic.Expression,
		localScope: borrowing Semantic.LocalScope,
		context: borrowing Semantic.DeclarationsContext
	) throws(Semantic.PatternError) -> [Semantic.Tag: Semantic.Expression] {
		switch self {
		case .wildcard: return [:]
		case let .binding(tag):
			return [tag: input]
		case let .value(expression):
			if expression.type != input.type {
				throw .bindingTypeMismatch
			} else {
				return [:]
			}
		case let .destructor(patterns):
			let rawType = input.type.getRawType(
				typeDeclarations: context.typeDeclarations
			)
			switch rawType {
			case let .record(fields):
				guard fields.count == patterns.count else {
					throw .numberOfPatternMismatch(
						expected: fields.count, received: patterns.count
					)
				}

				var bindings: [Semantic.Tag: Semantic.Expression] = [:]

				for (tag, typeSpecifier) in fields {
					// NOTE: consider spread operator of some sort to enable partial pattern
					// matching (might be a bad idea)
					guard let pattern = patterns[tag] else {
						throw .recordFieldMissing(tag: tag)
					}

					let patternBindings = try pattern.getTypedCheckBindings(
						with: .access(
							expression: input, field: tag, type: typeSpecifier
						),
						localScope: localScope,
						context: context
					)

					// check if there's any binding label duplicates
					let oldBindingsCount = bindings.count
					bindings.merge(patternBindings) { $1 }

					if bindings.count < oldBindingsCount + patternBindings.count {
						throw .duplicateBindings
					}
				}

				return bindings
			default:
				// TODO: this is not maybe wrong
				throw .numberOfPatternMismatch(
					expected: 1, received: patterns.count
				)
			}
		case let .constructor(tag, pattern):
			fatalError()
		// patterns.reduce(into: [:]) { pattern in
		//     pattern.type
		// }
		}
	}
}

extension Syntax.Branched {
	func checkType(
		with input: Semantic.Expression,
		localScope: Semantic.LocalScope,
		context: borrowing Semantic.DeclarationsContext,
	) throws(Semantic.Error) -> Semantic.Expression {
		let decompositionMatrixRow =
			try branches.map { branch throws(Semantic.Error) in
				let pattern = try branch.matchExpression.getPattern(
					localScope: localScope, context: context
				)
				let bindings: [Semantic.Tag: Semantic.Expression]
				do throws(Semantic.PatternError) {
					bindings = try pattern.getTypedCheckBindings(
						with: input,
						localScope: localScope,
						context: context
					)
				} catch {
					throw .init(
						location: branch.matchExpression.location,
						errorChoice: .bindingPatternError(error)
					)
				}
				let bindingTypes = bindings.mapValues { $0.type }
				let extendedLocalScope = localScope.merging(bindingTypes) { $1 }
				// let extendedLocalScope: Semantic.LocalScope = localScope.merging(
				//     bindings.mapValues { $0.type }
				// ) { $1 }

				// TODO: guard expression should be checked
				let guardExpression =
					try branch.guardExpression?.checkType(
						with: .boolLiteral(true),
						localScope: extendedLocalScope,
						context: context
					)
					?? .boolLiteral(true)
				if guardExpression.type != .bool {
					throw .init(
						location: self.location,
						errorChoice: .guardShouldReturnBool(
							received: guardExpression.type
						)
					)
				}

				let bodyExpression =
					try branch.body.checkType(
						with: .nothing,
						localScope: extendedLocalScope,
						context: context
					)
				return Semantic.DecompositionMatrix.Row(
					pattern: pattern,
					bindings: bindings,
					guardExpression: guardExpression,
					body: bodyExpression
				)
			}

		// removing duplicate types while keeping order
		let branchesType: [Semantic.TypeSpecifier] =
			decompositionMatrixRow.reduce(into: []) { arr, branch in
				let branchType = branch.body.type

				// Never type can be ignored
				if !arr.contains(branchType) && branchType != .never {
					arr.append(branchType)
				}
			}

		let type: Semantic.TypeSpecifier
		if branchesType.isEmpty {
			type = .never
		} else if branchesType.count == 1, let branchType = branchesType.first {
			type = branchType
		} else {
			type = .raw(
				.choice(
					branchesType
						.enumerated()
						.reduce(into: [:]) { acc, element in
							acc[.unnamed(UInt64(element.offset))] =
								element.element
						}
				)
			)
		}
		return .branched(
			matrix: .init(rows: decompositionMatrixRow),
			type: type
		)
	}

	// private static func validateExhaustiveness(
	//     input: Semantic.Expression,
	//     branches: [Semantic.Branch],
	//     context: borrowing Semantic.DeclarationsContext
	// ) throws(Semantic.Error) {
	//
	// }
}
#endif
