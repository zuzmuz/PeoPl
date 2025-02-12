extension Expression: TypeChecker {
    func checkType(
        with input: TypeIdentifier,
        localScope: LocalScope,
        context: TypeCheckerContext
    ) throws(ExpressionSemanticError) -> TypeIdentifier {

        switch (input, self.expressionType) {
        // Never
        case (_, .never), (.never, _):
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
        case (_, .nothing),
            (_, .intLiteral),
            (_, .floatLiteral),
            (_, .stringLiteral),
            (_, .boolLiteral):
            throw .inputMismatch(
                expression: self,
                expected: .nothing(),
                received: input)

        // Unary
        // TODO: consider operator overload
        case let (input, .positive(expression)),
            let (input, .negative(expression)):
            let right = try expression.checkType(
                with: .nothing(),
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
                with: .nothing(),
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
                with: .nothing(),
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
                with: .nothing(),
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
                with: .nothing(),
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
                expected: .nothing(),
                received: input)
        case let (.nothing, .unnamedTuple(expressions)):
            let typeIdentifiers = try expressions.map { expression throws(ExpressionSemanticError) in
                return try expression.checkType(
                    with: .nothing(),
                    localScope: localScope,
                    context: context)
            }
            return .unnamedTuple(.init(types: typeIdentifiers, location: .nowhere))
        case let (.nothing, .namedTuple(arguments)):
            let paramDefinitions = try arguments.map { argument throws(ExpressionSemanticError) in
                return ParamDefinition(
                    name: argument.name, 
                    type: try argument.value.checkType(
                        with: .nothing(),
                        localScope: localScope,
                        context: context),
                    location: .nowhere)
            }
            return .namedTuple(.init(types: paramDefinitions, location: .nowhere))
        case (_, .namedTuple), (_, .unnamedTuple):
            throw .inputMismatch(
                expression: self,
                expected: .nothing(),
                received: input)
        case let (_, .lambda(expression)):
            throw .unsupportedYet("lambda expression")
        case let (input, .call(call)):
            return try call.checkType(with: input, localScope: localScope, context: context)
        case let (input, .access(access)):
            throw .unsupportedYet("accessed fields")
        case let (.nothing, .field(field)):
            if let fieldType = localScope.fields[field] {
                return fieldType
            } else {
                throw .fieldNotInScope(expression: self)
            }
        case (_, .field):
            throw .inputMismatch(
                expression: self,
                expected: .nothing(),
                received: input)
        case let (input, .branched(branched)):
            return try branched.checkType(with: input, localScope: localScope, context: context)
        case let (input, .piped(leftExpression, rightExpression)):
            let leftType = try leftExpression.checkType(
                with: input,
                localScope: localScope,
                context: context)
            return try rightExpression.checkType(
                with: leftType,
                localScope: localScope,
                context: context)
        }
    }
}
