extension Syntax.Expression {
    func checkType(
        with input: Semantic.TypeSpecifier,
        localScope: Semantic.LocalScope,
        context: borrowing Semantic.Context
    ) throws(ExpressionSemanticError) -> Semantic.Expression {

        switch (input, self.expressionType) {
        case (_, .literal(.never)):
            return .init(expression: .never, type: .never)
        case (.nothing, .literal(.nothing)):
            return .init(expression: .nothing, type: .nothing)
        case (.nothing, .literal(.intLiteral(let value))):
            return .init(expression: .intLiteral(value), type: .int)
        case (.nothing, .literal(.floatLiteral(let value))):
            return .init(expression: .floatLiteral(value), type: .float)
        case (.nothing, .literal(.stringLiteral(let value))):
            return .init(expression: .stringLiteral(value), type: .string)
        case (.nothing, .literal(.boolLiteral(let value))):
            return .init(expression: .boolLiteral(value), type: .bool)
        case (_, .literal):
            throw .inputMismatch(
                expression: self,
                expected: .nothing,
                received: input)
        // Unary
        case (let input, .unary(let op, let expression)):
            let typedExpression = try expression.checkType(
                with: .nothing,
                localScope: localScope,
                context: context)

            guard
                let operation = context.operators[
                    .init(left: input, right: typedExpression.type, op: op)]
            else {
                throw .invalidOperation(
                    expression: self,
                    leftType: input,
                    rightType: typedExpression.type)
            }
            return .init(
                expression: .unary(op, expression: typedExpression),
                type: operation.type)

        // Binary
        case (.nothing, .binary(let op, left: let left, right: let right)):
            let leftTyped = try left.checkType(
                with: .nothing,
                localScope: localScope,
                context: context)
            let rightTyped = try right.checkType(
                with: .nothing,
                localScope: localScope,
                context: context)

            guard
                let operation = context.operators[
                    .init(left: leftTyped.type, right: rightTyped.type, op: op)]
            else {
                throw .invalidOperation(
                    expression: self,
                    leftType: leftTyped.type,
                    rightType: rightTyped.type)
            }
            return .init(
                expression: .binary(op, left: leftTyped, right: rightTyped),
                type: operation.type)
        case (_, .binary):
            throw .inputMismatch(
                expression: self,
                expected: .nothing,
                received: input)
        case (.nothing, .access(prefix: let prefix, field: let identifier)):
            let prefixTyped = try prefix.checkType(
                with: .nothing,
                localScope: localScope,
                context: context)

            // TODO: recursively detect record type
            switch prefixTyped.type {
            case .nominal(let typeIdentifier):
                // guard let typeSpecifier = context.typeDefinitions[typeIdentifier],
                //     let fieldType = typeSpecifier.type. else {
                //     throw .undefinedType(
                //         expression: self,
                //         identifier: typeIdentifier)
                // }
                fatalError()
            case .record(let fields):
                guard let fieldType = fields[identifier] else {
                    throw .undefinedField(expression: self, field: identifier)
                }
                return .init(
                    expression: .access(prefix: prefixTyped, field: identifier),
                    type: fieldType)
            default:
                throw .unsupportedYet("accessing fields on unsupported type")
            }

        case (_, .access):
            throw .inputMismatch(
                expression: self,
                expected: .nothing,
                received: input)
        case (let input, .call(prefix: let prefix, arguments: let arguments)):
            
        
        case (let input, .piped(left: let left, right: let right)):
            let leftTyped = try left.checkType(
                with: input,
                localScope: localScope,
                context: context)
            let rightTyped = try right.checkType(
                with: leftTyped.type,
                localScope: localScope,
                context: context)
            // TODO: join the piped expression
            fatalError()
        default:
            fatalError()
        }
        throw .unsupportedYet("Expression type checking is not implemented yet")
    }
}
