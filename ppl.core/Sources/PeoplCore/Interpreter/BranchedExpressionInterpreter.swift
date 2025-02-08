
extension Expression.Branched: Evaluable {
    func evaluate(
        with input: Evaluation, and scope: EvaluationScope
    ) -> Result<Evaluation, SemanticError> {
        do {
            var modifiedScope = scope // needed to capture input set inside the branch capture groups

            let branch = try self.branches.first { branch in
                guard branch.captureGroup.count == input.count else {
                    throw SemanticError.captureGroupCountMismatch(
                        location: branch.location, 
                        inputCount: input.count,
                        captureCount: branch.captureGroup.count)
                }

                return try zip(input, branch.captureGroup).first { input, captureGroup in
                    switch captureGroup {
                    case .simple(let expression):
                        switch (input, expression.expressionType) {
                        case (_, .field(let value)):
                            modifiedScope.locals[value] = input
                            print("field \(value) set to \(input)")
                            return false
                        case (.int(let input), .intLiteral(let value)):
                            return input != value
                        case (_, .intLiteral):
                            throw SemanticError.typeMismatch(
                                location: expression.location,
                                left: input.typeName,
                                right: "Int")
                        case (.float(let input), .floatLiteral(let value)):
                            return input != value
                        case (_, .floatLiteral):
                            throw SemanticError.typeMismatch(
                                location: expression.location,
                                left: input.typeName,
                                right: "Float")
                        case (.string(let input), .stringLiteral(let value)):
                            return input != value
                        case (_, .stringLiteral):
                            throw SemanticError.typeMismatch(
                                location: expression.location,
                                left: input.typeName,
                                right: "String")
                        case (.bool(let input), .boolLiteral(let value)):
                            return input != value
                        case (_, .boolLiteral):
                            throw SemanticError.typeMismatch(
                                location: expression.location,
                                left: input.typeName,
                                right: "Bool")
                        case (_, .access), (_, .branched), 
                             (_, .piped), (_, .lambda), 
                             (_, .unnamedTuple), (_, .namedTuple):
                            throw SemanticError.invalidCaptureGroup(
                                location: expression.location)
                        default:
                            let fields = expression.getFields()
                            let scopeFields = Set(scope.locals.keys)
                            let capturedInputSet = fields.union(scopeFields).symmetricDifference(scopeFields)
                            if capturedInputSet.count > 1 {
                                throw SemanticError.tooManyFieldsInCaptureGroup(
                                    location: expression.location, fields: Array(capturedInputSet))
                            } else if capturedInputSet.count == 1, let capturedInput = capturedInputSet.first {
                                modifiedScope.locals[capturedInput] = input
                                switch expression.evaluate(with: .nothing, and: modifiedScope) {
                                case let .success(.bool(value)):
                                    print("expression \(expression) evaluated to \(value)")
                                    return !value
                                case .success:
                                    throw SemanticError.invalidCaptureGroup(location: expression.location)
                                case let .failure(error):
                                    throw error
                                }
                            } else {
                                switch expression.evaluate(with: .nothing, and: modifiedScope) {
                                case let .success(evaluation):
                                    return evaluation != input
                                case let .failure(error):
                                    throw error
                                }
                            }
                        }
                    case let .type(nominalType):
                        throw SemanticError.notImplemented(
                            location: nominalType.location, description: "type capture group not implemented yet")
                    }
                } == nil
            }

            switch branch?.body {
            case let .simple(expression):
                return expression.evaluate(with: .nothing, and: modifiedScope)
            case let .looped(expression):
                let result = expression.evaluate(with: .nothing, and: modifiedScope)
                switch result {
                case let .success(evaluation):
                    return self.evaluate(with: evaluation, and: scope)
                case let .failure(error):
                    return .failure(error)
                }
            case nil:
                return .failure(.reachedNever(location: self.location))
            }
        } catch {
            if let error = error as? SemanticError {
                return .failure(error)
            } else {
                return .failure(.sourceUnreadable)
            }
        }
    }
}
