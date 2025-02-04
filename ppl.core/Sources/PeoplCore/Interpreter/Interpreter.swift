fileprivate extension String {
    func peoplFormat(_ arguments: [Evaluation]) -> String {
        var result = self
        for argument in arguments {
            result = result.replacingOccurrences(of: "{}", with: argument.describe(formating: ""))
        }
        return result
    }
}


enum Evaluation: Encodable, Equatable, Sequence {

    struct Iterator: IteratorProtocol {
        private var content: [Evaluation]
        private var index: Int = 0

        init(_ evaluation: Evaluation) {
            switch evaluation {
            case .nothing, .int, .float, .string, .bool:
                content = [evaluation]
            case let .tuple(evaluations):
                content = evaluations 
            }
        }

        mutating func next() -> Evaluation? {
            if index >= content.count {
                return nil
            }
            defer { index += 1 }
            return content[index]
        }
    }

    case nothing
    case int(Int)
    case float(Float)
    case string(String)
    case bool(Bool)
    case tuple([Evaluation])
    // case nominalType ...

    func describe(formating: String) -> String {
        switch self {
        case .nothing:
            "nothing"
        case let .int(int):
            "\(int)"
        case let .float(float):
            String(format: formating, float)
        case let .string(string):
            string
        case let .bool(bool):
            "\(bool)"
        case let .tuple(evaluations):
            "[\(evaluations.map { $0.describe(formating: formating) }.joined(separator: ", "))]"
        }
    }

    var typeName: String {
        return switch self {
        case .nothing:
            "Nothing"
        case .int:
            "Int"
        case .float:
            "Float"
        case .string:
            "String"
        case .bool:
            "Bool"
        case let .tuple(types):
            "[\(types.map { $0.typeName }.joined(separator: ", "))]"
        }
    }

    var count: Int {
        return switch self {
        case .nothing, .int, .float, .string, .bool:
            1
        case let .tuple(evaluations):
            evaluations.count
        }
    }

    func makeIterator() -> Iterator {
        return Iterator(self)
    }
}

struct EvaluationScope {
    var locals: [String: Evaluation]
    // let globals: 
}

protocol Evaluable {
    func evaluate(
        with input: Evaluation, and scope: EvaluationScope
    ) -> Result<Evaluation, SemanticError>
}

extension Module: Evaluable {
    func evaluate(
        with input: Evaluation, and scope: EvaluationScope
    ) -> Result<Evaluation, SemanticError> {
        let main = self.statements.filter { statement in
            if case let .functionDefinition(functionDefinition) = statement {
                return functionDefinition.name == "main"
            }
            return false
        }
        guard main.count == 1, let main = main.first, case let .functionDefinition(main) = main else {
            return .failure(.mainFunctionNotFound)
        }
        return main.body.evaluate(with: input, and: scope)
    }
}

extension Expression: Evaluable {
    func getFields() -> Set<String> {
        switch self.expressionType {
        case let .field(field):
            return Set([field])
        case let .positive(unary), let .negative(unary), let .not(unary):
            return unary.getFields()
        case let .plus(left, right), let .minus(left, right),
             let .times(left, right), let .by(left, right), let .mod(left, right),
             let .equal(left, right), let .different(left, right),
             let .lessThan(left, right), let .lessThanEqual(left, right),
             let .greaterThan(left, right), let .greaterThanEqual(left, right),
             let .or(left, right), let .and(left, right):
            return left.getFields().union(right.getFields())
        // TODO: adding compoud
        default:
            return Set()
        }
    }

