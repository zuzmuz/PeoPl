struct LocalScope {
}

struct TypeCheckerContext {
}

protocol TypeChecker {
    func checkType(
        with input: TypeIdentifier,
        localScope: LocalScope,
        context: TypeCheckerContext) -> TypeIdentifier
}

