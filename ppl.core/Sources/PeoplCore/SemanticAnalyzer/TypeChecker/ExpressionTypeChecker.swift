protocol ExpressionTypeChecker {
    func checkType(
        with input: TypeIdentifier,
        localScope: LocalScope,
        context: borrowing SemanticContext
    ) throws(ExpressionSemanticError) -> Self
}


extension Expression: ExpressionTypeChecker {

    func with(typeIdentifier: TypeIdentifier) -> Expression {
        return .init(
            expressionType: self.expressionType,
            location: self.location,
            typeIdentifier: typeIdentifier)
    }

    func checkType(
        with input: TypeIdentifier,
        localScope: LocalScope,
        context: borrowing SemanticContext
    ) throws(ExpressionSemanticError) -> Expression {

        guard case .unkown = self.typeIdentifier else { // if type is already known
            return self
        }

        switch (input, self.expressionType) {
        // Never
        case (_, .never), (.never, _):
            throw .reachedNever(expression: self)
        //Nothing
        case (.nothing, .nothing):
            return self.with(typeIdentifier: .nothing())
        // NOTE: think of generic int type for automatic inference
        // Literals
        case (.nothing, .intLiteral):
            // NOTE: consider undefined number type (with resetriction),
            // for example 10 can be an I8, I16 .. but also U8 ...
            // however 300 can not be I8, interesting logic
            return self.with(typeIdentifier: Builtins.i32)
        case (.nothing, .floatLiteral):
            return self.with(typeIdentifier: Builtins.f64)
        case (.nothing, .stringLiteral):
            return self.with(typeIdentifier: Builtins.string)
        case (.nothing, .boolLiteral):
            return self.with(typeIdentifier: Builtins.bool)
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
        // TODO: typechecking with unresolved number types
        // this is tricky, cause I should make sure that the number can be expressed as type
        case let (input, .unary(op, expression)):
            let right = try expression.checkType(
                with: .nothing(),
                localScope: localScope,
                context: context)

            switch (input, op, right.typeIdentifier) {
            case (.nothing, .plus, Builtins.i32),
                // TODO: continuation on the undefined number type, undefined numbers with - prefix will automatically become signed.
                (.nothing, .minus, Builtins.i32),
                (.nothing, .plus, Builtins.f64),
                (.nothing, .minus, Builtins.f64),
                (.nothing, .not, Builtins.bool),
                (Builtins.i32, .plus, Builtins.i32),
                (Builtins.f64, .minus, Builtins.f64),
                (Builtins.i32, .plus, Builtins.i32),
                (Builtins.f64, .minus, Builtins.f64),
                (Builtins.bool, .and, Builtins.bool),
                (Builtins.bool, .or, Builtins.bool):
                return .init(
                    expressionType: .unary(op, expression: right),
                    location: self.location,
                    typeIdentifier: right.typeIdentifier)
            default:
                throw .invalidOperation(
                    expression: self,
                    leftType: input,
                    rightType: right.typeIdentifier)
            }
        case let (.nothing, .binary(op, leftExpression, rightExpression)):
            let left = try leftExpression.checkType(
                with: input,
                localScope: localScope,
                context: context)
            let right = try rightExpression.checkType(
                with: input,
                localScope: localScope,
                context: context)
            switch (op, left.typeIdentifier, right.typeIdentifier) {
            case (.plus, Builtins.i32, Builtins.i32),
                (.minus, Builtins.i32, Builtins.i32),
                (.times, Builtins.i32, Builtins.i32),
                (.by, Builtins.i32, Builtins.i32),
                (.modulo, Builtins.i32, Builtins.i32),
                (.plus, Builtins.f64, Builtins.f64),
                (.minus, Builtins.f64, Builtins.f64),
                (.times, Builtins.f64, Builtins.f64),
                (.by, Builtins.f64, Builtins.f64):
                return .init(
                    expressionType: .binary(op, left: left, right: right),
                    location: self.location,
                    typeIdentifier: right.typeIdentifier)
            case (.and, Builtins.bool, Builtins.bool),
                (.or, Builtins.bool, Builtins.bool),
                (.equal, Builtins.i32, Builtins.i32),
                (.different, Builtins.i32, Builtins.i32),
                (.equal, Builtins.f64, Builtins.f64),
                (.different, Builtins.f64, Builtins.f64),
                (.equal, Builtins.string, Builtins.string),
                (.different, Builtins.string, Builtins.string),
                (.equal, Builtins.bool, Builtins.bool),
                (.different, Builtins.bool, Builtins.bool),
                (.lessThan, Builtins.i32, Builtins.i32),
                (.lessThanOrEqual, Builtins.i32, Builtins.i32),
                (.greaterThan, Builtins.i32, Builtins.i32),
                (.greaterThanOrEqual, Builtins.i32, Builtins.i32),
                (.lessThan, Builtins.f64, Builtins.f64),
                (.lessThanOrEqual, Builtins.f64, Builtins.f64),
                (.greaterThan, Builtins.f64, Builtins.f64),
                (.greaterThanOrEqual, Builtins.f64, Builtins.f64):
                return .init(
                    expressionType: .binary(op, left: left, right: right),
                    location: self.location,
                    typeIdentifier: Builtins.bool)
            default:
                throw .invalidOperation(
                    expression: self,
                    leftType: left.typeIdentifier,
                    rightType: right.typeIdentifier)
            }
        case (_, .binary):
            throw .inputMismatch(expression: self, expected: .nothing(), received: input)
        case let (.nothing, .unnamedTuple(expressions)):
            let typedExpressions = try expressions.map { expression throws(ExpressionSemanticError) in
                try expression.checkType(
                    with: .nothing(),
                    localScope: localScope,
                    context: context)
            }
            return .init(
                expressionType: .unnamedTuple(typedExpressions),
                location: self.location,
                typeIdentifier: .unnamedTuple(
                    .init(
                        types: typedExpressions.map { $0.typeIdentifier },
                        location: .nowhere)))
        case let (.nothing, .namedTuple(arguments)):
            let typedArguments = try arguments.map { argument throws(ExpressionSemanticError) in
                Expression.Argument(
                    name: argument.name,
                    value: try argument.value.checkType(
                        with: .nothing(), localScope: localScope, context: context),
                    location: argument.location)
            }
            let paramDefinitions = typedArguments.map { argument in
                ParamDefinition(
                    name: argument.name,
                    type: argument.value.typeIdentifier,
                    location: .nowhere)
            }

            return .init(
                expressionType: .namedTuple(typedArguments),
                location: self.location,
                typeIdentifier: .namedTuple(.init(types: paramDefinitions, location: .nowhere)))
        case (_, .namedTuple), (_, .unnamedTuple):
            throw .inputMismatch(
                expression: self,
                expected: .nothing(),
                received: input)

        case let (_, .lambda(expression)):
            throw .unsupportedYet("lambda expression")
        case let (_, .call(call)):
            let typedCall = try call.checkType(with: input, localScope: localScope, context: context)
            return .init(
                expressionType: .call(typedCall),
                location: typedCall.location,
                typeIdentifier: typedCall.typeIdentifier)
        case (_, .access(_)):
            throw .unsupportedYet("accessed fields")
        case let (.nothing, .field(field)):
            if let fieldType = localScope.fields[field] {
                return self.with(typeIdentifier: fieldType)
            } else {
                throw .fieldNotInScope(expression: self)
            }
        case (_, .field):
            throw .inputMismatch(
                expression: self,
                expected: .nothing(),
                received: input)
        case let (_, .branched(branched)):
            let typedBranched = try branched.checkType(with: input, localScope: localScope, context: context)
            return .init(
                expressionType: .branched(typedBranched),
                location: self.location,
                typeIdentifier: typedBranched.typeIdentifier)
        case let (_, .piped(leftExpression, rightExpression)):
            let typedLeftExpression = try leftExpression.checkType(
                with: input,
                localScope: localScope,
                context: context)
            let typedRightExpression = try rightExpression.checkType(
                with: typedLeftExpression.typeIdentifier,
                localScope: localScope,
                context: context)
            return .init(
                expressionType: .piped(left: typedLeftExpression, right: typedRightExpression),
                location: self.location,
                typeIdentifier: typedRightExpression.typeIdentifier)
        }
    }
}
