
extension Expression.Branched: TypeChecker {
    func checkType(
        with input: TypeIdentifier,
        localScope: LocalScope,
        context: TypeCheckerContext
    ) throws(ExpressionSemanticError) -> TypeIdentifier {
        throw .unsupportedYet("branched expression")
    }
}
