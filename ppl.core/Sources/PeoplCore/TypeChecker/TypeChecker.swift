struct LocalScope {
    let fields: [String: TypeIdentifier]
}

struct TypeCheckerContext {
    let functions: [FunctionDefinition: FunctionDefinition]
    let functionsIdentifiers: [FunctionIdentifier: [FunctionDefinition]]
    let functionsInputTypeIdentifiers: [TypeIdentifier: [FunctionDefinition]]
}

protocol TypeChecker {
    func checkType(
        with input: TypeIdentifier,
        localScope: LocalScope,
        context: TypeCheckerContext
    ) throws(ExpressionSemanticError) -> TypeIdentifier
}
