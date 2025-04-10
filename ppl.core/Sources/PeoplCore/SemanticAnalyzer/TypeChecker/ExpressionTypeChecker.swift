enum TypedCallable {
    case function(FunctionDefinition, arguments: [TypedArgument])
    case typeInitialization(TypeDefinition, arguments: [TypedArgument])

    var arguments: [TypedArgument] {
        switch self {
        case let .function(_, arguments):
            return arguments
        case let .typeInitialization(_, arguments):
            return arguments
        }
    }
}

typealias TypedArgument = (name: String, value: TypedExpression)

indirect enum TypedExpression {
    case nothing
    case never
    case intLiteral(value: UInt64)
    case floatLiteral(value: Double)
    case stringLiteral(value: String)
    case boolLiteral(value: Bool)
    case unary(Operator, expression: TypedExpression, type: TypeIdentifier)
    case binary(Operator, left: TypedExpression, right: TypedExpression, type: TypeIdentifier)
    case unnamedTuple([TypedExpression], type: TypeIdentifier)
    case namedTuple([TypedArgument], type: TypeIdentifier)
    case lambda(TypedExpression, type: TypeIdentifier)
    case call(TypedCallable, type: TypeIdentifier)
    case access(Expression.Access, type: TypeIdentifier)
    case field(String, type: TypeIdentifier)
    case branched(Expression.Branched, type: TypeIdentifier)
    case piped(left: TypedExpression, right: TypedExpression, type: TypeIdentifier)

    var type: TypeIdentifier {
        switch self {
        case .nothing:
            return .nothing
        case .never:
            return .never
        case .intLiteral:
            return Builtins.i64
        case .floatLiteral:
            return Builtins.f64
        case .stringLiteral:
            return Builtins.string
        case .boolLiteral:
            return Builtins.bool
        case .unary(_, _, let type),
            .binary(_, _, _, let type),
            .unnamedTuple(_, let type),
            .namedTuple(_, let type),
            .lambda(_, let type), // WARN: this might not be correct
            .call(_, let type),
            .access(_, let type),
            .field(_, let type),
            .branched(_, let type),
            .piped(_, _, let type):
            return type
        }
    }
}



protocol ExpressionTypeChecker {
    func checkType(
        with input: TypeIdentifier,
        localScope: LocalScope,
        context: borrowing SemanticContext
    ) throws(ExpressionSemanticError) -> TypedExpression
}


extension Expression: ExpressionTypeChecker {
    func checkType(
        with input: TypeIdentifier,
        localScope: LocalScope,
        context: borrowing SemanticContext
    ) throws(ExpressionSemanticError) -> TypedExpression {

        switch (input, self.expressionType) {
        // Never
        case (_, .never), (.never, _):
            throw .reachedNever(expression: self)
        //Nothing
        case (.nothing, .nothing):
            return .nothing
        // NOTE: think of generic int type for automatic inference
        // Literals
        case (.nothing, .intLiteral(let value)):
            // NOTE: consider undefined number type (with resetriction),
            // for example 10 can be an I8, I16 .. but also U8 ...
            // however 300 can not be I8, interesting logic
            return .intLiteral(value: value)
        case (.nothing, .floatLiteral(let value)):
            return .floatLiteral(value: value)
        case (.nothing, .stringLiteral(let value)):
            return .stringLiteral(value: value)
        case (.nothing, .boolLiteral(let value)):
            return .boolLiteral(value: value)
        case (_, .nothing),
            (_, .intLiteral),
            (_, .floatLiteral),
            (_, .stringLiteral),
            (_, .boolLiteral):
            throw .inputMismatch(
                expression: self,
                expected: .nothing,
                received: input)

        // Unary
        // TODO: consider operator overload
        // TODO: typechecking with unresolved number types
        // this is tricky, cause I should make sure that the number can be expressed as type
        case let (input, .unary(op, expression)):
            let right = try expression.checkType(
                with: .nothing,
                localScope: localScope,
                context: context)

            let operationDefinition = OperatorOverloadDefinition(
                left: input,
                op: op,
                right: right.type,
                outputType: .nothing,
                body: .empty,
                location: .nowhere)
            if let operation = context.operators[operationDefinition] {
                return .unary(op, expression: right, type: operation.outputType)
            } else {
                throw .invalidOperation(
                    expression: expression,
                    leftType: input, 
                    rightType: right.type)
            }
        case let (.nothing, .binary(op, leftExpression, rightExpression)):
            let left = try leftExpression.checkType(
                with: .nothing,
                localScope: localScope,
                context: context)
            let right = try rightExpression.checkType(
                with: .nothing,
                localScope: localScope,
                context: context)

            let operationDefinition = OperatorOverloadDefinition(
                left: left.type,
                op: op,
                right: right.type,
                outputType: .nothing,
                body: .empty,
                location: .nowhere)
            if let operation = context.operators[operationDefinition] {
                return .binary(op, left: left, right: right, type: operation.outputType)
            } else {
                throw .invalidOperation(
                    expression: self,
                    leftType: left.type,
                    rightType: right.type)
            }
        case (_, .binary):
            throw .inputMismatch(
                expression: self,
                expected: .nothing,
                received: input)
        case let (.nothing, .unnamedTuple(expressions)):
            let typedExpressions = try expressions.map { expression throws(ExpressionSemanticError) in
                try expression.checkType(
                    with: .nothing,
                    localScope: localScope,
                    context: context)
            }
            return .unnamedTuple(
                typedExpressions,
                type: .unnamedTuple(.init(types: typedExpressions.map { $0.type })))
        case let (.nothing, .namedTuple(arguments)):
            let typedArguments = try arguments.map { argument throws(ExpressionSemanticError) in
                (name: argument.name, value: try argument.value.checkType(
                    with: .nothing,
                    localScope: localScope,
                    context: context))
            }
            return .namedTuple(
                typedArguments,
                type: .namedTuple(
                    .init(
                        types: typedArguments.map { name, value in
                            ParamDefinition(name: name, type: value.type, location: .nowhere)
                        })))
        case (_, .namedTuple), (_, .unnamedTuple):
            throw .inputMismatch(
                expression: self,
                expected: .nothing,
                received: input)
        case let (_, .lambda(expression)):
            throw .unsupportedYet("lambda expression")
        case let (_, .call(call)):
            return try call.checkType(with: input, localScope: localScope, context: context)
        case (_, .access(_)):
            throw .unsupportedYet("accessed fields")
        case let (.nothing, .field(field)):
            if let fieldType = localScope.fields[field] {
                return .field(field, type: fieldType)
            } else {
                throw .fieldNotInScope(expression: self)
            }
        case (_, .field):
            throw .inputMismatch(
                expression: self,
                expected: .nothing,
                received: input)
        case let (_, .branched(branched)):
            return try branched.checkType(with: input, localScope: localScope, context: context)
        case let (_, .piped(leftExpression, rightExpression)):
            let typedLeftExpression = try leftExpression.checkType(
                with: input,
                localScope: localScope,
                context: context)
            let typedRightExpression = try rightExpression.checkType(
                with: typedLeftExpression.type,
                localScope: localScope,
                context: context)
            return .piped(left: typedLeftExpression, right: typedRightExpression, type: typedRightExpression.type)
        }
    }
}