    func evaluate(
        with input: Evaluation, and scope: EvaluationScope
    ) -> Result<Evaluation, SemanticError> {
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
        case (input, .positive(let value)):
            let right = value.evaluate(with: .nothing, and: scope)
            switch (input, right) {
            case (.nothing, .success(.int(let value))):
                return .success(.int(value))
            case (.nothing, .success(.float(let value))):
                return .success(.float(value))
            case (.int(let left), .success(.int(let right))):
                return .success(.int(left + right))
            case (.float(let left), .success(.float(let right))):
                return .success(.float(left + right))
            case (_, .failure(let error)):
                return .failure(error)
            case (_, .success(let right)):
                return .failure(.invalidInputForExpression(
                    location: location, expected: input.typeName, received: right.typeName))
            }
        case (input, .negative(let value)):
            let right = value.evaluate(with: .nothing, and: scope)
            switch (input, right) {
            case (.nothing, .success(.int(let value))):
                return .success(.int(-value))
            case (.nothing, .success(.float(let value))):
                return .success(.float(-value))
            case (.int(let left), .success(.int(let right))):
                return .success(.int(left - right))
            case (.float(let left), .success(.float(let right))):
                return .success(.float(left - right))
            case (_, .failure(let error)):
                return .failure(error)
            case (_, .success(let right)):
                return .failure(.invalidInputForExpression(
                    location: location, expected: input.typeName, received: right.typeName))
            }
        case (.nothing, .not(let value)):
            let right = value.evaluate(with: .nothing, and: scope)
            switch right {
            case .success(.bool(let value)):
                return .success(.bool(!value))
            case .success(let value):
                return .failure(.invalidOperation(
                    location: location, operation: "not", left: value.typeName, right: "bool"))
            case let .failure(error):
                return .failure(error)
            }

        case (input, .multiplied(let value)):
            let right = value.evaluate(with: .nothing, and: scope)
            switch (input, right) {
            case (.int(let left), .success(.int(let right))):
                return .success(.int(left * right))
            case (.float(let left), .success(.float(let right))):
                return .success(.float(left * right))
            case (_, .failure(let error)):
                return .failure(error)
            case (_, .success(let right)):
                return .failure(.invalidInputForExpression(
                    location: location, expected: input.typeName, received: right.typeName))
            }

        case (input, .divided(let value)):
            let right = value.evaluate(with: .nothing, and: scope)
            switch (input, right) {
            case (.int(let left), .success(.int(let right))):
                return .success(.int(left / right))
            case (.float(let left), .success(.float(let right))):
                return .success(.float(left / right))
            case (_, .failure(let error)):
                return .failure(error)
            case (_, .success(let right)):
                return .failure(.invalidInputForExpression(
                    location: location, expected: input.typeName, received: right.typeName))
            }

        case (input, .moduled(let value)):
            let right = value.evaluate(with: .nothing, and: scope)
            switch (input, right) {
            case (.int(let left), .success(.int(let right))):
                return .success(.int(left % right))
            case (_, .failure(let error)):
                return .failure(error)
            case (_, .success(let right)):
                return .failure(.invalidInputForExpression(
                    location: location, expected: input.typeName, received: right.typeName))
            }

        case (input, .anded(let value)):
            let right = value.evaluate(with: .nothing, and: scope)
            switch (input, right) {
            case (.bool(let left), .success(.bool(let right))):
                return .success(.bool(left && right))
            case (_, .failure(let error)):
                return .failure(error)
            case (_, .success(let right)):
                return .failure(.invalidInputForExpression(
                    location: location, expected: input.typeName, received: right.typeName))
            }

        case (input, .ored(let value)):
            let right = value.evaluate(with: .nothing, and: scope)
            switch (input, right) {
            case (.bool(let left), .success(.bool(let right))):
                return .success(.bool(left || right))
            case (_, .failure(let error)):
                return .failure(error)
            case (_, .success(let right)):
                return .failure(.invalidInputForExpression(
                    location: location, expected: input.typeName, received: right.typeName))
            }

        // Binary
        case (.nothing, .plus(let leftExpression, let rightExpression)):
            let left = leftExpression.evaluate(with: input, and: scope)
            let right = rightExpression.evaluate(with: input, and: scope)

            switch (left, right) {
            case (.success(.int(let left)), .success(.int(let right))):
                return .success(.int(left + right))
            case (.success(.float(let left)), .success(.float(let right))):
                return .success(.float(left + right))
            case (.success(let left), .success(let right)):
                return .failure(.invalidOperation(
                    location: location, operation: "+", left: left.typeName, right: right.typeName))
            case (.failure(let left), _):
                return .failure(left)
            case (_, .failure(let right)):
                return .failure(right)
            }
        case (.nothing, .minus(let leftExpression, let rightExpression)):
            let left = leftExpression.evaluate(with: input, and: scope)
            let right = rightExpression.evaluate(with: input, and: scope)

            switch (left, right) {
            case (.success(.int(let left)), .success(.int(let right))):
                return .success(.int(left - right))
            case (.success(.float(let left)), .success(.float(let right))):
                return .success(.float(left - right))
            case (.success(let left), .success(let right)):
                return .failure(.invalidOperation(
                    location: location, operation: "-", left: left.typeName, right: right.typeName))
            case (.failure(let left), _):
                return .failure(left)
            case (_, .failure(let right)):
                return .failure(right)
            }
        case (.nothing, .times(let leftExpression, let rightExpression)):
            let left = leftExpression.evaluate(with: input, and: scope)
            let right = rightExpression.evaluate(with: input, and: scope)

            switch (left, right) {
            case (.success(.int(let left)), .success(.int(let right))):
                return .success(.int(left * right))
            case (.success(.float(let left)), .success(.float(let right))):
                return .success(.float(left * right))
            case (.success(let left), .success(let right)):
                return .failure(.invalidOperation(
                location: location, operation: "*", left: left.typeName, right: right.typeName))
            case (.failure(let left), _):
                return .failure(left)
            case (_, .failure(let right)):
                return .failure(right)
            }
        case (.nothing, .by(let leftExpression, let rightExpression)):
            let left = leftExpression.evaluate(with: input, and: scope)
            let right = rightExpression.evaluate(with: input, and: scope)

            switch (left, right) {
            case (.success(.int(let left)), .success(.int(let right))):
                return .success(.int(left / right))
            case (.success(.float(let left)), .success(.float(let right))):
                return .success(.float(left / right))
            case (.success(let left), .success(let right)):
                return .failure(.invalidOperation(
                    location: location, operation: "/", left: left.typeName, right: right.typeName))
            case (.failure(let left), _):
                return .failure(left)
            case (_, .failure(let right)):
                return .failure(right)
            }
        case (.nothing, .mod(let leftExpression, let rightExpression)):
            let left = leftExpression.evaluate(with: input, and: scope)
            let right = rightExpression.evaluate(with: input, and: scope)

            switch (left, right) {
            case (.success(.int(let left)), .success(.int(let right))):
                return .success(.int(left % right))
            case (.success(let left), .success(let right)):
                return .failure(.invalidOperation(
                    location: location, operation: "%", left: left.typeName, right: right.typeName))
            case (.failure(let left), _):
                return .failure(left)
            case (_, .failure(let right)):
                return .failure(right)
            }
        case (.nothing, .equal(let leftExpression, let rightExpression)):
            let left = leftExpression.evaluate(with: input, and: scope)
            let right = rightExpression.evaluate(with: input, and: scope)

            switch (left, right) {
            case (.success(.int(let left)), .success(.int(let right))):
                return .success(.bool(left == right))
            case (.success(.float(let left)), .success(.float(let right))):
                return .success(.bool(left == right))
            case (.success(.string(let left)), .success(.string(let right))):
                return .success(.bool(left == right))
            case (.success(.bool(let left)), .success(.bool(let right))):
                return .success(.bool(left == right))
            case (.success(let left), .success(let right)):
                return .failure(.invalidOperation(
                    location: location, operation: "=", left: left.typeName, right: right.typeName))
            case (.failure(let left), _):
                return .failure(left)
            case (_, .failure(let right)):
                return .failure(right)
            }
        case (.nothing, .different(let leftExpression, let rightExpression)):
            let left = leftExpression.evaluate(with: input, and: scope)
            let right = rightExpression.evaluate(with: input, and: scope)

            switch (left, right) {
            case (.success(.int(let left)), .success(.int(let right))):
                return .success(.bool(left != right))
            case (.success(.float(let left)), .success(.float(let right))):
                return .success(.bool(left != right))
            case (.success(.string(let left)), .success(.string(let right))):
                return .success(.bool(left != right))
            case (.success(.bool(let left)), .success(.bool(let right))):
                return .success(.bool(left != right))
            case (.success(let left), .success(let right)):
                return .failure(.invalidOperation(
                    location: location, operation: "!=", left: left.typeName, right: right.typeName))
            case (.failure(let left), _):
                return .failure(left)
            case (_, .failure(let right)):
                return .failure(right)
            }
        case (.nothing, .lessThan(let leftExpression, let rightExpression)):
            let left = leftExpression.evaluate(with: input, and: scope)
            let right = rightExpression.evaluate(with: input, and: scope)

            switch (left, right) {
            case (.success(.int(let left)), .success(.int(let right))):
                return .success(.bool(left < right))
            case (.success(.float(let left)), .success(.float(let right))):
                return .success(.bool(left < right))
            case (.success(let left), .success(let right)):
                return .failure(.invalidOperation(
                    location: location, operation: "<", left: left.typeName, right: right.typeName))
            case (.failure(let left), _):
                return .failure(left)
            case (_, .failure(let right)):
                return .failure(right)
            }
        case (.nothing, .lessThanEqual(let leftExpression, let rightExpression)):
            let left = leftExpression.evaluate(with: input, and: scope)
            let right = rightExpression.evaluate(with: input, and: scope)

            switch (left, right) {
            case (.success(.int(let left)), .success(.int(let right))):
                return .success(.bool(left <= right))
            case (.success(.float(let left)), .success(.float(let right))):
                return .success(.bool(left <= right))
            case (.success(let left), .success(let right)):
                return .failure(.invalidOperation(
                    location: location, operation: "<=", left: left.typeName, right: right.typeName))
            case (.failure(let left), _):
                return .failure(left)
            case (_, .failure(let right)):
                return .failure(right)
            }
        case (.nothing, .greaterThan(let leftExpression, let rightExpression)):
            let left = leftExpression.evaluate(with: input, and: scope)
            let right = rightExpression.evaluate(with: input, and: scope)

            switch (left, right) {
            case (.success(.int(let left)), .success(.int(let right))):
                return .success(.bool(left > right))
            case (.success(.float(let left)), .success(.float(let right))):
                return .success(.bool(left > right))
            case (.success(let left), .success(let right)):
                return .failure(.invalidOperation(
                    location: location, operation: ">", left: left.typeName, right: right.typeName))
            case (.failure(let left), _):
                return .failure(left)
            case (_, .failure(let right)):
                return .failure(right)
            }
        case (.nothing, .greaterThanEqual(let leftExpression, let rightExpression)):
            let left = leftExpression.evaluate(with: input, and: scope)
            let right = rightExpression.evaluate(with: input, and: scope)

            switch (left, right) {
            case (.success(.int(let left)), .success(.int(let right))):
                return .success(.bool(left >= right))
            case (.success(.float(let left)), .success(.float(let right))):
                return .success(.bool(left >= right))
            case (.success(let left), .success(let right)):
                return .failure(.invalidOperation(
                    location: location, operation: ">=", left: left.typeName, right: right.typeName))
            case (.failure(let left), _):
                return .failure(left)
            case (_, .failure(let right)):
                return .failure(right)
            }
        case (.nothing, .or(let leftExpression, let rightExpression)):
            let left = leftExpression.evaluate(with: input, and: scope)
            let right = rightExpression.evaluate(with: input, and: scope)

            switch (left, right) {
            case (.success(.bool(let left)), .success(.bool(let right))):
                return .success(.bool(left || right))
            case (.success(let left), .success(let right)):
                return .failure(.invalidOperation(
                    location: location, operation: "or", left: left.typeName, right: right.typeName))
            case (.failure(let left), _):
                return .failure(left)
            case (_, .failure(let right)):
                return .failure(right)
            }
        case (.nothing, .and(let leftExpression, let rightExpression)):
            let left = leftExpression.evaluate(with: input, and: scope)
            let right = rightExpression.evaluate(with: input, and: scope)

            switch (left, right) {
            case (.success(.bool(let left)), .success(.bool(let right))):
                return .success(.bool(left && right))
            case (.success(let left), .success(let right)):
                return .failure(.invalidOperation(
                    location: location, operation: "and", left: left.typeName, right: right.typeName))
            case (.failure(let left), _):
                return .failure(left)
            case (_, .failure(let right)):
                return .failure(right)
            }
        case (input, .plus),
             (input, .minus),
             (input, .times),
             (input, .by),
             (input, .mod),
             (input, .equal),
             (input, .different),
             (input, .lessThan),
             (input, .lessThanEqual),
             (input, .greaterThan),
             (input, .greaterThanEqual):
            return .failure(.invalidInputForExpression(
                location: location, expected: "Nothing", received: input.typeName))

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
        default:
            return .failure(.notImplemented(location: self.location, description: "wip"))
        }
    }
}
//     func getFields() -> Set<String> {
// }
//
// extension Expression.Call: Evaluable {
//     func evaluate(
//         with input: Evaluation, and scope: [String: Evaluation]
//     ) -> Result<Evaluation, SemanticError> {
//         switch self.command {
//         case .field("print"):
//             if let format = (self.arguments.first { $0.name == "format" }) {
//                 let argument = format.value.evaluate(with: .nothing, and: scope)
//                 if case let .success(.string(format)) = argument {
//                     print(format.peoplFormat([input]))
//                 } else {
//                     return .failure(.notImplemented)
//                 }
//                 return .success(input)
//             } else {
//                 print(input.describe(formating: ""))
//                 return .success(input)
//             }
//         default:
//             return .failure(.notImplemented)
//         }
//     }
// }
//


extension Expression.Branched: Evaluable {
    
    func evaluateCaptureGroupExpression(
        with input: Evaluation
    ) -> Result<Evaluation, SemanticError> {
        return .success(.nothing)
    }

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
                        case (_, .field):
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
                        case (_, .access), (_, .branched), (_, .piped), (_, .lambda), (_, .tuple):
                            throw SemanticError.invalidCaptureGroup(
                                location: expression.location)
                        default:
                            let fields = expression.getFields()
                            let scopeFields = Set(scope.locals.keys)
                            let capturedInputSet = fields.union(scopeFields).symmetricDifference(scopeFields)
                            if capturedInputSet.count > 1 {
                                throw SemanticError.tooManyFieldsInCaptureGroup(
                                    location: expression.location, fields: Array(capturedInputSet))
                            } else if capturedInputSet.count == 1, let capturedInput = capturedInputSet.first{
                                modifiedScope.locals[capturedInput] = input
                                switch expression.evaluate(with: .nothing, and: modifiedScope) {
                                case let .success(.bool(value)):
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
                } != nil
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
