import Foundation

extension Semantic {
    public enum Error: LocalizedError {
        case notImplemented(String)
        case typeRedeclaration(types: [Syntax.TypeDefinition])
        case typeNotInScope(type: Syntax.ScopedIdentifier)
        case homogeneousTypeProductInSum(
            field: Syntax.TypeField)
        case cyclicType(
            type: Syntax.TypeDefinition,  // TODO: consider detecting cycle
            cyclicType: Syntax.ScopedIdentifier)
        case duplicateFieldName(
            field: Syntax.TypeField)
        case valueRedeclaration(values: [Syntax.ValueDefinition])
        case inputMismatch(
            expression: Syntax.Expression,
            expected: Semantic.TypeSpecifier,
            received: Semantic.TypeSpecifier)
        case invalidOperation(
            expression: Syntax.Expression,
            leftType: Semantic.TypeSpecifier,
            rightType: Semantic.TypeSpecifier)
        case undefinedField(
            expression: Syntax.Expression,
            field: String)
        case undefinedType(
            expression: Syntax.Expression,
            identifier: Semantic.ScopedIdentifier)
        case undefinedCall(
            expression: Syntax.Expression)
        case duplicatedExpressionFieldName(
            expression: Syntax.Expression)
        case consecutiveUnary(
            expression: Syntax.Expression)
        case bindingNotAllowed(
            expression: Syntax.Expression)
        case bindingMismatch(
            expression: Syntax.Expression)
        case guardShouldReturnBool(
            expression: Syntax.Expression)
    }

    public struct ErrorList: LocalizedError {
        public let errors: [Error]
    }
}
