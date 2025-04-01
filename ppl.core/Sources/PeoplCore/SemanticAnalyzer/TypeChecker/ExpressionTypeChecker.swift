// NOTE: the idea of value constraint is interesting, but I don't
// want to implement this cause it might interfere with function overloading on Int types

enum IntValueConstraint: Comparable {
    case Int8
    case UInt8
    case Int16
    case UInt16
    case Int32
    case UInt32
    case Int64
    case UInt64

    init(from value: UInt64) {
        if value >= 1<<63 {
            self = .UInt64
        } else if value >= 1<<32 {
            self = .Int64
        } else if value >= 1<<31 {
            self = .UInt32
        } else if value >= 1<<16 {
            self = .Int32
        } else if value >= 1<<15 {
            self = .UInt16
        } else if value >= 1<<8 {
            self = .Int16
        } else if value >= 1<<7 {
            self = .UInt8
        } else {
            self = .Int8
        }
    }
}

enum TypedExpressionType {
    case nothing
    case never
    case bool
    case int(constraint: IntValueConstraint)
    case float
    case string
    case nominal(TypeIdentifier)
    case unnamedTuple([TypedExpressionType])
    case namedTuple([String: TypedExpressionType])
    // case lambda TODO: implement lambdas (someday)
}

indirect enum TypedExpression {
    case nothing
    case never
    case intLiteral(value: UInt64, constraint: IntValueConstraint)
    case floatLiteral(value: Double)
    case stringLiteral(value: String)
    case boolLiteral(value: Bool)
    case unary(Operator, expression: TypedExpression, type: TypedExpressionType)
    case binary(Operator, left: TypedExpression, right: TypedExpression, type: TypedExpressionType)
    case unnamedTuple([TypedExpression], type: TypedExpressionType)
    case namedTuple([String: TypedExpression], type: TypedExpressionType)
    case lambda(TypedExpression, type: TypedExpressionType)
    case call(Expression.Call, type: TypedExpressionType)
    case access(Expression.Access, type: TypedExpressionType)
    case field(String, type: TypedExpressionType)
    case branched(Expression.Branched, type: TypedExpressionType)
    case piped(left: TypedExpression, right: TypedExpression, type: TypedExpressionType)

    var type: TypedExpressionType {
        switch self {
        case .nothing:
            return .nothing
        case .never:
            return .never
        case .intLiteral(_, let constraint):
            return .int(constraint: constraint)
        case .floatLiteral:
            return .float
        case .stringLiteral:
            return .string
        case .boolLiteral:
            return .bool
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
        with input: TypedExpressionType,
        localScope: LocalScope,
        context: borrowing SemanticContext
    ) throws(ExpressionSemanticError) -> TypedExpression
}


extension Expression: ExpressionTypeChecker {
    func checkType(
        with input: TypedExpressionType,
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
            return .intLiteral(value: value, constraint: .init(from: value))
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

            switch (input, op, right.type) {
            case (.nothing, .plus, .int),
                // TODO: continuation on the undefined number type, undefined numbers with - prefix will automatically become signed.
                (.nothing, .minus, .int),
                (.nothing, .plus, .float),
                (.nothing, .minus, .float),
                (.nothing, .not, .bool),
                (.float, .plus, .float),
                (.float, .minus, .float),
                (.bool, .and, .bool),
                (.bool, .or, .bool):
                return .unary(op, expression: right, type: right.type)
            case (.int(let leftConstraint), .plus, .int(let rightConstraint)):
                return .unary(
                    op,
                    expression: right,
                    type: .int(constraint: max(leftConstraint, rightConstraint)))
            default:
                throw .invalidOperation(
                    expression: self,
                    leftType: input,
                    rightType: right.type)
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
            switch (op, left.type, right.type) {
            case (.plus, .int(let leftConstraint), .int(let rightConstraint)),
                (.minus, .int(let leftConstraint), .int(let rightConstraint)),
                (.times, .int(let leftConstraint), .int(let rightConstraint)),
                (.by, .int(let leftConstraint), .int(let rightConstraint)),
                (.modulo, .int(let leftConstraint), .int(let rightConstraint)):
                return .binary(op, left: left, right: right, type: .int(constraint: max(leftConstraint, rightConstraint)))
            case (.plus, .float, .float),
                (.minus, .float, .float),
                (.times, .float, .float),
                (.by, .float, .float):
                return .binary(op, left: left, right: right, type: .float)
            case (.and, .bool, .bool),
                (.or, .bool, .bool),
                (.equal, .int, .int),
                (.different, .int, .int),
                (.equal, .float, .float),
                (.different, .float, .float),
                (.equal, .string, .string),
                (.different, .string, .string),
                (.equal, .bool, .bool),
                (.different, .bool, .bool),
                (.lessThan, .int, .int),
                (.lessThanOrEqual, .int, .int),
                (.greaterThan, .int, .int),
                (.greaterThanOrEqual, .int, .int),
                (.lessThan, .float, .float),
                (.lessThanOrEqual, .float, .float),
                (.greaterThan, .float, .float),
                (.greaterThanOrEqual, .float, .float):
                return .binary(op, left: left, right: right, type: .bool)
            default:
                throw .invalidOperation(
                    expression: self,
                    leftType: left.type,
                    rightType: right.type)
            }
        case (_, .binary):
            throw .inputMismatch(expression: self, expected: .nothing, received: input)
        case let (.nothing, .unnamedTuple(expressions)):
            let typedExpressions = try expressions.map { expression throws(ExpressionSemanticError) in
                try expression.checkType(
                    with: .nothing,
                    localScope: localScope,
                    context: context)
            }
            return .unnamedTuple(typedExpressions, type: .unnamedTuple(typedExpressions.map { $0.type }))
        case let (.nothing, .namedTuple(arguments)):
            let typedArguments = try arguments.map { argument throws(ExpressionSemanticError) in
                (name: argument.name, value: try argument.value.checkType(
                    with: .nothing,
                    localScope: localScope,
                    context: context))
            }.reduce(into: [:]) { partialResult, argument in // this was separated because typed Exceptions don't work properly with reduce
                partialResult[argument.name] = argument.value
            }

            return .namedTuple(typedArguments, type: .namedTuple(typedArguments.mapValues { $0.type }))
        case (_, .namedTuple), (_, .unnamedTuple):
            throw .inputMismatch(
                expression: self,
                expected: .nothing,
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
