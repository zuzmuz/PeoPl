fileprivate extension String {
    func peoplFormat(_ arguments: [Evaluation]) -> String {
        var result = self
        for argument in arguments {
            result = result.replacingOccurrences(of: "{}", with: argument.describe(formating: ""))
        }
        return result
    }
}

enum Evaluation: Encodable, Equatable {
    case nothing
    case int(Int)
    case float(Float)
    case string(String)
    case bool(Bool)
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
        }
    }
}

struct EvaluationScope {
    let locals: [String: Evaluation]
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
        default:
            return .failure(.notImplemented)
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
    func evaluate(
        with input: Evaluation, and scope: EvaluationScope
    ) -> Result<Evaluation, SemanticError> {
        return .success(.nothing)

        // TODO: handle tupe input differently
        // print("evaluating branched")
        // do {
        //     var scope = scope
        //     let branch = try self.branches.filter { branch in
        //         guard let captureGroupExpression = branch.captureGroup.first else {
        //             throw SemanticError.noCaptureGroups
        //         }
        //         switch captureGroupExpression {
        //         case let .simple(simple):
        //             let fields = simple.getFields()
        //             let scopeFields = Set(scope.keys)
        //             let capturedInputSet = fields.union(scopeFields).symmetricDifference(scopeFields)
        //             // print("capturing, expression fields \(fields) scopw fields \(scopeFields) captured \(capturedInputSet)")
        //
        //             if capturedInputSet.count > 1 {
        //                 throw SemanticError.tooManyFieldsInCaptureGroup
        //             }
        //             if capturedInputSet.count == 1, let capturedInput = capturedInputSet.first {
        //                 scope[capturedInput] = input
        //                 if case .field = simple {
        //                     return true
        //                 } else {
        //                     switch simple.evaluate(with: .nothing, and: scope) {
        //                     case let .success(evaluation):
        //                         return evaluation == .bool(true)
        //                     case let .failure(error):
        //                         throw error
        //                     }
        //                 }
        //             } else {
        //                 switch simple.evaluate(with: .nothing, and: scope) {
        //                 case let .success(evaluation):
        //                     return evaluation == input
        //                 case let .failure(error):
        //                     throw error
        //                 }
        //             }
        //         case let .call(call):
        //             // switch call {
        //             // case let .field(field):
        //             //     
        //             // }
        //             // nested pattern matching
        //             return true //assign to scope
        //         default:
        //             throw SemanticError.invalidCaptureGroup
        //         }
        //     }.first
        //
        //     switch branch?.body {
        //     case let .simple(simple):
        //         return simple.evaluate(with: .nothing, and: scope)
        //     default:
        //         throw SemanticError.notImplemented
        //     }
        // } catch let error as SemanticError {
        //     return .failure(error)
        // } catch {
        //     return .failure(.invalidOperation)
        // }
    }
}
//
// extension Expression.Piped: Evaluable {
//     func evaluate(
//         with input: Evaluation, and scope: [String: Evaluation]
//     ) -> Result<Evaluation, SemanticError> {
//         // print("piping  input \(input) scope \(scope)")
//         return switch self {
//         case let .normal(left, right):
//             switch left.evaluate(with: input, and: scope) {
//             case let .success(leftEvaluation):
//                 right.evaluate(with: leftEvaluation, and: scope)
//             case let .failure(error):
//                 .failure(error)
//             }
//         case let .unwrapping(left, right):
//             .failure(.notImplemented)
//         }
//     }
// }
//
