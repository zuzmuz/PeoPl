import Foundation

extension Semantic {
	public enum Error: LocalizedError {
		case redeclaration(
			identifier: Semantic.QualifiedIdentifier,
			node: Syntax.NodeLocation,
		)
		case shadowing(
			identifier: Semantic.QualifiedIdentifier,
			node: Syntax.NodeLocation
		)
		case invalidOperation(
			op: Operator,
			node: Syntax.NodeLocation
		)
		case undefinedIdentifier(
			identifier: Semantic.QualifiedIdentifier,
			node: Syntax.NodeLocation
		)
		case cycle(
			identifier: Semantic.QualifiedIdentifier,
			node: Syntax.NodeLocation
		)
	}
}
