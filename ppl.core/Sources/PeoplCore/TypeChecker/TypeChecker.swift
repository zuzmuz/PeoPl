struct LocalScope {
    let fields: [String: TypeIdentifier]
}

struct TypeCheckerContext {
    let functionsIdentifiers: [FunctionIdentifier: FunctionDefinition]
    let functionsInputTypeIdentifiers: [FunctionIdentifier: FunctionDefinition]
}

protocol TypeChecker {
    func checkType(
        with input: TypeIdentifier,
        localScope: LocalScope,
        context: TypeCheckerContext
    ) throws(ExpressionSemanticError) -> TypeIdentifier
}
