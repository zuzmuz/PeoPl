import Foundation
// //
enum SemanticError: LocalizedError {
    case type(TypeSemanticError)
    case value(ValueSemanticError)
    case expression(ExpressionSemanticError)
}

struct SemanticErrorList: LocalizedError {
    let errors: [SemanticError]
}

enum TypeSemanticError: LocalizedError {
    case redeclaration(types: [Syntax.TypeDefinition])
    // case shadowing(
    //     type: Syntax.TypeDefinition,
    //     module: String)
    case typeNotInScope(type: Syntax.ScopedIdentifier)
    case homogeneousTypeProductInSum(
        type: Syntax.TypeSpecifier,
        field: Syntax.TypeField)
    case cyclicType(
        type: Syntax.TypeDefinition, // TODO: consider detecting cycle
        cyclicType: Syntax.ScopedIdentifier)
    case unsupportedYet(String)
}
//
enum ValueSemanticError: LocalizedError {
    case redeclaration(values: [Syntax.ValueDefinition])
//     case shadowing(
//         function: Syntax.FunctionDefinition,
//         module: String)
    case typeNotInScope(type: Syntax.ScopedIdentifier)
}
// //

enum ExpressionSemanticError: LocalizedError {
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
    // case callingUncallable(
    //     expression: Expression,
    //     type: TypeIdentifier)

    // case undefinedTypeInitializer(
    //     nominalType: NominalType)
    // case undefinedFunction(
    //     call: Expression.Call,
    //     function: FunctionIdentifier)
    // case undefinedFunctionOnInput(
    //     call: Expression.Call,
    //     input: TypeIdentifier,
    //     function: FunctionIdentifier)
    // case argumentMismatch(
    //     call: Expression.Call,
    //     givenArguments: [ParamDefinition],
    //     inputType: TypeIdentifier,
    //     function: FunctionIdentifier)
    // case typeInitializeArgumentMismatch(
    //     call: Expression.Call,
    //     givenArguments: [ParamDefinition],
    //     typeDefinition: TypeDefinition)
    // case fieldNotInScope(
    //     expression: Expression)
    // case captureGroupCountMismatch(
    //     branch: Expression.Branched.Branch,
    //     inputType: TypeIdentifier,
    //     captureGroupCount: Int)
    // case loopedExpressionTypeMismatch(
    //     expression: Expression,
    //     expectedType: TypeIdentifier,
    //     receivedType: TypeIdentifier)
    // case reachedNever(
    //     expression: Expression)
    // case returnTypeMismatch(
    //     functionDefinition: FunctionDefinition,
    //     expectedReturnType: TypeIdentifier,
    //     receivedType: TypeIdentifier)
    // case emptyFunctionBody(
    //     functionDefinition: FunctionDefinition
    // )
    case unsupportedYet(String)
}
