import Foundation

enum SemanticError: LocalizedError {
    case type(TypeSemanticError)
    case function(FunctionSemanticError)
    case expression(ExpressionSemanticError)
}

extension Array<SemanticError>: Error {
    // var localizedDescription: String {
    //     return self.map { error in
    //         return error.localizedDescription
    //     }.joined(separator: "\n")
    // }
}

enum TypeSemanticError: LocalizedError {
    case redeclaration(
        locations: [NodeLocation])
    case shadowing(
        location: NodeLocation,
        module: String,
        typeDefinition: TypeDefinition)
    case typeNotInScope(
        location: NodeLocation,
        type: NominalType,
        typesInScope: [NominalType: TypeDefinition].Keys)
    case cyclicType(
        // type: TypeDefinition, // TODO: should save the cyclic path of types
        cyclicType: NominalType
    )
    case unsupportedYet(String)
}

enum FunctionSemanticError: LocalizedError {
    case redeclaration(
        locations: [NodeLocation])
    case typeNotInScope(
        location: NodeLocation,
        type: NominalType,
        typesInScope: [NominalType: TypeDefinition].Keys)
}

enum ExpressionSemanticError: LocalizedError {
    case inputMismatch(
        expression: Expression,
        expected: TypedExpressionType,
        received: TypedExpressionType)
    case invalidOperation(
        expression: Expression,
        leftType: TypedExpressionType,
        rightType: TypedExpressionType)
    case callingUncallable(
        expression: Expression,
        type: TypedExpressionType)
    case undefinedTypeInitializer(
        nominalType: NominalType)
    case undifienedFunction(
        call: Expression.Call,
        function: FunctionIdentifier)
    case undifinedFunctionOnInput(
        call: Expression.Call,
        input: TypedExpressionType,
        function: FunctionIdentifier)
    case argumentMismatch(
        call: Expression.Call,
        givenArguments: [ParamDefinition],
        inputType: TypedExpressionType,
        function: FunctionIdentifier)
    case typeInitializeArgumentMismatch(
        call: Expression.Call,
        givenArguments: [ParamDefinition],
        typeDefinition: TypeDefinition)
    case fieldNotInScope(
        expression: Expression)
    case captureGroupCountMismatch(
        branch: Expression.Branched.Branch,
        inputType: TypedExpressionType,
        captureGroupCount: Int)
    case loopedExpressionTypeMismatch(
        expression: Expression,
        expectedType: TypedExpressionType,
        receivedType: TypedExpressionType)
    case reachedNever(
        expression: Expression)
    case returnTypeMismatch(
        functionDefinition: FunctionDefinition,
        expectedReturnType: TypedExpressionType,
        receivedType: TypedExpressionType)
    case emptyFunctionBody(
        functionDefinition: FunctionDefinition
    )
    case unsupportedYet(String)
}
