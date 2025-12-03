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

	public struct Expression {
		let syntax: Syntax.Expression
	}

	/// Symbol lookup table mapping qualified identifiers to syntax expression
	public typealias SymbolTable = [QualifiedIdentifier: Syntax.Expression]
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
			return (.init(chain: ["_\(position)"]), newPosition: position + 1)
		}
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
