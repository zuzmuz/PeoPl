struct LocalScope {
    let fields: [String: TypeIdentifier]
}

struct TypeCheckerContext: ~Copyable {
    let functions: [FunctionDefinition: FunctionDefinition]
    let functionsIdentifiers: [FunctionIdentifier: [FunctionDefinition]]
    let functionsInputTypeIdentifiers: [TypeIdentifier: [FunctionDefinition]]
}

protocol TypeChecker {
    func checkType(
        with input: Expression,
        localScope: LocalScope,
        context: borrowing TypeCheckerContext
    ) throws(ExpressionSemanticError) -> Self
}
