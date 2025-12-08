// MARK: Language Semantic Tree

// ============================
// This file defines the semantic tree structure of valid type checked
// Peopl code.

public enum Semantic {

	// MARK: - Core Types

	public typealias ElementId = Int

	/// Qualified identifier for symbol names
	public enum IdElement: Hashable, Sendable, Equatable {
		case named(String)
		case positional(UInt32)
		case functionNoInput(name: String, args: Set<QualifiedIdentifier>)
		case operation(op: Operator)  //, lhs: Expression, rhs: Expression)

		var description: String {
			switch self {
			case .named(let name):
				return name
			case .positional(let position):
				return "$\(position)"
			case .functionNoInput(let name, let args):
				let argsDescription =
					args
					.map { $0.description }
					.sorted()
					.joined(separator: ",")
				return "\(name)(\(argsDescription))"
			case .operation(let op):
				return "#\(op)"
			}
		}
	}

	public struct QualifiedIdentifier: Hashable, Sendable, Equatable {
		let chain: [IdElement]

		public init(chain: [String]) {
			self.chain = chain.map { .named($0) }
		}

		public init(chain: [IdElement]) {
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
			return .init(chain: lhs.chain + [.named(rhs)])
		}

		public func parent() -> QualifiedIdentifier {
			return .init(chain: Array(chain.dropLast()))
		}

		public var description: String {
			chain.map { $0.description }.joined(separator: "\\")
		}

		static let empty = QualifiedIdentifier(chain: [IdElement]())
	}

	public indirect enum Expression: Sendable {
		case typeDefinition
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

		case nominal(QualifiedIdentifier, type: Expression, kind: Kind)
		case function(
			input: Expression,
			arguments: Set<QualifiedIdentifier>,
			output: Expression)
		case operation(
			lhs: Expression,
			rhs: Expression,
			output: Expression)
		case intrinsic(Intrinsic)
		case type

		case invalid

		static let nothing: Expression = .typeDefinition

		var type: Expression {
			switch self {
			case .typeDefinition:
				.type
			case .literal(let literal):
				literal.type
			case .unary(_, _, let type, _):
				type
			case .binary(_, _, _, let type, _):
				type
			case .intrinsic:
				.type
			case .nominal(_, let type, _):
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
				fatalError("not implemented \(self)")
			}
		}

		var kind: Kind {
			switch self {
			case .literal, .type, .intrinsic, .function,
				.operation:
				.compiletimeValue
			case .nominal(_, _, let kind):
				kind
			case .unary(_, _, _, let kind):
				kind
			case .binary(_, _, _, _, let kind):
				kind
			default:
				.runtimeValue
			}
		}

		var description: String {
			switch self {
			case .nominal(let id, _, _):
				return id.description
			case .unary(let op, _, let type, _):
				return "#\(op)(\(type.description))"
			case .binary(let op, let lhs, let rhs, _, _):
				return "#\(op)(\(lhs.type),\(rhs.type))"
			case .invalid:
				return "!"
			default:
				fatalError("not implemented \(self)")
			}
		}
	}

	public enum Kind: Sendable {
		case runtimeValue
		case compiletimeValue

		static func & (
			lhs: Kind,
			rhs: Kind
		) -> Kind {
			switch (lhs, rhs) {
			case (.compiletimeValue, .compiletimeValue):
				return .compiletimeValue
			default:
				return .runtimeValue
			}
		}
	}

	public struct LocalContext {
		let symbols: [QualifiedIdentifier: Syntax.Expression]
		var context: [QualifiedIdentifier: Semantic.Expression]
		fileprivate var visitingSymbols: [QualifiedIdentifier: Bool]

		public init(symbols: [QualifiedIdentifier: Syntax.Expression]) {
			self.symbols = symbols
			self.visitingSymbols = [:]
			self.context = [:]
		}
	}

	public enum Literal: Sendable {
		case int(UInt64)
		case float(Double)
		// case string(String)
		case bool(Bool)

		var type: Expression {
			switch self {
			case .int:
				.nominal(
					.init(chain: ["Int"]), type: .type, kind: .compiletimeValue)
			case .float:
				.nominal(
					.init(chain: ["Float"]), type: .type, kind: .compiletimeValue)
			case .bool:
				.nominal(
					.init(chain: ["Bool"]), type: .type, kind: .compiletimeValue)
			}
		}
	}
}

extension Dictionary where Key == Semantic.QualifiedIdentifier {
	func resolveSymbol(
		identifier: Semantic.QualifiedIdentifier,
		in scope: Semantic.QualifiedIdentifier
	) -> (Key, Value)? {
		// print("typing to resolve symbol: \(identifier.description) in scope: \(scope.description)")
		let newIdentifier = scope + identifier
		if let expression = self[newIdentifier] {
			return (newIdentifier, expression)
		}
		if scope.chain.isEmpty {
			return nil
		}
		return resolveSymbol(identifier: identifier, in: scope.parent())
	}

