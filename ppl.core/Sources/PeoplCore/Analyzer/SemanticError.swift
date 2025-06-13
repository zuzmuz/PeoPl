import Foundation

// //
enum SemanticError: LocalizedError {

    case typeRedeclaration(types: [Syntax.TypeDefinition])
    case typeNotInScope(type: Syntax.ScopedIdentifier)
    case homogeneousTypeProductInSum(
        field: Syntax.TypeField)
    case cyclicType(
        type: Syntax.TypeDefinition,  // TODO: consider detecting cycle
        cyclicType: Syntax.ScopedIdentifier)
    case duplicateFieldName(
        field: Syntax.TypeField)
    case unsupportedYet(String)

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
}

struct SemanticErrorList: LocalizedError {
    let errors: [SemanticError]
}
