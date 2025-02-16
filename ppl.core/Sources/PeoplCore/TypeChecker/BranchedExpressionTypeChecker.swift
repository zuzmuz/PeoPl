extension Expression.Branched: TypeChecker {
    func checkType(
        with input: Expression,
        localScope: LocalScope,
        context: borrowing TypeCheckerContext
    ) throws(ExpressionSemanticError) -> Expression.Branched {

        let typedBranches: [Expression.Branched.Branch] = try self.branches.map {
            branch throws(ExpressionSemanticError) in
            
            // checking if capture group count matches input
            switch (input.typeIdentifier, branch.captureGroup.count) {
            case (.nothing, let count) where count > 1,
                (.nominal, let count) where count != 1,
                (.lambda, let count) where count != 1:
                throw .captureGroupCountMismatch(
                    branch: branch,
                    inputType: input.typeIdentifier,
                    captureGroupCount: branch.captureGroup.count
                )
            // for some reason swift doesn't support having all these expression together, and fallthrough isn't working
            case (.unnamedTuple(let unnamedTuple), let count)
            where count != unnamedTuple.types.count && count != 1:
                throw .captureGroupCountMismatch(
                    branch: branch,
                    inputType: input.typeIdentifier,
                    captureGroupCount: branch.captureGroup.count
                )
            case (.namedTuple(let namedTuple), let count)
            where count != namedTuple.types.count && count != 1:
                throw .captureGroupCountMismatch(
                    branch: branch,
                    inputType: input.typeIdentifier,
                    captureGroupCount: branch.captureGroup.count
                )
            default:
                break
            }

            var scopeFields = localScope.fields
            
            if branch.captureGroup.count == 1,
                let captureGroup = branch.captureGroup.first
            {
                switch captureGroup {
                case let .simple(expression):
                    if case let .field(field) = expression.expressionType {
                        scopeFields[field] = input.typeIdentifier
                    }
                case let .paramDefinition(param):
                    scopeFields[param.name] = param.type // WARN: not sure about this
                case let .argument(argument):
                    scopeFields[argument.name] = input.typeIdentifier
                default:
                    break
                }
            } else {
                zip(branch.captureGroup, input.typeIdentifier).forEach { captureGroup, input in
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
                let typedBranchExpression = try expression.checkType(
                    with: .empty,
                    localScope: localScope,
                    context: context)
                return .init(
                    captureGroup: branch.captureGroup,
                    body: .simple(typedBranchExpression),
                    location: branch.location,
                    typeIdentifier: typedBranchExpression.typeIdentifier)
            case let .looped(expression):
                let typedLoopedExpression = try expression.checkType(
                    with: .empty,
                    localScope: localScope,
                    context: context)
                if typedLoopedExpression.typeIdentifier != input.typeIdentifier {
                    throw .loopedExpressionTypeMismatch(
                        expression: expression,
                        expectedType: input.typeIdentifier,
                        receivedType: typedLoopedExpression.typeIdentifier
                    )
                }
                return .init(
                    captureGroup: branch.captureGroup,
                    body: .looped(typedLoopedExpression),
                    location: branch.location,
                    typeIdentifier: .never())
            }
        }
        // TODO: verify exhaustiveness of
        
        let typedLastBranch: Expression? = if let lastBranch {
            try lastBranch.checkType(
                with: .empty,
                localScope: localScope,
                context: context)
        } else {
            nil
        }

        var distinctTypes: Set<TypeIdentifier> = Set(typedBranches.compactMap { branch in
            if branch.typeIdentifier == .never() {
                return nil
            } else {
                return branch.typeIdentifier
            }
        })
        
        if let typedLastBranch {
            distinctTypes = distinctTypes.union([typedLastBranch.typeIdentifier])
        }
        if distinctTypes.count > 1 {
            return .init(
                branches: typedBranches,
                lastBranch: typedLastBranch,
                location: location,
                typeIdentifier: .union(
                    .init(
                        types: Array(distinctTypes),
                        location: .nowhere)))
        } else if let type = distinctTypes.first {
            return .init(
                branches: typedBranches,
                lastBranch: typedLastBranch,
                location: location,
                typeIdentifier: type)
        } else {
            return .init(
                branches: typedBranches,
                lastBranch: typedLastBranch,
                location: location,
                typeIdentifier: .never())
        }
    }
}
