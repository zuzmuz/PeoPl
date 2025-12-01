// MARK: Language Semantic Tree

// ============================
// This file defines the semantic tree structure of valid type checked
// Peopl code.

public enum Semantic {

	// MARK: - Core Types

	public typealias ElementId = UInt32

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

	/// Symbol lookup table mapping qualified identifiers to element IDs
	public typealias SymbolTable = [QualifiedIdentifier: ElementId]
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

extension Syntax.Module {
	/// First pass: collect all tagged top-level definitions
	/// Returns elements list and symbol table
	public func resolve(
		element: Semantic.Element
	) -> (
		elements: [Semantic.Element],
		symbolTable: Semantic.SymbolTable,
		errors: [String]
	) {
		var elements: [Semantic.Element] = []
		var symbolTable: Semantic.SymbolTable = [:]
		var redeclarations: [Semantic.QualifiedIdentifier: [Syntax.Expression]] =
			[:]

		var index = UInt32(0)  // index for unnamed expressions
		var tag: Semantic.QualifiedIdentifier

		for definition in self.definitions {

			let (tag, index) = definition.semanticTag(position: index)

			let qualifiedId = element.qualifiedId + tag

			// Check for redeclaration
			if let existingId = symbolTable[qualifiedId] {
				redeclarations[qualifiedId] =
					redeclarations[qualifiedId] ?? [] + [definition]
			}

			// Create element
			// let elementId = Semantic.ElementId(elements.count)
			// let element = Semantic.Element(
			// 	parentId: moduleElementId,
			// 	qualifiedId: qualifiedId,
			// 	location: location,
			// 	expression: definition
			// )
			//
			// elements.append(element)
			// symbolTable[qualifiedId] = elementId
		}

        fatalError("Unfinished function")

		// return (elements, symbolTable, errors)
	}
}

// MARK: - Tag Extraction Helpers

extension Syntax.Expression {
	/// Extract tag and location from a tagged expression
	/// Returns the qualified identifier chain and location
	func extractTag() -> (
		tag: Syntax.QualifiedIdentifier,
		location: Syntax.NodeLocation
	)? {
		switch self {
		case .taggedExpression(let tagged):
			return (tagged.tag, tagged.location)
		default:
			return nil
		}
	}
}
