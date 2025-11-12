// extension Semantic.FunctionSignature {
// 	public func checkBody(
// 		body: Syntax.Expression,
// 		outputType: Semantic.TypeSpecifier,
// 		context: borrowing Semantic.DeclarationsContext
// 	) throws(Semantic.Error) -> Semantic.Expression {
// 		let inputExpression: Semantic.Expression
// 		let localScope: [Semantic.Tag: Semantic.TypeSpecifier]
//
// 		switch inputType.tag {
// 		case .input, .unnamed:
// 			localScope = arguments
// 			switch inputType.type {
// 			case .nothing:
// 				inputExpression = .nothing
// 			default:
// 				inputExpression = .input(type: inputType.type)
// 			}
// 		case .named:
// 			localScope = arguments.merging(
// 				[inputType.tag: inputType.type]
// 			) { $1 }
// 			inputExpression = .nothing
// 		}
//
// 		let bodyExpression = try body.checkType(
// 			with: inputExpression,
// 			localScope: localScope,
// 			context: context
// 		)
//
// 		if bodyExpression.type != outputType {
// 			throw .init(
// 				location: body.location,
// 				errorChoice: .functionBodyOutputTypeMismatch(
// 					expected: outputType, received: bodyExpression.type
// 				)
// 			)
// 		}
//
// 		return bodyExpression
// 	}
// }
//
// extension [Syntax.Expression] {
// 	/// Transforms a list of syntax expressions to a tagged list of semantic
// 	/// expressions.
// 	/// If an expression of the list is a tagged expressions,
// 	/// then the semantic expression is deconstructed.
// 	/// If the expression is untagged then an implicit tag is assigned to it, which
// 	/// is the index.
// 	/// # Params
// 	/// - with: the type specifier of the input expression
// 	/// - localScope: the local scope of the current context
// 	/// - context: the declarations context of the current module
// 	///
// 	/// # Returns
// 	/// Dictionary of tagged expressions, where the tag is either a named tag or an
// 	/// unnamed tag
// 	///
// 	/// # throws
// 	/// ``Semantic.Error`` if there is a duplicated expression field name or if the
// 	/// type checking fails
// 	public func checkType(
// 		with input: Semantic.Expression,
// 		localScope: borrowing Semantic.LocalScope,
// 		context: borrowing Semantic.DeclarationsContext
// 	) throws(Semantic.Error) -> [Semantic.Tag: Semantic.Expression] {
// 		var expressions: [Semantic.Tag: Semantic.Expression] = [:]
// 		var fieldCounter = UInt64(0)
// 		for expression in self {
// 			switch expression {
// 			case let .taggedExpression(taggedExpression):
// 				let expressionTag = Semantic.Tag.named(taggedExpression.tag)
// 				if expressions[expressionTag] != nil {
// 					throw .init(
// 						location: taggedExpression.location,
// 						errorChoice: .duplicatedExpressionFieldName
// 					)
// 				}
// 				expressions[expressionTag] =
// 					try taggedExpression.expression.checkType(
// 						with: input,
// 						localScope: localScope,
// 						context: context
// 					)
// 			default:
// 				let expressionTag = Semantic.Tag.unnamed(fieldCounter)
// 				fieldCounter += 1
// 				// WARN: this might be buggy, I guess I should put this outside the switch
// 				if expressions[expressionTag] != nil {
// 					throw .init(
// 						location: expression.location,
// 						errorChoice: .duplicatedExpressionFieldName
// 					)
// 				}
// 				expressions[expressionTag] =
// 					try expression.checkType(
// 						with: input,
// 						localScope: localScope,
// 						context: context
// 					)
// 			}
// 		}
// 		return expressions
// 	}
// }
//
// extension Syntax.Literal {
// 	func checkType(
// 		with input: Semantic.Expression,
// 		localScope _: borrowing Semantic.LocalScope,
// 		context _: borrowing Semantic.DeclarationsContext,
// 	) throws(Semantic.Error) -> Semantic.Expression {
// 		switch (input, value) {
// 		case (_, .never):
// 			return .never
// 		case (.nothing, .nothing):
// 			return .nothing
// 		case let (.nothing, .intLiteral(value)):
// 			return .intLiteral(value)
// 		case let (.nothing, .floatLiteral(value)):
// 			return .floatLiteral(value)
// 		case let (.nothing, .stringLiteral(value)):
// 			throw .init(
// 				location: location,
// 				errorChoice: .notImplemented(
// 					"String literal type checking is not implemented yet"
// 				)
// 			)
// 		// return .init(expression: .stringLiteral(value), type: .string)
// 		case let (.nothing, .boolLiteral(value)):
// 			return .boolLiteral(value)
// 		default:
// 			throw .init(
// 				location: location,
// 				errorChoice: .inputMismatch(
// 					expected: .nothing,
// 					received: input.type
// 				)
// 			)
// 		}
// 	}
// }
//
// extension Syntax.Unary {
// 	func checkType(
// 		with input: Semantic.Expression,
// 		localScope: borrowing Semantic.LocalScope,
// 		context: borrowing Semantic.DeclarationsContext,
// 	) throws(Semantic.Error) -> Semantic.Expression {
// 		// multiple consecutive unary operations are not allowed
// 		// because things like `+ * - exp` are allowed syntactically
// 		if case .unary = expression {
// 			throw .init(
// 				location: expression.location,
// 				errorChoice: .consecutiveUnary
// 			)
// 		}
//
// 		let typedExpression = try expression.checkType(
// 			with: .nothing,
// 			localScope: localScope,
// 			context: context
// 		)
//
// 		guard
// 			let opReturnType = context.operatorDeclarations[
// 				.init(left: input.type, right: typedExpression.type, op: op)
// 			]
// 		else {
// 			throw .init(
// 				location: expression.location,
// 				errorChoice: .invalidOperation(
// 					leftType: input.type,
// 					op: op,
// 					rightType: typedExpression.type
// 				)
// 			)
// 		}
//
// 		switch input.type {
// 		case .nothing:
// 			return .unary(op, expression: typedExpression, type: opReturnType)
// 		// if input is not nothing than this expression is considered a binary
// 		// expression
// 		default:
// 			return .binary(
// 				op, left: input, right: typedExpression, type: opReturnType
// 			)
// 		}
// 	}
// }
//
// extension Syntax.Binary {
// 	func checkType(
// 		with _: Semantic.Expression,
// 		localScope: borrowing Semantic.LocalScope,
// 		context: borrowing Semantic.DeclarationsContext,
// 	) throws(Semantic.Error) -> Semantic.Expression {
// 		let leftTyped = try left.checkType(
// 			with: .nothing,
// 			localScope: localScope,
// 			context: context
// 		)
//
// 		// FIX: this is problematic in case of an expression starting with an unary
// 		// this is only a error if a binary expression is nested inside another one
// 		if case .unary = left {
// 			throw .init(
// 				location: location,
// 				errorChoice: .consecutiveUnary
// 			)
// 		}
//
// 		let rightTyped = try right.checkType(
// 			with: .nothing,
// 			localScope: localScope,
// 			context: context
// 		)
//
// 		if case .unary = right {
// 			throw .init(
// 				location: location,
// 				errorChoice: .consecutiveUnary
// 			)
// 		}
//
// 		guard
// 			let opReturnType = context.operatorDeclarations[
// 				.init(left: leftTyped.type, right: rightTyped.type, op: op)
// 			]
// 		else {
// 			throw .init(
// 				location: location,
// 				errorChoice: .invalidOperation(
// 					leftType: leftTyped.type,
// 					op: op,
// 					rightType: rightTyped.type
// 				)
// 			)
// 		}
// 		return .binary(
// 			op, left: leftTyped, right: rightTyped, type: opReturnType
// 		)
// 	}
// }
//
// extension Syntax.Access {
// 	func checkType(
// 		with input: Semantic.Expression,
// 		localScope: borrowing Semantic.LocalScope,
// 		context: borrowing Semantic.DeclarationsContext,
// 	) throws(Semantic.Error) -> Semantic.Expression {
// 		let prefixTyped = try prefix.checkType(
// 			with: input,
// 			localScope: localScope,
// 			context: context
// 		)
//
// 		switch prefixTyped.type.getRawType(
// 			typeDeclarations: context.typeDeclarations
// 		) {
// 		case let .record(fields):
// 			let tag = Semantic.Tag.named(field)
// 			if let recordFieldType = fields[tag] {
// 				return .access(
// 					expression: prefixTyped,
// 					field: tag,
// 					type: recordFieldType
// 				)
// 			} else {
// 				throw .init(
// 					location: location,
// 					errorChoice: .accessFieldUnknown(field: field)
// 				)
// 			}
// 		default:
// 			throw .init(
// 				location: location,
// 				errorChoice: .accessingNonRecord
// 			)
// 		}
// 	}
// }
//
// extension Syntax.Call {
// 	private func methodCall(
// 		identifier: Semantic.QualifiedIdentifier,
// 		input: Semantic.Expression,
// 		arguments: [Semantic.Tag: Semantic.Expression],
// 		localScope _: borrowing Semantic.LocalScope,
// 		context: borrowing Semantic.DeclarationsContext
// 	) throws(Semantic.Error) -> Semantic.Expression {
// 		let functionSignature: Semantic.FunctionSignature =
// 			.init(
// 				identifier: identifier,
// 				inputType: (tag: .input, type: input.type),
// 				arguments: arguments.mapValues { $0.type }
// 			)
//
// 		// the nominal is a function call
// 		if let functionOutputType =
// 			context.functionDeclarations[functionSignature]
// 		{
// 			return .call(
// 				signature: functionSignature,
// 				input: input,
// 				arguments: arguments,
// 				type: functionOutputType
// 			)
// 		}
//
// 		throw .init(
// 			location: location,
// 			errorChoice: .undefinedCall(signature: functionSignature)
// 		)
// 	}
//
// 	func checkType(
// 		with input: Semantic.Expression,
// 		localScope: borrowing Semantic.LocalScope,
// 		context: borrowing Semantic.DeclarationsContext,
// 	) throws(Semantic.Error) -> Semantic.Expression {
// 		let argumentsTyped = try arguments.checkType(
// 			with: .nothing,
// 			localScope: localScope,
// 			context: context
// 		)
//
// 		switch prefix {
// 		case let .access(access):
// 			let prefixTyped = try access.prefix.checkType(
// 				with: input,
// 				localScope: localScope,
// 				context: context
// 			)
//
// 			return try methodCall(
// 				// TODO: have to consider qualified identifiers and scoping based on input type qualifier
// 				identifier: .init(chain: [access.field]),
// 				input: prefixTyped,
// 				arguments: argumentsTyped,
// 				localScope: localScope,
// 				context: context
// 			)
//
// 		case let .nominal(nominal):
// 			// the nominal is a type initializer
// 			let semanticIdentifier =
// 				nominal.identifier.getSemanticIdentifier()
// 			if let typeSpecifier = context.typeDeclarations[
// 				semanticIdentifier
// 			] {
// 				// TODO: I have to know how to deal with type aliases
// 				return .initializer(
// 					type: .nominal(semanticIdentifier),
// 					arguments: argumentsTyped
// 				)
// 			}
//
// 			return try methodCall(
// 				identifier: semanticIdentifier,
// 				input: input,
// 				arguments: argumentsTyped,
// 				localScope: localScope,
// 				context: context
// 			)
//
// 		case .none:
// 			// literal tuple
// 			return .initializer(
// 				type: .raw(.record(argumentsTyped.mapValues { $0.type })),
// 				arguments: argumentsTyped
// 			)
//
// 		default:
// 			throw .init(
// 				location: location,
// 				errorChoice: .notImplemented(
// 					"function call prefix \(String(describing: prefix)) not implemented"
// 				)
// 			)
// 		}
// 	}
// }
//
// extension Syntax.Pipe {
// 	func checkType(
// 		with input: Semantic.Expression,
// 		localScope: borrowing Semantic.LocalScope,
// 		context: borrowing Semantic.DeclarationsContext,
// 	) throws(Semantic.Error) -> Semantic.Expression {
// 		let leftTyped = try left.checkType(
// 			with: input,
// 			localScope: localScope,
// 			context: context
// 		)
//
// 		switch right {
// 		case let .branched(branched):
// 			return try branched.checkType(
// 				with: leftTyped,
// 				localScope: localScope,
// 				context: context
// 			)
// 		default:
// 			return try right.checkType(
// 				with: leftTyped,
// 				localScope: localScope,
// 				context: context
// 			)
// 		}
// 	}
// }
//
// extension Syntax.Expression {
// 	/// Checks the type of the syntax expression against the input expression type.
// 	/// A syntax expression is a node in the AST that represents an expression in
// 	/// the source code.
// 	/// ``checkType(with:localScope:context:)`` will return a typed checked
// 	/// semantic expression node by processing, type checking and performing
// 	/// semantic analysis on the AST.
// 	/// The generated semantic expression tree represents an intermediate
// 	/// representation of the source code, ready to be compiled.
// 	/// # Params:
// 	/// - with: the input expression. Expressions can have inputs and they need to
// 	/// be type matched.
// 	/// - localScope: the local scope of the current context, which contains
// 	/// bindings and local 'variable' names
// 	/// - context: the declarations context of the current module, which contains
// 	/// type, function and constant declarations
// 	/// # Returns:
// 	/// A ``Semantic.Expression`` that is a typed checked semantic expression node.
// 	/// A semantic expression is not a one to one mapping of the syntax expression,
// 	/// but rather an optimized intermediate representation of the source code.
// 	/// # Throws:
// 	/// A ``Semantic.Error`` if the type checking fails.
// 	/// # Notes:
// 	/// ``checkType(with:localScope:context:)`` will:
// 	/// - perform type checking of arithmetic operations
// 	/// - resolve field access expressions, identifiers and generic types (TODO)
// 	/// - deconstruct piped expressions into regular basic expressions and function
// 	/// calls
// 	/// - check branching expressions for exhaustiveness and type consistency
// 	func checkType(
// 		// swiftlint:disable:previous cyclomatic_complexity
// 		with input: Semantic.Expression,
// 		localScope: borrowing Semantic.LocalScope,
// 		context: borrowing Semantic.DeclarationsContext,
// 	) throws(Semantic.Error) -> Semantic.Expression {
// 		switch (input.type, self) {
// 		case let (_, .literal(literal)):
// 			return try literal.checkType(
// 				with: input,
// 				localScope: localScope,
// 				context: context
// 			)
// 		// Unary
// 		case let (_, .unary(unary)):
// 			return try unary.checkType(
// 				with: input,
// 				localScope: localScope,
// 				context: context
// 			)
// 		// Binary
// 		case let (.nothing, .binary(binary)):
// 			return try binary.checkType(
// 				with: input,
// 				localScope: localScope,
// 				context: context
// 			)
// 		// NOTE: Binary expressions need input to be nothing
// 		case (_, .binary):
// 			throw .init(
// 				location: location,
// 				errorChoice: .inputMismatch(
// 					expected: .nothing,
// 					received: input.type
// 				)
// 			)
// 		case let (_, .nominal(nominal)):
// 			if nominal.identifier.chain.count == 1,
// 				let field = nominal.identifier.chain.first
// 			{
// 				// NOTE: named and unnamed are equivalent, but I should figure out how to
// 				// switch between the two
// 				if input.type == .nothing,
// 					let fieldTypeInScope = localScope[.named(field)]
// 				{
// 					return .fieldInScope(
// 						tag: .named(field), type: fieldTypeInScope
// 					)
// 				} else {
// 					switch input.type.getRawType(
// 						typeDeclarations: context.typeDeclarations
// 					) {
// 					case let .record(fields):
// 						let tag = Semantic.Tag.named(field)
// 						if let recordFieldType = fields[tag] {
// 							return .access(
// 								expression: input, field: .named(field),
// 								type: recordFieldType
// 							)
// 						} else {
// 							throw .init(
// 								location: nominal.location,
// 								errorChoice: .accessFieldUnknown(field: field)
// 							)
// 						}
// 					default:
// 						throw .init(
// 							location: location,
// 							errorChoice: .accessingNonRecord
// 						)
// 					}
// 				}
// 			}
// 			// TODO: qualified identifiers might be compile time expressions or globals
// 			throw .init(
// 				location: location,
// 				errorChoice: .notImplemented(
// 					"Field expression type checking is not implemented yet"
// 				)
// 			)
// 		// NOTE: should bindings shadow definitions in scope or context
// 		case let (_, .access(access)):
// 			return try access.checkType(
// 				with: input,
// 				localScope: localScope,
// 				context: context
// 			)
// 		case let (_, .call(call)):
// 			return try call.checkType(
// 				with: input,
// 				localScope: localScope,
// 				context: context
// 			)
// 		case let (_, .branched(branched)):
// 			return try branched.checkType(
// 				with: input,
// 				localScope: localScope,
// 				context: context
// 			)
// 		case let (_, .piped(piped)):
// 			return try piped.checkType(
// 				with: input,
// 				localScope: localScope,
// 				context: context
// 			)
// 		case (_, .binding):
// 			throw .init(
// 				location: location,
// 				errorChoice: .bindingNotAllowed
// 			)
// 		case let (input, .function(function)):
// 			// NOTE: here I should infer signature if not present
// 			throw .init(
// 				location: location,
// 				errorChoice: .notImplemented(
// 					"Function expression type checking is not implemented yet"
// 				)
// 			)
// 		default:
// 			throw .init(
// 				location: location,
// 				errorChoice: .notImplemented(
// 					"abstract expression type checking is not implemented yet"
// 				)
// 			)
// 		}
// 		throw .init(
// 			location: location,
// 			errorChoice: .notImplemented(
// 				"Expression type checking is not implemented yet"
// 			)
// 		)
// 	}
// }
