import Foundation

protocol SemanticError: LocalizedError {}

enum FunctionSemanticError: SemanticError {
    case returnTypeMismatch(
        location: NodeLocation,
        expectedReturnType: TypeIdentifier,
        receivedType: TypeIdentifier)
    case redeclaration(
        locations: [NodeLocation])
    case typeNotInScope(
        location: NodeLocation,
        type: TypeIdentifier,
        typesInScope: [TypeIdentifier: TypeIdentifier].Keys)
}


enum ExpressionSemanticError: SemanticError, Encodable {
    case inputMismatch(
        expression: Expression,
        expected: TypeIdentifier,
        received: TypeIdentifier)
    case invalidOperation(
        expression: Expression,
        leftType: TypeIdentifier,
        rightType: TypeIdentifier)
    case undifinedFunctionOnInput(
        expression: Expression,
        input: TypeIdentifier,
        function: FunctionIdentifier)
    case argumentMismatch(
        expression: Expression,
        givenArguments: [Expression.Argument],
        inputType: TypeIdentifier,
        FunctionIdentifier: FunctionIdentifier)
    case reachedNever(
        expression: Expression)
    case unsupportedYet(
        expression: Expression)
}

enum CaptureGroupSemanticError: SemanticError, Encodable {
    case groupCountMismatch(
        location: NodeLocation,
        inputType: TypeIdentifier,
        inputCount: Int,
        captureGroupCount: Int)
    case invalidType(
        location: NodeLocation,
        type: TypeIdentifier)
}

enum BranchingSemanticError: SemanticError, Encodable {
    case branchingNotExhaustive(location: NodeLocation)
}
