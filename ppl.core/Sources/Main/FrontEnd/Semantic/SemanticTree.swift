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
				fatalError("not implemented")
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
	) -> Value? {
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
	) -> Value? {
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
	public func taggedExpression(
		position: UInt32
	) -> (
		tag: Semantic.QualifiedIdentifier,
		expression: Syntax.Expression,
		newPosition: UInt32
	) {
		switch self {
		case .taggedExpression(let tagged):
			switch tagged.expression {
			case .function(let function):
				fatalError(
					"I should figure out how to identify inputs for functions")
			default:
				return (
					tag: .init(chain: tagged.tag.chain),
					expression: tagged.expression,
					newPosition: position
				)
			}
		default:
			return (
				tag: .init(chain: ["$\(position)"]),
				expression: self,
				newPosition: position + 1
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
	) -> (
		expression: Semantic.Expression,
		errors: [Semantic.Error]
	) {
		switch self {
		// case .typeDefinition(let typeDefinition):
		// 	let result = typeDefinition.expressions.resolveSymbols(scope: scope)
		// 	return (.typeDefinition(result.symbols), result.errors)
		case .literal(let literal):
			return (literal.resolveType(), [])
		case .unary(let unary):
			return unary.resolveType(
				scope: scope,
				context: context,
				currentSymbols: currentSymbols,
				symbolsState: &symbolsState,
				currentContext: &currentContext)
		case .binary(let binary):
			return binary.resolveType(
				scope: scope,
				context: context,
				currentSymbols: currentSymbols,
				symbolsState: &symbolsState,
				currentContext: &currentContext)
		case .nominal(let identifier):
			return self.resolveIdentifier(
				identifier: identifier,
				scope: scope,
				context: context,
				currentSymbols: currentSymbols,
				symbolsState: &symbolsState,
				currentContext: &currentContext)
		// identifier.getSemanticIdentifier()
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
	) -> (
		expression: Semantic.Expression,
		errors: [Semantic.Error]
	) {
		let semanticIdentifier = Semantic.QualifiedIdentifier(
			chain: identifier.chain)

		let keys = context.keys

		// Looking in local resolved context first
		if let semanticExpression = currentContext.resolveSymbol(
			identifier: semanticIdentifier,
			in: scope)
		{
			return (semanticExpression, [])
		}
		// checking if symbol exists in current unevaluated symbols
		else if symbolsState.resolveSymbol(
			identifier: semanticIdentifier,
			in: scope) == .visiting
		{
			return (
				expression: .invalid,
				errors: [
					.cycle(identifier: semanticIdentifier, node: self.location)
				]
			)
		}
		// evaluating symbol from current unevaluated symbols
		else if let syntaxExpression = currentSymbols.resolveSymbol(
			identifier: semanticIdentifier,
			in: scope)
		{
			// Marking as visiting
			symbolsState[semanticIdentifier] = .visiting

			let (semanticExpression, errors) = syntaxExpression.resolveType(
				scope: scope,
				context: context,
				currentSymbols: currentSymbols,
				symbolsState: &symbolsState,
				currentContext: &currentContext)

			// Marking as visited
			symbolsState[semanticIdentifier] = .visited

			// Storing evaluated expression in current context
			currentContext[semanticIdentifier] = semanticExpression

			return (semanticExpression, errors)
		}
		// Looking in global context next
		else if let semanticExpression = context.resolveSymbol(
			identifier: semanticIdentifier,
			in: scope)
		{
			return (semanticExpression, [])

		} else {
			return (
				expression: .invalid,
				errors: [
					.undefinedIdentifier(
						identifier: semanticIdentifier,
						node: self.location)
				]
			)
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
	) -> (
		expression: Semantic.Expression,
		errors: [Semantic.Error]
	) {
		let (typedExpression, errors) = self.expression.resolveType(
			scope: scope,
			context: context,
			currentSymbols: currentSymbols,
			symbolsState: &symbolsState,
			currentContext: &currentContext)

		let symbol = "#\(self.op.rawValue)(\(typedExpression.type.description))"

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
	fileprivate func resolveType(
		scope: Semantic.QualifiedIdentifier,
		context: Semantic.Context,
		currentSymbols: borrowing Semantic.SymbolTable,
		symbolsState: inout [Semantic.QualifiedIdentifier: NodeState],
		currentContext: inout Semantic.Context,
	) -> (
		expression: Semantic.Expression,
		errors: [Semantic.Error]
	) {
		let (typedLHS, lhsErrors) = self.left.resolveType(
			scope: scope,
			context: context,
			currentSymbols: currentSymbols,
			symbolsState: &symbolsState,
			currentContext: &currentContext)

		let (typedRHS, rhsErrors) = self.right.resolveType(
			scope: scope,
			context: context,
			currentSymbols: currentSymbols,
			symbolsState: &symbolsState,
			currentContext: &currentContext)

		let symbol =
			"#\(self.op.rawValue)(\(typedLHS.type.description),\(typedRHS.type.description))"

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
					kind: typedLHS.kind & typedRHS.kind),
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
	public func resolveSymbols(scope: Semantic.QualifiedIdentifier) -> (
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
				let (tag, expression, newPosition) = expression.taggedExpression(
					position: acc.positional)
				acc.positional = newPosition

				let qualifiedId = scope + tag

				if let existingSymbol = acc.symbols[qualifiedId] {
					fatalError("Proper redeclation storing")
				}
				if let existingSymbol = acc.symbols[tag] {
					fatalError("Proper global shadowing storing")
				}
				acc.symbols[qualifiedId] = expression
			}
		return (result.symbols, result.errors)
	}
}

extension Syntax.Module {
	fileprivate enum NodeState {
		case unvisited
		case visiting
		case visited
	}

	public func resolveExpressions(
		scope: Semantic.QualifiedIdentifier,
		context: Semantic.Context
	) -> (
		context: Semantic.Context,
		errors: [Semantic.Error]
	) {
		let result = self.definitions.resolveSymbols(scope: scope)
		let symbols = result.symbols
		var symbolsState = symbols.mapValues { _ in
			Syntax.Module.NodeState.unvisited
		}
		var currentContext: Semantic.Context = [:]
		var errors: [Semantic.Error] = []

		func cyclicEvaluation(
			// TODO: store stack to report cycles
			identifier: Semantic.QualifiedIdentifier,
			expression: Syntax.Expression
		) {
			if currentContext[identifier] != nil {
				// already evaluated
				return
			}

			if symbolsState[identifier] == .visiting {
				// cycle detected
				errors.append(
					.cycle(identifier: identifier, node: expression.location)
				)
				// TODO: mark symbol as invalid type
				return
			}

			symbolsState[identifier] = .visiting

		}

		for (identifier, expression) in symbols {
			// TODO: start evaluating positional expressions,
			// TODO: if fields are needed, evaluate them,
			// TODO: visit nodes and check for cycles
		}

		fatalError("not implemented")
	}

	public func resolveTypeDefinitions(
		scope: Semantic.QualifiedIdentifier,
		context: Semantic.Context
	) -> (
		context: Semantic.Context,
		errors: [Semantic.Error]
	) {
		let result = self.definitions.resolveSymbols(scope: scope)

		let typeDefinitions:
			[Semantic.QualifiedIdentifier: Syntax.TypeDefinition] = result.symbols
				.reduce(into: [:]) { acc, symbol in
					switch symbol.value {
					case .typeDefinition(let typeDefinition):
						acc[symbol.key] = typeDefinition
					default:
						break
					}
				}

		// TODO: detect shadowing?
		// TODO: detect redeclaration?
		// TODO: detect undefined types

		let undefinedTypes = typeDefinitions.compactMap {
			identifier, typeDefinition in
			// some recursive shit
			// typeDefinition.expressions
		}

		// TODO: detect cyclical referencing

		fatalError("not implemented")
	}

	// private func checkCyclicalDependencies(
	// 	symbols: Semantic.TypeLookupMap
	// ) -> [Semantic.Error] {
	// 	var nodeStates: [Syntax.QualifiedIdentifier: NodeState] = [:]
	// 	var errors: [Semantic.Error] = []
	//
	// 	func checkCyclicalDependencies(
	// 		typeSpecifier: Syntax.TypeSpecifier,
	// 		stack: [Syntax.Definition]
	// 	) {
	// 		switch typeSpecifier {
	// 		case .nothing, .never:
	// 			break
	// 		case let .nominal(nominal):
	// 			// NOTE: intrinsics don't have definition
	// 			if let typeDefinition = localTypeLookup[
	// 				nominal.identifier.getSemanticIdentifier()
	// 			] {
	// 				checkCyclicalDependencies(
	// 					typeDefinition: typeDefinition,
	// 					stack: stack
	// 				)
	// 			}
	// 		case let .recordType(record):
	// 			for field in record.typeFields {
	// 				switch field {
	// 				case let .typeSpecifier(typeSpecifier):
	// 					checkCyclicalDependencies(
	// 						typeSpecifier: typeSpecifier,
	// 						stack: stack
	// 					)
	// 				case let .taggedTypeSpecifier(taggedTypeSpecifier):
	// 					if let typeSpecifier =
	// 						taggedTypeSpecifier.typeSpecifier
	// 					{
	// 						checkCyclicalDependencies(
	// 							typeSpecifier: typeSpecifier,
	// 							stack: stack
	// 						)
	// 					} else {
	// 						// NOTE: nil typeSpecifiers are not allowed in record types
	// 						errors.append(
	// 							.init(
	// 								location: field.location,
	// 								errorChoice: .taggedTypeSpecifierRequired
	// 							)
	// 						)
	// 					}
	// 				case let .homogeneousTypeProduct(homogeneousTypeProduct):
	// 					checkCyclicalDependencies(
	// 						typeSpecifier: homogeneousTypeProduct.typeSpecifier,
	// 						stack: stack
	// 					)
	// 				}
	// 			}
	// 		case let .choiceType(choice):
	// 			for field in choice.typeFields {
	// 				switch field {
	// 				case let .typeSpecifier(typeSpecifier):
	// 					checkCyclicalDependencies(
	// 						typeSpecifier: typeSpecifier,
	// 						stack: stack
	// 					)
	// 				case let .taggedTypeSpecifier(taggedTypeSpecifier):
	// 					if let typeSpecifier =
	// 						taggedTypeSpecifier.typeSpecifier
	// 					{
	// 						checkCyclicalDependencies(
	// 							typeSpecifier: typeSpecifier,
	// 							stack: stack
	// 						)
	// 					}
	// 				case .homogeneousTypeProduct:
	// 					errors.append(
	// 						.init(
	// 							location: field.location,
	// 							errorChoice: .homogeneousTypeProductInSum
	// 						)
	// 					)
	// 				}
	// 			}
	// 		case .function:
	// 			break
	// 		}
	// 	}
	//
	// 	func checkCyclicalDependencies(
	// 		typeDefinition: Syntax.Definition,
	// 		stack: [Syntax.Definition]
	// 	) {
	// 		let typeIdentifier = typeDefinition.identifier
	// 		if nodeStates[typeIdentifier] == .visited {
	// 			return
	// 		}
	// 		if nodeStates[typeIdentifier] == .visiting {
	// 			for element in stack {
	// 				errors.append(
	// 					.init(
	// 						location: typeIdentifier.location,
	// 						errorChoice: .cyclicType(
	// 							stack: stack
	// 						)
	// 					)
	// 				)
	// 			}
	// 			return
	// 		}
	// 		nodeStates[typeIdentifier] = .visiting
	//
	// 		if case let .typeSpecifier(typeSpecifier) =
	// 			typeDefinition.definition
	// 		{
	// 			checkCyclicalDependencies(
	// 				typeSpecifier: typeSpecifier,
	// 				stack: stack + [typeDefinition]
	// 			)
	// 			nodeStates[typeIdentifier] = .visited
	// 		}
	// 	}
	//
	// 	for (_, typeDefinition) in localTypeLookup {
	// 		checkCyclicalDependencies(
	// 			typeDefinition: typeDefinition,
	// 			stack: []
	// 		)
	// 	}
	//
	// 	return errors
	// }
}
