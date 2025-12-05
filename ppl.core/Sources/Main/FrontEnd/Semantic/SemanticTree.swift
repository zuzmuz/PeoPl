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

		static let nothing: Expression = .typeDefinition([:])

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
			case .literal, .typeDefinition, .type, .intrinsic, .function,
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

	public enum Intrinsic: Sendable {
		case int
		case float
		case bool
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

// MARK: - Symbol Collection

private enum NodeState {
	case unvisited
	case visiting
	case visited
}

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

	public func resolveSymbols() -> (
		symbols: Semantic.SymbolTable,
		errors: [Semantic.Error]
	) {
		switch self {
		// case .typeDefinition(let typeDefinition):
		// 	typeDefinition.expressions.resolveSymbols()
		// case .call(let call):
		// 	call.arguments.resolveSymbols()
		default:
			fatalError("not implemented")
		}
	}

	fileprivate func resolveType(
		scope: Semantic.QualifiedIdentifier,
		context: Semantic.Context,
		currentSymbols: borrowing Semantic.SymbolTable,
		symbolsState: inout [Semantic.QualifiedIdentifier: NodeState],
		currentContext: inout Semantic.Context,
		errors: inout [Semantic.Error]
	) -> Semantic.Expression {
		// print("resolving expression in scope: \(scope.description)")
		switch self {
		case .literal(let literal):
			return literal.resolveType()
		case .unary(let unary):
			return unary.resolveType(
				scope: scope,
				context: context,
				currentSymbols: currentSymbols,
				symbolsState: &symbolsState,
				currentContext: &currentContext,
				errors: &errors)
		case .binary(let binary):
			return binary.resolveType(
				scope: scope,
				context: context,
				currentSymbols: currentSymbols,
				symbolsState: &symbolsState,
				currentContext: &currentContext,
				errors: &errors)
		case .nominal(let identifier):
			return self.resolveIdentifier(
				identifier: identifier,
				scope: scope,
				context: context,
				currentSymbols: currentSymbols,
				symbolsState: &symbolsState,
				currentContext: &currentContext,
				errors: &errors)
		case .function(let function):
			return function.resolveType(
				scope: scope,
				context: context,
				currentSymbols: currentSymbols,
				symbolsState: &symbolsState,
				currentContext: &currentContext,
				errors: &errors)
		default:
			fatalError("not implemented \(self)")
		}
	}

	fileprivate func resolveIdentifier(
		identifier: Syntax.QualifiedIdentifier,
		scope: Semantic.QualifiedIdentifier,
		context: Semantic.Context,
		currentSymbols: borrowing Semantic.SymbolTable,
		symbolsState: inout [Semantic.QualifiedIdentifier: NodeState],
		currentContext: inout Semantic.Context,
		errors: inout [Semantic.Error]
	) -> Semantic.Expression {
		// print("resolving identifier: \(identifier.chain) in scope: \(scope.description)")
		let semanticIdentifier = Semantic.QualifiedIdentifier(
			chain: identifier.chain)

		// Looking in local resolved context first
		if let (fullIdentifier, semanticExpression) = currentContext.resolveSymbol(
			identifier: semanticIdentifier,
			in: scope)
		{
			// print("in local context: \(semanticIdentifier.description)")
			return .nominal(
				fullIdentifier,
				type: semanticExpression.type,
				kind: semanticExpression.kind)
		}
		// checking if symbol exists in current unevaluated symbols
		else if let (fullIdentifier, nodeState) = symbolsState.resolveSymbol(
			identifier: semanticIdentifier,
			in: scope), nodeState == .visiting
		{
			errors.append(
				.cycle(identifier: fullIdentifier, node: self.location))
			return .invalid
		}
		// evaluating symbol from current unevaluated symbols
		else if let (fullIdentifier, syntaxExpression) = currentSymbols.resolveSymbol(
			identifier: semanticIdentifier,
			in: scope)
		{
			// print("in current symbols: \(semanticIdentifier.description)")
			// Marking as visiting
			symbolsState[fullIdentifier] = .visiting

			let semanticExpression = syntaxExpression.resolveType(
				scope: fullIdentifier,
				context: context,
				currentSymbols: currentSymbols,
				symbolsState: &symbolsState,
				currentContext: &currentContext,
				errors: &errors)

			// Marking as visited
			symbolsState[fullIdentifier] = .visited

			// Storing evaluated expression in current context
			currentContext[fullIdentifier] = semanticExpression

			return .nominal(
				fullIdentifier,
				type: semanticExpression.type,
				kind: semanticExpression.kind)
		}
		// Looking in global context next
		else if let (fullIdentifier, semanticExpression) = context.resolveSymbol(
			identifier: semanticIdentifier,
			in: scope)
		{
			// print("in global context: \(semanticIdentifier.description)")
			return .nominal(
				fullIdentifier,
				type: semanticExpression.type,
				kind: semanticExpression.kind)

		} else {
			errors.append(
				.undefinedIdentifier(
					identifier: semanticIdentifier,
					node: self.location))
			return .invalid
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
	fileprivate func resolveType(
		scope: Semantic.QualifiedIdentifier,
		context: Semantic.Context,
		currentSymbols: borrowing Semantic.SymbolTable,
		symbolsState: inout [Semantic.QualifiedIdentifier: NodeState],
		currentContext: inout Semantic.Context,
		errors: inout [Semantic.Error]
	) -> Semantic.Expression {
		let typedExpression = self.expression.resolveType(
			scope: scope,
			context: context,
			currentSymbols: currentSymbols,
			symbolsState: &symbolsState,
			currentContext: &currentContext,
			errors: &errors)

		let symbol = "#\(self.op.rawValue)(\(typedExpression.type.description))"
		
		// FIXME: should consider the symbol resolution algo to be common to all
		if let (_, symbolExpression) = context.resolveSymbol(
			symbol, in: scope),
			case .operation(_, _, let output) = symbolExpression
		{
			return .unary(
				op: self.op,
				expression: typedExpression,
				type: output,
				kind: typedExpression.kind)
		}
		errors.append(
			.invalidOperation(op: self.op, node: self.location))
		return .invalid
	}
}

extension Syntax.Binary {
	fileprivate func resolveType(
		scope: Semantic.QualifiedIdentifier,
		context: Semantic.Context,
		currentSymbols: borrowing Semantic.SymbolTable,
		symbolsState: inout [Semantic.QualifiedIdentifier: NodeState],
		currentContext: inout Semantic.Context,
		errors: inout [Semantic.Error]
	) -> Semantic.Expression {

		let typedLHS = self.left.resolveType(
			scope: scope,
			context: context,
			currentSymbols: currentSymbols,
			symbolsState: &symbolsState,
			currentContext: &currentContext,
			errors: &errors)

		let typedRHS = self.right.resolveType(
			scope: scope,
			context: context,
			currentSymbols: currentSymbols,
			symbolsState: &symbolsState,
			currentContext: &currentContext,
			errors: &errors)

		let symbol =
			"#\(self.op.rawValue)(\(typedLHS.type.description),\(typedRHS.type.description))"
		
		// FIXME: should consider the symbol resolution algo to be common to all
		if let (_, symbolExpression) = context.resolveSymbol(
			symbol, in: scope),
			case .operation(_, _, let output) = symbolExpression
		{
			return .binary(
				op: self.op,
				lhs: typedLHS,
				rhs: typedRHS,
				type: output,
				kind: typedLHS.kind & typedRHS.kind)
		}
		errors.append(
			.invalidOperation(op: self.op, node: self.location))
		return .invalid
	}
}

extension Syntax.Function {
	fileprivate func resolveType(
		scope: Semantic.QualifiedIdentifier,
		context: Semantic.Context,
		currentSymbols: borrowing Semantic.SymbolTable,
		symbolsState: inout [Semantic.QualifiedIdentifier: NodeState],
		currentContext: inout Semantic.Context,
		errors: inout [Semantic.Error]
	) -> Semantic.Expression {
		let input = self.input?.resolveType(
			scope: scope,
			context: context,
			currentSymbols: currentSymbols,
			symbolsState: &symbolsState,
			currentContext: &currentContext,
			errors: &errors)

		let argumentsSymbols = self.arguments.generateSymbols(scope: scope)
		// TODO: figure out scoping of arguments

	
		// let output: Semantic.Expression
		//
		// return .function(
		// 	input: input ?? .nothing,
		// 	arguments: arguments,
		// 	output: output
		// )
		fatalError("not implemented")
	}
}

extension [Syntax.Expression] {
	public func generateSymbols(scope: Semantic.QualifiedIdentifier) -> (
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
		context: Semantic.Context
	) -> (
		context: Semantic.Context,
		errors: [Semantic.Error]
	) {
		let result = self.definitions.generateSymbols(scope: scope)
		let symbols = result.symbols
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