	func resolveSymbol(
		_ identifier: String,
		in scope: Semantic.QualifiedIdentifier
	) -> (Key, Value)? {
		return resolveSymbol(
			identifier: .init(chain: [identifier]),
			in: scope)
	}
}

extension Syntax.QualifiedIdentifier {
	func getSemanticId() -> Semantic.QualifiedIdentifier {
		return Semantic.QualifiedIdentifier(chain: self.chain)
	}

	func resolve(
		in scope: Semantic.QualifiedIdentifier,
		inheritedContext:
			borrowing [Semantic.QualifiedIdentifier: Semantic.Expression],
		localContext: inout Semantic.LocalContext,
		errors: inout [Semantic.Error]
	) -> Semantic.Expression {
		let semanticId = self.getSemanticId()

		// First step:
		// Looking in local resolved context first
		if let (fullId, expression) = localContext.context.resolveSymbol(
			identifier: semanticId, in: scope)
		{
			return .nominal(
				fullId,
				type: expression.type,
				kind: expression.kind
			)
		}
		// Second step:
		// Check if symbol is in current symbols,
		// if the symbol is currently being resolved, it means there's cycle
		else if let (fullId, nodeState) = localContext.visitingSymbols.resolveSymbol(
			identifier: semanticId,
			in: scope), nodeState
		{
			errors.append(
				.cycle(
					identifier: fullId, node: self.location))
			return .invalid
		}
		// Third step:
		// If node is unvisited, resolve the type of identifier
		else if let (fullId, syntaxExpression) =
			localContext.symbols.resolveSymbol(
			identifier: semanticId, in: scope)
		{
			// Mark current symbol as visiting to detect cycle
			localContext.visitingSymbols[fullId] = true

			let semanticExpression = syntaxExpression.resolve(
				scope: fullId,
				inheritedContext: inheritedContext,
				localContext: &localContext,
				errors: &errors)

			localContext.visitingSymbols[fullId] = false
			return .nominal(
				fullId,
				type: semanticExpression.type,
				kind: semanticExpression.kind
			)
		}
		// Forth step:
		// Look into inherited context
		else if let (fullId, expression) = inheritedContext.resolveSymbol(
			identifier: semanticId,
			in: scope)
		{
				return .nominal(
				fullId,
				type: expression.type,
				kind: expression.kind
			)
		}
		// Fifth step:
		// Symbol resolution failed, the identifier is undefined
		else {
			errors.append(
				.undefinedIdentifier(
					identifier: semanticId, node: self.location))
			return .invalid
		}
	}
}

// MARK: - Symbol Collection

extension Syntax.Expression {
	public func generateTaggedExpression(
		position: UInt32
	) -> (
		tag: Semantic.QualifiedIdentifier,
		expression: Syntax.Expression,
		newPosition: UInt32,
		errors: [Semantic.Error]
	) {
		switch self {
		case .taggedExpression(let tagged):
			switch tagged.expression {
			case .function(let function):
				if function.input == nil {
					let functionName = (tagged.tag.chain.last ?? "")
					let (argumentsSets, errors) = function.arguments.generateSymbols(
						scope: .empty)
					return (
						tag: .init(
							chain: tagged.tag.chain.dropLast().map { .named($0) } + [
								.functionNoInput(
									name: functionName.description,
									args: Set(argumentsSets.keys))
							]),
						expression: tagged.expression,
						newPosition: position,
						errors: errors
					)
				}
				fatalError("Need to handle function with input")
			default:
				return (
					tag: .init(chain: tagged.tag.chain),
					expression: tagged.expression,
					newPosition: position,
					errors: []
				)
			}
		default:
			return (
				tag: .init(chain: [.positional(position)]),
				expression: self,
				newPosition: position + 1,
				errors: []
			)
		}
	}

	fileprivate func resolve(
		scope: Semantic.QualifiedIdentifier,
		inheritedContext:
			borrowing [Semantic.QualifiedIdentifier: Semantic.Expression],
		localContext: inout Semantic.LocalContext,
		errors: inout [Semantic.Error]
	) -> Semantic.Expression {
		// print("resolving expression in scope: \(scope.description)")
		switch self {
		case .literal(let literal):
			return literal.resolve()
		case .unary(let unary):
			fatalError()
		case .binary(let binary):
			fatalError()
		case .nominal(let identifier):
			fatalError()
		case .call(let call):
			fatalError()
		case .function(let function):
			fatalError()
		default:
			fatalError("not implemented \(self)")
		}
	}
}

