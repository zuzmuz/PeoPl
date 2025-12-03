// MARK: Language Semantic Tree

// ============================
// This file defines the semantic tree structure of valid type checked
// Peopl code.

public enum Semantic {

	// MARK: - Core Types

	public typealias ElementId = Int

	/// Qualified identifier for symbol names
	public struct QualifiedIdentifier: Hashable, Sendable, Equatable {
		let chain: [String]

		public init(chain: [String]) {
			self.chain = chain
		}

		public static func + (
			lhs: QualifiedIdentifier,
			rhs: QualifiedIdentifier
		) -> QualifiedIdentifier {
			return .init(chain: lhs.chain + rhs.chain)
		}

		public static func + (
			lhs: QualifiedIdentifier,
			rhs: String
		) -> QualifiedIdentifier {
			return .init(chain: lhs.chain + [rhs])
		}

		public func parent() -> QualifiedIdentifier {
			return .init(chain: Array(chain.dropLast()))
		}

		public var description: String {
			chain.joined(separator: "\\")
		}
	}

	/// Element in the semantic tree representing a definition
	/// Elements form a hierarchy with parent-child relationships
	public struct Element: Sendable {
		/// Index in the elements array (parent reference)
		let parentId: ElementId
		/// Fully qualified identifier
		let qualifiedId: QualifiedIdentifier
		/// The original syntax expression
		let expression: Syntax.Expression

		public init(
			parentId: ElementId,
			qualifiedId: QualifiedIdentifier,
			expression: Syntax.Expression
		) {
			self.parentId = parentId
			self.qualifiedId = qualifiedId
			self.expression = expression
		}
	}

	public indirect enum Expression: Sendable {
		case typeDefinition(SymbolTable)
		case literal(Literal)
		case unary(
			op: Operator,
			expression: Expression,
			type: Expression,
			kind: Kind)
		case binary(
			op: Operator,
			lhs: Expression,
			rhs: Expression,
			type: Expression,
			kind: Kind)

		case nominal(QualifiedIdentifier, type: Expression)
		case function(
			input: Expression,
			arguments: [QualifiedIdentifier],
			output: Expression)
		case operation(
			lhs: Expression,
			rhs: Expression,
			output: Expression)
		case intrinsic(Intrinsic)
		case type

		case invalid

		var type: Expression {
			switch self {
			case .typeDefinition:
				.type
			case .literal(let literal):
				literal.type
			case .intrinsic:
				.type
			case .nominal(_, let type):
				type
			case .function(let input, let arguments, let output):
				.function(
					input: input,
					arguments: arguments,
					output: output.type)
			case .operation(let lhs, let rhs, let output):
				.operation(
					lhs: lhs,
					rhs: rhs,
					output: output.type)
			case .invalid:
				.invalid
			default:
				fatalError("not implemented")
			}
		}

		var kind: Kind {
			switch self {
			case .typeDefinition, .type, .intrinsic, .function, .operation:
				.compiletimeValue
			default:
				.runtimeValue
			}
		}

		var description: String {
			switch self {
			case .nominal(let id, _):
				return id.description
			case .unary(let op, _, let type, _):
				return "#\(op)(\(type.description))"
			case .invalid:
				return "!"
			default:
				fatalError("not implemented")
			}
		}
	}

	public enum Kind: Sendable {
		case runtimeValue
		case compiletimeValue
	}

	/// Symbol lookup table mapping qualified identifiers to syntax expression
	public typealias SymbolTable = [QualifiedIdentifier: Syntax.Expression]
	public typealias Context = [QualifiedIdentifier: Semantic.Expression]

	public enum Literal: Sendable {
		case int(UInt64)
		case float(Double)
		// case string(String)
		case bool(Bool)

		var type: Expression {
			switch self {
			case .int:
				.intrinsic(.int)
			case .float:
				.intrinsic(.float)
			case .bool:
				.intrinsic(.bool)
			}
		}
	}

	public enum Intrinsic: Sendable {
		case int
		case float
		case bool
	}
}

extension [Semantic.QualifiedIdentifier: Semantic.Expression] {
	func resolveSymbol(
		identifier: Semantic.QualifiedIdentifier,
		in scope: Semantic.QualifiedIdentifier
	) -> Semantic.Expression? {
		if let expression = self[scope + identifier] {
			return expression
		}
		if scope.chain.isEmpty {
			return nil
		}
		return resolveSymbol(identifier: identifier, in: scope.parent())
	}

	func resolveSymbol(
		_ identifier: String,
		in scope: Semantic.QualifiedIdentifier
	) -> Semantic.Expression? {
		return resolveSymbol(
			identifier: .init(chain: [identifier]),
			in: scope)
	}
}

// MARK: - Symbol Collection

