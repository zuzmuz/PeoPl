import Foundation

extension Semantic {
    public enum Error: LocalizedError {
        case redeclaration(
            identifier: Semantic.QualifiedIdentifier,
            nodes: [Syntax.Expression],
        )
    }
}
