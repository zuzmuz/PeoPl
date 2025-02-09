
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

                // NOTE: this method should return nil if the branch's capture group passes
                // which means that if a capture group passes, we should return false from inside
                // the filter function, this is why we're evaluating for failure
                return try zip(input, branch.captureGroup).first { input, captureGroup in
                    switch captureGroup {
                    case .argument(let argument):
                        modifiedScope.locals[argument.name] = input
                        switch argument.value.evaluate(with: .nothing, and: modifiedScope) {
                        case let .success(.bool(evaluation)):
                            return !evaluation
                        case .success:
                            throw SemanticError.invalidCaptureGroup(location: location)
                        case let .failure(error):
                            throw error
                        }
                    case .paramDefinition(let paramDefinition):
                        modifiedScope.locals[paramDefinition.name] = input
                        // TODO: should check for enum cases if input type is an enum
                        return input.typeIdentifier != paramDefinition.type
                    case .simple(let expression):
                        switch (input, expression.expressionType) {
                        case (_, .field(let value)):
                            if let localValue = scope.locals[value] {
                                if case let .bool(evaluation) = localValue {
                                    return !evaluation
                                } else {
                                    throw SemanticError.invalidCaptureGroup(location: expression.location)
                                }
                            } else {
                                modifiedScope.locals[value] = input
                                return false
                            }
                        case (input, .nothing):
                            return input != .nothing
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
                            switch expression.evaluate(with: .nothing, and: scope) {
                            case let .success(.bool(evaluation)):
                                return !evaluation
                            case .success:
                                throw SemanticError.invalidCaptureGroup(location: expression.location)
                            case let .failure(error):
                                throw error
                            }
                        }
                    case let .type(nominalType):
                        return input.typeIdentifier != .nominal(nominalType)
                    }
                } == nil
            }
            
            if let body = branch?.body {
                switch body {
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
                }
            } else if let expression = self.lastBranch {
                return expression.evaluate(with: input, and: scope)
            } else {
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
