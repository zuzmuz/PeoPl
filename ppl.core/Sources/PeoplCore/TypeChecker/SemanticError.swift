import Foundation

protocol SemanticError: LocalizedError {}

enum FunctionSemanticError: SemanticError, Encodable {
    case nameNotFound(
        location: NodeLocation,
        name: String,
        extra: String)
    case inputMismatch(
        location: NodeLocation,
        inputType: TypeIdentifier,
        validInputs: [TypeIdentifier])
    case argumentMismatch(
        location: NodeLocation,
        givenArguments: [Expression.Argument],
        expectedArguments: [[Expression.Argument]])
    case returnTypeMismatch(
        location: NodeLocation,
        expectedReturnType: TypeIdentifier,
        receivedType: TypeIdentifier)
    case redeclaration(
        locations: [NodeLocation]
    )
}

enum OperationSemanticError: SemanticError, Encodable {
    case typeMismatch(
        location: NodeLocation,
        leftType: TypeIdentifier,
        rightType: TypeIdentifier)
    case inputMismatch(
        location: NodeLocation,
        expected: TypeIdentifier,
        received: TypeIdentifier)
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

enum ScopeSemanticError: SemanticError, Encodable {
    case fieldNotInScope(
        location: NodeLocation,
        field: String,
        fieldsInScope: [String])
}
