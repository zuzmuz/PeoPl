import Foundation
//
enum SemanticError: LocalizedError {
    case type(TypeSemanticError)
    case function(FunctionSemanticError)
    // case expression(ExpressionSemanticError)
}
//
// extension Array<SemanticError>: Error {
//     // var localizedDescription: String {
//     //     return self.map { error in
//     //         return error.localizedDescription
//     //     }.joined(separator: "\n")
//     // }
// }
//
enum TypeSemanticError: LocalizedError {
    case redeclaration(locations: [Syntax.TypeDefinition])
    case shadowing(
        type: Syntax.TypeDefinition,
        module: String)
    case typeNotInScope(
        type: Syntax.NominalType)
    case cyclicType(
        // type: Syntax.TypeDefinition, // TODO: consider detecting cycle
        cyclicType: Syntax.NominalType)
    case unsupportedYet(String)
}

enum FunctionSemanticError: LocalizedError {
    case redeclaration(locations: [Syntax.FunctionDefinition])
    case typeNotInScope(
        type: Syntax.NominalType,
        typesInScope: [Syntax.NominalType: Syntax.TypeDefinition].Keys)
}
//
// enum ExpressionSemanticError: LocalizedError {
//     case inputMismatch(
//         expression: Expression,
//         expected: TypeIdentifier,
//         received: TypeIdentifier)
//     case invalidOperation(
//         expression: Expression,
//         leftType: TypeIdentifier,
//         rightType: TypeIdentifier)
//     case callingUncallable(
//         expression: Expression,
//         type: TypeIdentifier)
//     case undefinedTypeInitializer(
//         nominalType: NominalType)
//     case undefinedFunction(
//         call: Expression.Call,
//         function: FunctionIdentifier)
//     case undefinedFunctionOnInput(
//         call: Expression.Call,
//         input: TypeIdentifier,
//         function: FunctionIdentifier)
//     case argumentMismatch(
//         call: Expression.Call,
//         givenArguments: [ParamDefinition],
//         inputType: TypeIdentifier,
//         function: FunctionIdentifier)
//     case typeInitializeArgumentMismatch(
//         call: Expression.Call,
//         givenArguments: [ParamDefinition],
//         typeDefinition: TypeDefinition)
//     case fieldNotInScope(
//         expression: Expression)
//     case captureGroupCountMismatch(
//         branch: Expression.Branched.Branch,
//         inputType: TypeIdentifier,
//         captureGroupCount: Int)
//     case loopedExpressionTypeMismatch(
//         expression: Expression,
//         expectedType: TypeIdentifier,
//         receivedType: TypeIdentifier)
//     case reachedNever(
//         expression: Expression)
//     case returnTypeMismatch(
//         functionDefinition: FunctionDefinition,
//         expectedReturnType: TypeIdentifier,
//         receivedType: TypeIdentifier)
//     case emptyFunctionBody(
//         functionDefinition: FunctionDefinition
//     )
//     case unsupportedYet(String)
// }