extension Syntax.Literal {
	func resolve() -> Semantic.Expression {
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
	fileprivate func resolveType(
		scope: Semantic.QualifiedIdentifier,
	) -> Semantic.Expression {
		return .invalid
	}
}

extension Syntax.Binary {
	fileprivate func resolveType(
		scope: Semantic.QualifiedIdentifier,
	) -> Semantic.Expression {
		//
		// let typedLHS = self.left.resolveType(
		// 	scope: scope,
		// 	context: &context,
		// )
		//
		// let typedRHS = self.right.resolveType(
		// 	scope: scope,
		// 	context: &context,
		// )
		//
		// let symbol =
		// 	"#\(self.op.rawValue)(\(typedLHS.type.description),\(typedRHS.type.description))"
		//
		// // FIXME: should consider the symbol resolution algo to be common to all
		// if let (_, symbolExpression) = context.inheritedContext.resolveSymbol(
		// 	symbol, in: scope),
		// 	case .operation(_, _, let output) = symbolExpression
		// {
		// 	return .binary(
		// 		op: self.op,
		// 		lhs: typedLHS,
		// 		rhs: typedRHS,
		// 		type: output,
		// 		kind: typedLHS.kind & typedRHS.kind)
		// }
		// // errors.append(
		// // 	.invalidOperation(op: self.op, node: self.location))
		return .invalid
	}
}

extension Syntax.Function {
	fileprivate func resolveType(
		scope: Semantic.QualifiedIdentifier,
	) -> Semantic.Expression {
		// let input = self.input?.resolveType(
		// 	scope: scope,
		// 	context: &context,
		// )
		//
		// let argumentsSymbols = self.arguments.generateSymbols(scope: scope)
		// // TODO: figure out scoping of arguments
		//
		// // let output: Semantic.Expression
		// //
		// // return .function(
		// // 	input: input ?? .nothing,
		// // 	arguments: arguments,
		// // 	output: output
		// // )
		fatalError("not implemented")
	}
}

extension [Syntax.Expression] {
	public func generateSymbols(scope: Semantic.QualifiedIdentifier) -> (
		symbols: [Semantic.QualifiedIdentifier: Syntax.Expression],
		errors: [Semantic.Error]
	) {
		let result:
			(
				positional: UInt32,
				errors: [Semantic.Error],
				symbols: [Semantic.QualifiedIdentifier: Syntax.Expression]
			) = self.reduce(
				into: (
					positional: 0,
					errors: [],
					symbols: [:]
				)
			) { acc, expression in
				let (tag, expression, newPosition, errors) =
					expression.generateTaggedExpression(
						position: acc.positional)
				acc.positional = newPosition

				acc.errors.append(contentsOf: errors)

				let qualifiedId = scope + tag

				if let existingSymbol = acc.symbols[qualifiedId] {
					acc.errors.append(
						.redeclaration(
							identifier: qualifiedId,
							node: expression.location))
				}
				if let existingSymbol = acc.symbols[tag] {
					acc.errors.append(
						.shadowing(
							identifier: qualifiedId,
							node: expression.location))
				}
				acc.symbols[qualifiedId] = expression
			}
		return (result.symbols, result.errors)
	}
}

extension Syntax.Module {
	public func resolveExpressions(
		scope: Semantic.QualifiedIdentifier,
		inheritedContext: [Semantic.QualifiedIdentifier: Semantic.Expression]
	) -> (
		context: [Semantic.QualifiedIdentifier: Semantic.Expression],
		errors: [Semantic.Error]
	) {
		let result = self.definitions.generateSymbols(scope: scope)
		let symbols = result.symbols
		var localContext = Semantic.LocalContext(context: [Semantic.QualifiedIdentifier : Semantic.Expression], symbols: [Semantic.QualifiedIdentifier : Syntax.Expression], symbolsState: [Semantic.QualifiedIdentifier : Semantic.NodeState]
		var currentContext: Semantic.Context = [:]
		var symbolsState: [Semantic.QualifiedIdentifier: NodeState] =
			symbols.mapValues { _ in
				.unvisited  // TODO: not sure if this is necessary
			}
		var errors: [Semantic.Error] = []

		for (identifier, expression) in symbols {
			// NOTE: I don't think I need to resolve the identifier recursively
			if currentContext.resolveSymbol(identifier: identifier, in: scope)
				!= nil
			{
				continue
			}
			currentContext[identifier] = expression.resolveType(
				scope: identifier,
				context: context,
				currentSymbols: symbols,
				symbolsState: &symbolsState,
				currentContext: &currentContext,
				errors: &errors)
		}

		return (
			currentContext,
			errors
		)
	}
}
