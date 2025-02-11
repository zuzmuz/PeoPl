extension Expression: TypeChecker {
    func checkType(
        with input: TypeIdentifier,
        localScope: LocalScope,
        context: TypeCheckerContext
    ) throws(ExpressionSemanticError) -> TypeIdentifier {

        switch (input, self.expressionType) {
        // Never
        case (_, .never):
            throw .reachedNever(expression: self)
        //Nothing
        case (.nothing, .nothing):
            return input

        // Literals
        case (.nothing, .intLiteral):
            return Builtins.i32
        case (.nothing, .floatLiteral):
            return Builtins.f64
        case (.nothing, .stringLiteral):
            return Builtins.string
        case (.nothing, .boolLiteral):
            return Builtins.bool
        case (input, .nothing),
            (input, .intLiteral),
            (input, .floatLiteral),
            (input, .stringLiteral),
            (input, .boolLiteral):
            throw .inputMismatch(
                expression: self,
                expected: .nothing(location: .nowhere),
                received: input)

        // Unary
        // TODO: consider operator overload
        case let (input, .positive(expression)),
            let (input, .negative(expression)):
            let right = try expression.checkType(
                with: .nothing(location: .nowhere),
                localScope: localScope,
                context: context)

            switch (input, right) {
            case (.nothing, Builtins.i32),
                (.nothing, Builtins.f64),
                (.nothing, Builtins.string),
                (.nothing, Builtins.bool),
                (Builtins.i32, Builtins.i32),
                (Builtins.f64, Builtins.f64):
                return right
            default:
                throw .invalidOperation(
                    expression: self,
                    leftType: input,
                    rightType: right)
            }
        case let (input, .multiplied(expression)),
            let (input, .divided(expression)):

            let right = try expression.checkType(
                with: .nothing(location: .nowhere),
                localScope: localScope,
                context: context)
            switch (input, right) {
            case (Builtins.i32, Builtins.i32),
                (Builtins.f64, Builtins.f64):
                return right
            default:
                throw .invalidOperation(
                    expression: self,
                    leftType: input,
                    rightType: right)
            }
        case let (input, .moduled(expression)):
            let right = try expression.checkType(
                with: .nothing(location: .nowhere),
                localScope: localScope,
                context: context)
            switch (input, right) {
            case (Builtins.i32, Builtins.i32):
                return right
            default:
                throw .invalidOperation(
                    expression: self,
                    leftType: input,
                    rightType: right)
            }
        case let (input, .anded(expression)),
            let (input, .ored(expression)):
            let right = try expression.checkType(
                with: .nothing(location: .nowhere),
                localScope: localScope,
                context: context)
            switch (input, right) {
            case (Builtins.bool, Builtins.bool):
                return right
            default:
                throw .invalidOperation(
                    expression: self,
                    leftType: input,
                    rightType: right)
            }
        case let (input, .not(expression)):
            let right = try expression.checkType(
                with: .nothing(location: .nowhere),
                localScope: localScope,
                context: context)
            switch (input, right) {
            case (.nothing, Builtins.bool):
                return right
            default:
                throw .invalidOperation(
                    expression: self,
                    leftType: input,
                    rightType: right)
            }

        case let (.nothing, .plus(leftExpression, rightExpression)),
            let (.nothing, .minus(leftExpression, rightExpression)),
            let (.nothing, .times(leftExpression, rightExpression)),
            let (.nothing, .by(leftExpression, rightExpression)):

            let left = try leftExpression.checkType(
                with: input,
                localScope: localScope,
                context: context)
            let right = try rightExpression.checkType(
                with: input,
                localScope: localScope,
                context: context)
            switch (left, right) {
            case (Builtins.i32, Builtins.i32),
                (Builtins.f64, Builtins.f64):
                return right
            default:
                throw .invalidOperation(
                    expression: self,
                    leftType: input,
                    rightType: right)
            }
        case let (.nothing, .mod(leftExpression, rightExpression)):
            let left = try leftExpression.checkType(
                with: input,
                localScope: localScope,
                context: context)
            let right = try rightExpression.checkType(
                with: input,
                localScope: localScope,
                context: context)
            switch (left, right) {
            case (Builtins.i32, Builtins.i32):
                return right
            default:
                throw .invalidOperation(
                    expression: self,
                    leftType: input,
                    rightType: right)
            }
        case let (.nothing, .equal(leftExpression, rightExpression)),
            let (.nothing, .different(leftExpression, rightExpression)):
            let left = try leftExpression.checkType(
                with: input,
                localScope: localScope,
                context: context)
            let right = try rightExpression.checkType(
                with: input,
                localScope: localScope,
                context: context)
            switch (left, right) {
            case (Builtins.i32, Builtins.i32),
                (Builtins.f64, Builtins.f64),
                (Builtins.string, Builtins.string),
                (Builtins.bool, Builtins.bool):
                return Builtins.bool
            default:
                throw .invalidOperation(
                    expression: self,
                    leftType: input,
                    rightType: right)
            }

        case let (.nothing, .lessThan(leftExpression, rightExpression)),
            let (.nothing, .lessThanEqual(leftExpression, rightExpression)),
            let (.nothing, .greaterThan(leftExpression, rightExpression)),
            let (.nothing, .greaterThanEqual(leftExpression, rightExpression)):
            let left = try leftExpression.checkType(
                with: input,
                localScope: localScope,
                context: context)
            let right = try rightExpression.checkType(
                with: input,
                localScope: localScope,
                context: context)
            switch (left, right) {
            case (Builtins.i32, Builtins.i32),
                (Builtins.f64, Builtins.f64):
                return Builtins.bool
            default:
                throw .invalidOperation(
                    expression: self,
                    leftType: input,
                    rightType: right)
            }

        case let (.nothing, .or(leftExpression, rightExpression)),
            let (.nothing, .and(leftExpression, rightExpression)):
            let left = try leftExpression.checkType(
                with: input,
                localScope: localScope,
                context: context)
            let right = try rightExpression.checkType(
                with: input,
                localScope: localScope,
                context: context)
            switch (left, right) {
            case (Builtins.bool, Builtins.bool):
                return Builtins.bool
            default:
                throw .invalidOperation(
                    expression: self,
                    leftType: input,
                    rightType: right)
            }
        case (_, .plus), (_, .minus), (_, .times), (_, .by), (_, .mod),
            (_, .equal), (_, .different), (_, .lessThan), (_, .lessThanEqual),
            (_, .greaterThan), (_, .greaterThanEqual), (_, .or), (_, .and):
            throw .inputMismatch(
                expression: self,
                expected: .nothing(location: .nowhere),
                received: input)
        case let (.nothing, .unnamedTuple(expressions)):
            let typeIdentifiers = try expressions.map { expression throws(ExpressionSemanticError) in
                return try expression.checkType(
                    with: .nothing(location: .nowhere),
                    localScope: localScope,
                    context: context)
            }
            return .unnamedTuple(.init(types: typeIdentifiers, location: .nowhere))
        case let (.nothing, .namedTuple(arguments)):
            let paramDefinitions = try arguments.map { argument throws(ExpressionSemanticError) in
                return ParamDefinition(
                    name: argument.name, 
                    type: try argument.value.checkType(
                        with: .nothing(location: .nowhere),
                        localScope: localScope,
                        context: context),
                    location: .nowhere)
            }
            return .namedTuple(.init(types: paramDefinitions, location: .nowhere))
        case (_, .namedTuple), (_, .unnamedTuple):
            throw .inputMismatch(
                expression: self,
                expected: .nothing(location: .nowhere),
                received: input)
        case let (_, .lambda(expression)):
            throw .unsupportedYet("lambda expression")
        case let (input, .call(call)):
            return try call.checkType(with: input, localScope: localScope, context: context)
        case let (input, .access(access)):
            break
        case let (input, .field(field)):
            break
        case let (input, .branched(branched)):
            break
        case let (input, .piped(leftExpression, rightExpression)):
            break
            
            





        //
        // // Binary
        // case (.nothing, .plus(let leftExpression, let rightExpression)):
        //     let left = leftExpression.evaluate(with: input, and: scope)
        //     let right = rightExpression.evaluate(with: input, and: scope)
        //
        //     switch (left, right) {
        //     case (.success(.int(let left)), .success(.int(let right))):
        //         return .success(.int(left + right))
        //     case (.success(.float(let left)), .success(.float(let right))):
        //         return .success(.float(left + right))
        //     case (.success(let left), .success(let right)):
        //         return .failure(.invalidOperation(
        //             location: location, operation: "+", left: left.typeName, right: right.typeName))
        //     case (.failure(let left), _):
        //         return .failure(left)
        //     case (_, .failure(let right)):
        //         return .failure(right)
        //     }
        // case (.nothing, .minus(let leftExpression, let rightExpression)):
        //     let left = leftExpression.evaluate(with: input, and: scope)
        //     let right = rightExpression.evaluate(with: input, and: scope)
        //
        //     switch (left, right) {
        //     case (.success(.int(let left)), .success(.int(let right))):
        //         return .success(.int(left - right))
        //     case (.success(.float(let left)), .success(.float(let right))):
        //         return .success(.float(left - right))
        //     case (.success(let left), .success(let right)):
        //         return .failure(.invalidOperation(
        //             location: location, operation: "-", left: left.typeName, right: right.typeName))
        //     case (.failure(let left), _):
        //         return .failure(left)
        //     case (_, .failure(let right)):
        //         return .failure(right)
        //     }
        // case (.nothing, .times(let leftExpression, let rightExpression)):
        //     let left = leftExpression.evaluate(with: input, and: scope)
        //     let right = rightExpression.evaluate(with: input, and: scope)
        //
        //     switch (left, right) {
        //     case (.success(.int(let left)), .success(.int(let right))):
        //         return .success(.int(left * right))
        //     case (.success(.float(let left)), .success(.float(let right))):
        //         return .success(.float(left * right))
        //     case (.success(let left), .success(let right)):
        //         return .failure(.invalidOperation(
        //         location: location, operation: "*", left: left.typeName, right: right.typeName))
        //     case (.failure(let left), _):
        //         return .failure(left)
        //     case (_, .failure(let right)):
        //         return .failure(right)
        //     }
        // case (.nothing, .by(let leftExpression, let rightExpression)):
        //     let left = leftExpression.evaluate(with: input, and: scope)
        //     let right = rightExpression.evaluate(with: input, and: scope)
        //
        //     switch (left, right) {
        //     case (.success(.int(let left)), .success(.int(let right))):
        //         return .success(.int(left / right))
        //     case (.success(.float(let left)), .success(.float(let right))):
        //         return .success(.float(left / right))
        //     case (.success(let left), .success(let right)):
        //         return .failure(.invalidOperation(
        //             location: location, operation: "/", left: left.typeName, right: right.typeName))
        //     case (.failure(let left), _):
        //         return .failure(left)
        //     case (_, .failure(let right)):
        //         return .failure(right)
        //     }
        // case (.nothing, .mod(let leftExpression, let rightExpression)):
        //     let left = leftExpression.evaluate(with: input, and: scope)
        //     let right = rightExpression.evaluate(with: input, and: scope)
        //
        //     switch (left, right) {
        //     case (.success(.int(let left)), .success(.int(let right))):
        //         return .success(.int(left % right))
        //     case (.success(let left), .success(let right)):
        //         return .failure(.invalidOperation(
        //             location: location, operation: "%", left: left.typeName, right: right.typeName))
        //     case (.failure(let left), _):
        //         return .failure(left)
        //     case (_, .failure(let right)):
        //         return .failure(right)
        //     }
        // case (.nothing, .equal(let leftExpression, let rightExpression)):
        //     let left = leftExpression.evaluate(with: input, and: scope)
        //     let right = rightExpression.evaluate(with: input, and: scope)
        //
        //     switch (left, right) {
        //     case (.success(.int(let left)), .success(.int(let right))):
        //         return .success(.bool(left == right))
        //     case (.success(.float(let left)), .success(.float(let right))):
        //         return .success(.bool(left == right))
        //     case (.success(.string(let left)), .success(.string(let right))):
        //         return .success(.bool(left == right))
        //     case (.success(.bool(let left)), .success(.bool(let right))):
        //         return .success(.bool(left == right))
        //     case (.success(let left), .success(let right)):
        //         return .failure(.invalidOperation(
        //             location: location, operation: "=", left: left.typeName, right: right.typeName))
        //     case (.failure(let left), _):
        //         return .failure(left)
        //     case (_, .failure(let right)):
        //         return .failure(right)
        //     }
        // case (.nothing, .different(let leftExpression, let rightExpression)):
        //     let left = leftExpression.evaluate(with: input, and: scope)
        //     let right = rightExpression.evaluate(with: input, and: scope)
        //
        //     switch (left, right) {
        //     case (.success(.int(let left)), .success(.int(let right))):
        //         return .success(.bool(left != right))
        //     case (.success(.float(let left)), .success(.float(let right))):
        //         return .success(.bool(left != right))
        //     case (.success(.string(let left)), .success(.string(let right))):
        //         return .success(.bool(left != right))
        //     case (.success(.bool(let left)), .success(.bool(let right))):
        //         return .success(.bool(left != right))
        //     case (.success(let left), .success(let right)):
        //         return .failure(.invalidOperation(
        //             location: location, operation: "!=", left: left.typeName, right: right.typeName))
        //     case (.failure(let left), _):
        //         return .failure(left)
        //     case (_, .failure(let right)):
        //         return .failure(right)
        //     }
        // case (.nothing, .lessThan(let leftExpression, let rightExpression)):
        //     let left = leftExpression.evaluate(with: input, and: scope)
        //     let right = rightExpression.evaluate(with: input, and: scope)
        //
        //     switch (left, right) {
        //     case (.success(.int(let left)), .success(.int(let right))):
        //         return .success(.bool(left < right))
        //     case (.success(.float(let left)), .success(.float(let right))):
        //         return .success(.bool(left < right))
        //     case (.success(let left), .success(let right)):
        //         return .failure(.invalidOperation(
        //             location: location, operation: "<", left: left.typeName, right: right.typeName))
        //     case (.failure(let left), _):
        //         return .failure(left)
        //     case (_, .failure(let right)):
        //         return .failure(right)
        //     }
        // case (.nothing, .lessThanEqual(let leftExpression, let rightExpression)):
        //     let left = leftExpression.evaluate(with: input, and: scope)
        //     let right = rightExpression.evaluate(with: input, and: scope)
        //
        //     switch (left, right) {
        //     case (.success(.int(let left)), .success(.int(let right))):
        //         return .success(.bool(left <= right))
        //     case (.success(.float(let left)), .success(.float(let right))):
        //         return .success(.bool(left <= right))
        //     case (.success(let left), .success(let right)):
        //         return .failure(.invalidOperation(
        //             location: location, operation: "<=", left: left.typeName, right: right.typeName))
        //     case (.failure(let left), _):
        //         return .failure(left)
        //     case (_, .failure(let right)):
        //         return .failure(right)
        //     }
        // case (.nothing, .greaterThan(let leftExpression, let rightExpression)):
        //     let left = leftExpression.evaluate(with: input, and: scope)
        //     let right = rightExpression.evaluate(with: input, and: scope)
        //
        //     switch (left, right) {
        //     case (.success(.int(let left)), .success(.int(let right))):
        //         return .success(.bool(left > right))
        //     case (.success(.float(let left)), .success(.float(let right))):
        //         return .success(.bool(left > right))
        //     case (.success(let left), .success(let right)):
        //         return .failure(.invalidOperation(
        //             location: location, operation: ">", left: left.typeName, right: right.typeName))
        //     case (.failure(let left), _):
        //         return .failure(left)
        //     case (_, .failure(let right)):
        //         return .failure(right)
        //     }
        // case (.nothing, .greaterThanEqual(let leftExpression, let rightExpression)):
        //     let left = leftExpression.evaluate(with: input, and: scope)
        //     let right = rightExpression.evaluate(with: input, and: scope)
        //
        //     switch (left, right) {
        //     case (.success(.int(let left)), .success(.int(let right))):
        //         return .success(.bool(left >= right))
        //     case (.success(.float(let left)), .success(.float(let right))):
        //         return .success(.bool(left >= right))
        //     case (.success(let left), .success(let right)):
        //         return .failure(.invalidOperation(
        //             location: location, operation: ">=", left: left.typeName, right: right.typeName))
        //     case (.failure(let left), _):
        //         return .failure(left)
        //     case (_, .failure(let right)):
        //         return .failure(right)
        //     }
        // case (.nothing, .or(let leftExpression, let rightExpression)):
        //     let left = leftExpression.evaluate(with: input, and: scope)
        //     let right = rightExpression.evaluate(with: input, and: scope)
        //
        //     switch (left, right) {
        //     case (.success(.bool(let left)), .success(.bool(let right))):
        //         return .success(.bool(left || right))
        //     case (.success(let left), .success(let right)):
        //         return .failure(.invalidOperation(
        //             location: location, operation: "or", left: left.typeName, right: right.typeName))
        //     case (.failure(let left), _):
        //         return .failure(left)
        //     case (_, .failure(let right)):
        //         return .failure(right)
        //     }
        // case (.nothing, .and(let leftExpression, let rightExpression)):
        //    let left = leftExpression.evaluate(with: input, and: scope)
        //     let right = rightExpression.evaluate(with: input, and: scope)
        //
        //     switch (left, right) {
        //     case (.success(.bool(let left)), .success(.bool(let right))):
        //         return .success(.bool(left && right))
        //     case (.success(let left), .success(let right)):
        //         return .failure(.invalidOperation(
        //             location: location, operation: "and", left: left.typeName, right: right.typeName))
        //     case (.failure(let left), _):
        //         return .failure(left)
        //     case (_, .failure(let right)):
        //         return .failure(right)
        //     }
        // case (input, .plus),
        //      (input, .minus),
        //      (input, .times),
        //      (input, .by),
        //      (input, .mod),
        //      (input, .equal),
        //      (input, .different),
        //      (input, .lessThan),
        //      (input, .lessThanEqual),
        //      (input, .greaterThan),
        //      (input, .greaterThanEqual):
        //     return .failure(.invalidInputForExpression(
        //         location: location, expected: "Nothing", received: input.typeName))
        //
        // case (input, .branched(let branched)):
        //     return branched.evaluate(with: input, and: scope)
        // case (input, .piped(let leftExpression, let rightExpression)):
        //     let left = leftExpression.evaluate(with: input, and: scope)
        //     switch left {
        //     case .success(let evaluation):
        //         return rightExpression.evaluate(with: evaluation, and: scope)
        //     case .failure(let error):
        //         return .failure(error)
        //     }
        // case (.nothing, .field(let fieldName)):
        //     if let fieldValue = scope.locals[fieldName] {
        //         return .success(fieldValue)
        //     } else {
        //         return .failure(.fieldNotInScope(location: location, fieldName: fieldName))
        //     }
        // case (input, .call(let call)):
        //     return call.evaluate(with: input, and: scope)
        // case (.nothing, .unnamedTuple(let expressions)):
        //     let results = expressions.map { $0.evaluate(with: input, and: scope) }
        //     if case let .failure(error) = (results.first { (try? $0.get()) == nil }) {
        //         return .failure(error)
        //     }
        //     return .success(.unnamedTuple(results.compactMap { try? $0.get() }))
        // case (input, .unnamedTuple):
        //     return .failure(.invalidInputForExpression(
        //         location: location, expected: "Nothing", received: input.typeName))
        // case (.nothing, .namedTuple(let expressions)):
        //     let results = expressions.map { ($0.name, $0.value.evaluate(with: input, and: scope)) }
        //     if case let .failure(error) = (results.first { (try? $0.1.get()) == nil })?.1 {
        //         return .failure(error)
        //     }
        //     return .success(.namedTuple(results.compactMap { result in
        //         if let evaluation = try? result.1.get() {
        //             return Evaluation.NamedEvaluation(name: result.0, value: evaluation)
        //         }
        //         return nil
        //     }))
        // case (input, .namedTuple):
        //     return .failure(.invalidInputForExpression(
        //         location: location, expected: "Nothing", received: input.typeName))
        default:
            return .simpleNominalType(name: "invalid")
        }
        return .simpleNominalType(name: "invalid")
    }
}