extension Syntax.Expression {
	public func semanticTag(
		position: UInt32
	) -> (Semantic.QualifiedIdentifier, newPosition: UInt32) {
		switch self {
		case .taggedExpression(let tagged):
			switch tagged.expression {
			case .function(let function):
				fatalError(
					"I should figure out how to identify inputs for functions")
			default:
				return (.init(chain: tagged.tag.chain), newPosition: position)
			}
		default:
			return (.init(chain: ["$\(position)"]), newPosition: position + 1)
		}
	}

	public func resolveSymbols() -> (
		symbols: Semantic.SymbolTable,
		errors: [Semantic.Error]
	) {
		switch self {
		case .typeDefinition(let typeDefinition):
			typeDefinition.expressions.resolveSymbols()
		case .call(let call):
			call.arguments.resolveSymbols()
		default:
			fatalError("not implemented")
		}
	}

	public func resolveType(
		scope: Semantic.QualifiedIdentifier,
		context: Semantic.Context
	) -> (
		expression: Semantic.Expression,
		errors: [Semantic.Error]
	) {
		switch self {
		case .typeDefinition(let typeDefinition):
			let result = typeDefinition.expressions.resolveSymbols()
			return (.typeDefinition(result.symbols), result.errors)
		case .literal(let literal):
			return (literal.resolveType(), [])
		case .unary(let unary):
			return unary.resolveType(scope: scope, context: context)
		default:
			fatalError("not implemented")
		}
	}
}

extension Syntax.Literal {
	func resolveType() -> Semantic.Expression {
		switch self.value {
		case .intLiteral(let value):
			return .literal(.int(value))
		case .floatLiteral(let value):
			return .literal(.float(value))
		case .boolLiteral(let value):
			return .literal(.bool(value))
		default:
			fatalError("not implemented")
		}
	}
}

extension Syntax.Unary {
	func resolveType(
		scope: Semantic.QualifiedIdentifier,
		context: Semantic.Context
	) -> (
		expression: Semantic.Expression,
		errors: [Semantic.Error]
	) {
		let (typedExpression, errors) = self.expression.resolveType(
			scope: scope, context: context)
		let symbol = "#\(self.op)(\(typedExpression.type.description))"

		if let symbolExpression = context.resolveSymbol(
			symbol, in: scope),
			case .operation(_, _, let output) = symbolExpression
		{
			return (
				expression: .unary(
					op: self.op,
					expression: typedExpression,
					type: output,
					kind: typedExpression.kind),
				errors: errors
			)
		}

		return (
			expression: .invalid,
			errors: errors + [
				.invalidOperation(op: self.op, node: self.location)
			]
		)
	}
}

extension Syntax.Binary {
	func resolveType(
		scope: Semantic.QualifiedIdentifier,
		context: Semantic.Context
	) -> (
		expression: Semantic.Expression,
		errors: [Semantic.Error]
	) {
		let (typedLHS, lhsErrors) = self.left.resolveType(
			scope: scope, context: context)
		let (typedRHS, rhsErrors) = self.right.resolveType(
			scope: scope, context: context)

		let symbol =
			"#\(self.op)(\(typedLHS.type.description),\(typedRHS.type.description))"

		if let symbolExpression = context.resolveSymbol(
			symbol, in: scope),
			case .operation(_, _, let output) = symbolExpression
		{
			return (
				expression: .binary(
					op: self.op,
					lhs: typedLHS,
					rhs: typedRHS,
					type: output,
					kind: typedLHS.kind),
				errors: lhsErrors + rhsErrors
			)
		}

		return (
			expression: .invalid,
			errors: lhsErrors + rhsErrors + [
				.invalidOperation(op: self.op, node: self.location)
			]
		)
	}
}

extension [Syntax.Expression] {
	public func resolveSymbols() -> (
		symbols: Semantic.SymbolTable,
		errors: [Semantic.Error]
	) {
		let result:
			(
				positional: UInt32,
				errors: [Semantic.Error],
				symbols: Semantic.SymbolTable
			) = self.reduce(
				into: (
					positional: 0,
					errors: [],
					symbols: [:]
				)
			) { acc, expression in
				let (tag, newPosition) = expression.semanticTag(
					position: acc.positional)
				acc.positional = newPosition

				// let qualifiedId = parent + tag // NOTE: if parent is given

				if let existingSymbol = acc.symbols[tag] {
					// let error = Semantic.Error.redeclaration(
					// 	identifier: tag, nodes: [])
					// acc.errors.append(error)
					fatalError("Proper redeclation storing")
				}
				acc.symbols[tag] = expression
			}
		return (result.symbols, result.errors)
	}
}

extension Syntax.Module {
	/// First pass: collect all tagged top-level definitions
	/// Returns elements list and symbol table
	public func resolveSymbols() -> (
		symbols: Semantic.SymbolTable,
		errors: [Semantic.Error]
	) {
		return self.definitions.resolveSymbols()
	}
}
