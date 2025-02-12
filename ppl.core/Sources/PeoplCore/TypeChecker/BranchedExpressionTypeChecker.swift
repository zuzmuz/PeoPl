extension Expression.Branched: TypeChecker {
    func checkType(
        with input: TypeIdentifier,
        localScope: LocalScope,
        context: TypeCheckerContext
    ) throws(ExpressionSemanticError) -> TypeIdentifier {
        let unionType = try self.branches.map { branch throws(ExpressionSemanticError) in
            
            // checking if capture group count matches input
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
            case (.unnamedTuple(let unnamedTuple), let count)
            where count != unnamedTuple.types.count && count != 1:
                throw .captureGroupCountMismatch(
                    branch: branch,
                    inputType: input,
                    captureGroupCount: branch.captureGroup.count
                )
            case (.namedTuple(let namedTuple), let count)
            where count != namedTuple.types.count && count != 1:
                throw .captureGroupCountMismatch(
                    branch: branch,
                    inputType: input,
                    captureGroupCount: branch.captureGroup.count
                )
            default:
                break
            }

            // TODO: add captured fields to local scope for branch body

            var scopeFields = localScope.fields
            
            if branch.captureGroup.count == 1,
                let captureGroup = branch.captureGroup.first
            {
                switch captureGroup {
                case let .simple(expression):
                    if case let .field(field) = expression.expressionType {
                        scopeFields[field] = input
                    }
                case let .paramDefinition(param):
                    scopeFields[param.name] = param.type // WARN: not sure about this
                case let .argument(argument):
                    scopeFields[argument.name] = input
                default:
                    break
                }
            } else {
                zip(branch.captureGroup, input).forEach { captureGroup, input in
                    switch captureGroup {
                    case let .simple(expression):
                        if case let .field(field) = expression.expressionType {
                            scopeFields[field] = input
                        }
                    case let .paramDefinition(param):
                        scopeFields[param.name] = param.type
                    case let .argument(argument):
                        scopeFields[argument.name] = input
                    default:
                        break
                    }
                }
            }

            let localScope = LocalScope(fields: scopeFields)

            switch branch.body {
            case let .simple(expression):
                return try expression.checkType(
                    with: .nothing(),
                    localScope: localScope,
                    context: context)
            case let .looped(expression):
                let loopedExpressionType = try expression.checkType(
                    with: .nothing(),
                    localScope: localScope,
                    context: context)
                if loopedExpressionType != input {
                    throw .loopedExpressionTypeMismatch(
                        expression: expression,
                        expectedType: input,
                        receivedType: loopedExpressionType
                    )
                }
                return .never()
            }
        }
        // TODO: verify exhaustiveness of


        let distinctTypes = Set(unionType.filter { $0 != .never() })
        if distinctTypes.count > 1 {
            return .union(.init(types: Array(distinctTypes), location: .nowhere))
        } else if let type = distinctTypes.first {
            return type
        } else {  // distinctTypes.count == 0
            return .never()
        }
    }
}
