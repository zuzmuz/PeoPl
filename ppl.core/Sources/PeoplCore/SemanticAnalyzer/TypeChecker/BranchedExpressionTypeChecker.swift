extension Expression.Branched: ExpressionTypeChecker {
    func checkType(
        with input: TypeIdentifier,
        localScope: LocalScope,
        context: borrowing SemanticContext
    ) throws(ExpressionSemanticError) -> TypedExpression {

        let typedBranches: [Expression.Branched.Branch] = try self.branches.map {
            branch throws(ExpressionSemanticError) in
            
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
                    scopeFields[param.name] = param.type
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
                let typedBranchExpression = try expression.checkType(
                    with: .nothing,
                    localScope: localScope,
                    context: context)
                return .init(
                    captureGroup: branch.captureGroup,
                    body: .simple(typedBranchExpression),
                    location: branch.location,
                    typeIdentifier: typedBranchExpression.typeIdentifier)
            case let .looped(expression):
                let typedLoopedExpression = try expression.checkType(
                    with: .nothing(),
                    localScope: localScope,
                    context: context)
                if typedLoopedExpression.typeIdentifier != input {
                    throw .loopedExpressionTypeMismatch(
                        expression: expression,
                        expectedType: input,
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
        // FIX: verify exhaustiveness of branches
        
        let typedLastBranch: TypedExpression? = if let lastBranch {
            try lastBranch.checkType(
                with: .nothing,
                localScope: localScope,
                context: context)
        } else {
            nil
        }

        var distinctTypes: Set<TypedExpressionType> = Set(typedBranches.compactMap { branch in
            if branch.type == .never {
                return nil
            } else {
                return branch.typeIdentifier
            }
        })
        
        if let typedLastBranch {
            distinctTypes = distinctTypes.union([typedLastBranch.type])
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
