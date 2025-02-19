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
        type: NominalType,
        typesInScope: [NominalType: TypeDefinition].Keys)
}

enum TypeSemanticError: SemanticError {
    case redeclaration(
        locations: [NodeLocation])
    case cyclicType(
        // type: TypeDefinition, // TODO: should save the cyclic path of types
        cyclicType: NominalType
    )
    case unsupportedYet(String)
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
    case callingUncallable(
        expression: Expression,
        type: TypeIdentifier)
    case undifienedFunction(
        call: Expression.Call,
        function: FunctionIdentifier)
    case undifinedFunctionOnInput(
        call: Expression.Call,
        input: TypeIdentifier,
        function: FunctionIdentifier)
    case argumentMismatch(
        call: Expression.Call,
        givenArguments: [ParamDefinition],
        inputType: TypeIdentifier,
        function: FunctionIdentifier)
    case fieldNotInScope(
        expression: Expression)
    case captureGroupCountMismatch(
        branch: Expression.Branched.Branch,
        inputType: TypeIdentifier,
        captureGroupCount: Int)
    case loopedExpressionTypeMismatch(
        expression: Expression,
        expectedType: TypeIdentifier,
        receivedType: TypeIdentifier)
    case reachedNever(
        expression: Expression)
    case unsupportedYet(String)
}
