extension Expression: Evaluable {
    func getFields() -> Set<String> {
        switch self.expressionType {
        case let .field(field):
            return Set([field])
        case let .unary(_, unary):
            return unary.getFields()
        case let .binary(_, left: left, right: right):
            return left.getFields().union(right.getFields())
        // TODO: adding compoud
        default:
            return Set()
        }
    }

    func evaluate(
        with input: Evaluation, and scope: EvaluationScope
    ) -> Result<Evaluation, RuntimeError> {
        switch (input, self.expressionType) {
        // Never
        case (_, .never):
            return .failure(.reachedNever(location: self.location))
        //Nothing
        case (.nothing, .nothing):
            return .success(.nothing)

        // Literals
        case (.nothing, .intLiteral(let value)):
            return .success(.int(value))
        case (.nothing, .floatLiteral(let value)):
            return .success(.float(value))
        case (.nothing, .stringLiteral(let value)):
            return .success(.string(value))
        case (.nothing, .boolLiteral(let value)):
            return .success(.bool(value))
        case (input, .nothing),
             (input, .intLiteral),
             (input, .floatLiteral),
             (input, .stringLiteral),
             (input, .boolLiteral):
            return .failure(.invalidInputForExpression(
                location: location, expected: "Nothing", received: input.typeName))

        // Unary
        case let (input, .unary(op, expression)):
            let right = expression.evaluate(with: .nothing, and: scope)
            switch (input, op, right) {
            case (.nothing, .plus, .success(.int(let value))):
                return .success(.int(value))
            case (.nothing, .plus, .success(.float(let value))):
                return .success(.float(value))
            case (.nothing, .minus, .success(.int(let value))):
                return .success(.int(-value))
            case (.nothing, .minus, .success(.float(let value))):
                return .success(.float(-value))
            case (.int(let left), .plus, .success(.int(let right))):
                return .success(.int(left + right))
            case (.float(let left), .plus, .success(.float(let right))):
                return .success(.float(left + right))
            case (.int(let left), .minus, .success(.int(let right))):
                return .success(.int(left - right))
            case (.float(let left), .minus, .success(.float(let right))):
                return .success(.float(left - right))
            case (.int(let left), .times, .success(.int(let right))):
                return .success(.int(left * right))
            case (.float(let left), .times, .success(.float(let right))):
                return .success(.float(left * right))
            case (.int(let left), .by, .success(.int(let right))):
                return .success(.int(left / right))
            case (.float(let left), .by, .success(.float(let right))):
                return .success(.float(left / right))
            case (.int(let left), .modulo, .success(.int(let right))):
                return .success(.int(left % right))
            case (.int(let left), .equal, .success(.int(let right))):
                return .success(.bool(left == right))
            case (.float(let left), .equal, .success(.float(let right))):
                return .success(.bool(left == right))
            case (.string(let left), .equal, .success(.string(let right))):
                return .success(.bool(left == right))
            case (.bool(let left), .equal, .success(.bool(let right))):
                return .success(.bool(left == right))
            case (.int(let left), .different, .success(.int(let right))):
                return .success(.bool(left != right))
            case (.float(let left), .different, .success(.float(let right))):
                return .success(.bool(left != right))
            case (.string(let left), .different, .success(.string(let right))):
                return .success(.bool(left != right))
            case (.bool(let left), .different, .success(.bool(let right))):
                return .success(.bool(left != right))
            case (.int(let left), .lessThan, .success(.int(let right))):
                return .success(.bool(left < right))
            case (.float(let left), .lessThan, .success(.float(let right))):
                return .success(.bool(left < right))
            case (.int(let left), .lessThanOrEqual, .success(.int(let right))):
                return .success(.bool(left <= right))
            case (.float(let left), .lessThanOrEqual, .success(.float(let right))):
                return .success(.bool(left <= right))
            case (.int(let left), .greaterThan, .success(.int(let right))):
                return .success(.bool(left > right))
            case (.float(let left), .greaterThan, .success(.float(let right))):
                return .success(.bool(left > right))
            case (.int(let left), .greaterThanOrEqual, .success(.int(let right))):
                return .success(.bool(left >= right))
            case (.float(let left), .greaterThanOrEqual, .success(.float(let right))):
                return .success(.bool(left >= right))
            case (.nothing, .not, .success(.bool(let right))):
                return .success(.bool(!right))
            case (.bool(let left), .and, .success(.bool(let right))):
                return .success(.bool(left && right))
            case (.bool(let left), .or, .success(.bool(let right))):
                return .success(.bool(left || right))
            case (_, _, .failure(let error)):
                return .failure(error)
            case (_, let op, .success(let right)):
                return .failure(
                    .invalidOperation(
                        location: self.location,
                        operation: op.rawValue,
                        left: input.typeName,
                        right: right.typeName))
            }

        // Binary
        case let (.nothing, .binary(op, left, right)):
            let left = left.evaluate(with: .nothing, and: scope)
            let right = right.evaluate(with: .nothing, and: scope)

            switch (left, op, right) {
            case let (.success(.int(left)), .plus, .success(.int(right))):
                return .success(.int(left + right))
            case let (.success(.float(left)), .plus, .success(.float(right))):
                return .success(.float(left + right))
            case let (.success(.int(left)), .minus, .success(.int(right))):
                return .success(.int(left - right))
            case let (.success(.float(left)), .minus, .success(.float(right))):
                return .success(.float(left - right))
            case let (.success(.int(left)), .times, .success(.int(right))):
                return .success(.int(left * right))
            case let (.success(.float(left)), .times, .success(.float(right))):
                return .success(.float(left * right))
            case let (.success(.int(left)), .by, .success(.int(right))):
                return .success(.int(left / right))
            case let (.success(.float(left)), .by, .success(.float(right))):
                return .success(.float(left / right))
            case let (.success(.int(left)), .modulo, .success(.int(right))):
                return .success(.int(left % right))
            case let (.success(.int(left)), .equal, .success(.int(right))):
                return .success(.bool(left == right))
            case let (.success(.float(left)), .equal, .success(.float(right))):
                return .success(.bool(left == right))
            case let (.success(.string(left)), .equal, .success(.string(right))):
                return .success(.bool(left == right))
            case let (.success(.bool(left)), .equal, .success(.bool(right))):
                return .success(.bool(left == right))
            case let (.success(.int(left)), .different, .success(.int(right))):
                return .success(.bool(left != right))
            case let (.success(.float(left)), .different, .success(.float(right))):
                return .success(.bool(left != right))
            case let (.success(.string(left)), .different, .success(.string(right))):
                return .success(.bool(left != right))
            case let (.success(.bool(left)), .different, .success(.bool(right))):
                return .success(.bool(left != right))
            case let (.success(.int(left)), .lessThan, .success(.int(right))):
                return .success(.bool(left < right))
            case let (.success(.float(left)), .lessThan, .success(.float(right))):
                return .success(.bool(left < right))
            case let (.success(.int(left)), .lessThanOrEqual, .success(.int(right))):
                return .success(.bool(left <= right))
            case let (.success(.float(left)), .lessThanOrEqual, .success(.float(right))):
                return .success(.bool(left <= right))
            case let (.success(.int(left)), .greaterThan, .success(.int(right))):
                return .success(.bool(left > right))
            case let (.success(.float(left)), .greaterThan, .success(.float(right))):
                return .success(.bool(left > right))
            case let (.success(.int(left)), .greaterThanOrEqual, .success(.int(right))):
                return .success(.bool(left >= right))
            case let (.success(.float(left)), .greaterThanOrEqual, .success(.float(right))):
                return .success(.bool(left >= right))
            case let (.success(.bool(left)), .and, .success(.bool(right))):
                return .success(.bool(left && right))
            case let (.success(.bool(left)), .or, .success(.bool(right))):
                return .success(.bool(left || right))
            case let (.failure(error), _, _):
                return .failure(error)
            case let (_, _, .failure(error)):
                return .failure(error)
            case let (.success(left), op, .success(right)):
                return .failure(
                    .invalidOperation(
                        location: self.location,
                        operation: op.rawValue,
                        left: left.typeName, right: right.typeName))
            }

        case (input, .branched(let branched)):
            return branched.evaluate(with: input, and: scope)
        case (input, .piped(let leftExpression, let rightExpression)):
            let left = leftExpression.evaluate(with: input, and: scope)
            switch left {
            case .success(let evaluation):
                return rightExpression.evaluate(with: evaluation, and: scope)
            case .failure(let error):
                return .failure(error)
            }
        case (.nothing, .field(let fieldName)):
            if let fieldValue = scope.locals[fieldName] {
                return .success(fieldValue)
            } else {
                return .failure(.fieldNotInScope(location: location, fieldName: fieldName))
            }
        case (input, .call(let call)):
            return call.evaluate(with: input, and: scope)
        case (.nothing, .unnamedTuple(let expressions)):
            let results = expressions.map { $0.evaluate(with: input, and: scope) }
            if case let .failure(error) = (results.first { (try? $0.get()) == nil }) {
                return .failure(error)
            }
            return .success(.unnamedTuple(results.compactMap { try? $0.get() }))
        case (input, .unnamedTuple):
            return .failure(.invalidInputForExpression(
                location: location, expected: "Nothing", received: input.typeName))
        case (.nothing, .namedTuple(let expressions)):
            let results = expressions.map { ($0.name, $0.value.evaluate(with: input, and: scope)) }
            if case let .failure(error) = (results.first { (try? $0.1.get()) == nil })?.1 {
                return .failure(error)
            }
            return .success(.namedTuple(results.compactMap { result in
                if let evaluation = try? result.1.get() {
                    return Evaluation.NamedEvaluation(name: result.0, value: evaluation)
                }
                return nil
            }))
        case (input, .namedTuple):
            return .failure(.invalidInputForExpression(
                location: location, expected: "Nothing", received: input.typeName))
        default:
            return .failure(.notImplemented(location: self.location, description: "wip"))
        }
    }
}
