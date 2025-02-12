
extension Expression.Branched: TypeChecker {
    func checkType(
        with input: TypeIdentifier,
        localScope: LocalScope,
        context: TypeCheckerContext
    ) throws(ExpressionSemanticError) -> TypeIdentifier {
        let unionType = try self.branches.map { branch throws(ExpressionSemanticError) in
            switch (input, branch.captureGroup.count) {
            case (.nothing, let count) where count > 1,
                (.nominal, let count) where count != 1,
                (.lambda, let count) where count != 1:
                throw .captureGroupCountMismatch(
                    branch: branch,
                    inputType: input,
                    captureGroupCount: branch.captureGroup.count
                )
            // for some reason swift doesn't support having all these expression together, and fallthrough isn't working
            case (.unnamedTuple(let unnamedTuple), let count) where count != unnamedTuple.types.count && count != 1:
                throw .captureGroupCountMismatch(
                    branch: branch,
                    inputType: input,
                    captureGroupCount: branch.captureGroup.count
                )
            case (.namedTuple(let namedTuple), let count) where count != namedTuple.types.count && count != 1:
                throw .captureGroupCountMismatch(
                    branch: branch,
                    inputType: input,
                    captureGroupCount: branch.captureGroup.count
                )
            default:
                break
            }
            
            switch branch.body {
            case let .simple(expression):
                return try expression.checkType(
                    with: .nothing(location: .nowhere),
                    localScope: localScope,
                    context: context)
            case let .looped(expression):
                let loopedExpressionType = try expression.checkType(
                    with: .nothing(location: .nowhere),
                    localScope: localScope,
                    context: context)
                if loopedExpressionType != input {
                    throw .loopedExpressionTypeMismatch(
                        expression: expression,
                        expectedType: input,
                        receivedType: loopedExpressionType
                    )
                }
                return .never(location: .nowhere)
            }
        }
        
        // let distinctTypes = Set(unionType)
        // if distinctTypes.count > 1 {
        //     return .nominal(.init(chain: [.init(typeName: "Union)
        //         distinctTypes.filter { $0 != .never(location: .nowhere }
        // }

        throw .unsupportedYet("branched expression")
    }
}
