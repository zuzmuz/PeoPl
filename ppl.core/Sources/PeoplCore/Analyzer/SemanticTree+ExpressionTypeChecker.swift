extension [Syntax.Expression] {
    func checkType(
        with input: Semantic.TypeSpecifier,
        localScope: borrowing Semantic.LocalScope,
        context: borrowing Semantic.DeclarationsContext
    ) throws(SemanticError) -> [Semantic.Tag: Semantic.Expression] {
        var expressions: [Semantic.Tag: Semantic.Expression] = [:]
        var fieldCounter = UInt64(0)
        for expression in self {
            switch expression.expressionType {
            case let .taggedExpression(taggedExpression):
                let expressionTag = Semantic.Tag.named(taggedExpression.tag)
                if expressions[expressionTag] != nil {
                    throw .duplicatedExpressionFieldName(expression: expression)
                }
                expressions[expressionTag] =
                    try taggedExpression.expression.checkType(
                        with: input,
                        localScope: localScope,
                        context: context)
            default:
                let expressionTag = Semantic.Tag.unnamed(fieldCounter)
                fieldCounter += 1
                if expressions[expressionTag] != nil {
                    throw .duplicatedExpressionFieldName(expression: expression)
                }
                expressions[expressionTag] =
                    try expression.checkType(
                        with: input,
                        localScope: localScope,
                        context: context)
            }
        }
        return expressions
    }
}

extension Syntax.Expression {

    func checkLiteral(
        with input: Semantic.TypeSpecifier,
        literal: Syntax.Expression.Literal,
        localScope: borrowing Semantic.LocalScope,
        context: borrowing Semantic.DeclarationsContext,
    ) throws(SemanticError) -> Semantic.Expression {

        switch (input, literal) {
        case (_, .never):
            return .init(expression: .never, type: .never)
        case (.nothing, .nothing):
            return .init(expression: .nothing, type: .nothing)
        case (.nothing, .intLiteral(let value)):
            return .init(expression: .intLiteral(value), type: .int)
        case (.nothing, .floatLiteral(let value)):
            return .init(expression: .floatLiteral(value), type: .float)
        case (.nothing, .stringLiteral(let value)):
            fatalError("String literal type checking is not implemented yet")
        // return .init(expression: .stringLiteral(value), type: .string)
        case (.nothing, .boolLiteral(let value)):
            return .init(expression: .boolLiteral(value), type: .bool)
        default:
            throw .inputMismatch(
                expression: self,
                expected: .nothing,
                received: input)
        }
    }

    func checkTypeUnary(
        with input: Semantic.TypeSpecifier,
        op: Operator,
        expression: Syntax.Expression,
        localScope: borrowing Semantic.LocalScope,
        context: borrowing Semantic.DeclarationsContext,
    ) throws(SemanticError) -> Semantic.Expression {
        let typedExpression = try expression.checkType(
            with: .nothing,
            localScope: localScope,
            context: context)

        guard
            let opReturnType = context.operatorDeclarations[
                .init(left: input, right: typedExpression.type, op: op)]
        else {
            throw .invalidOperation(
                expression: self,
                leftType: input,
                rightType: typedExpression.type)
        }
        return .init(
            expression: .unary(op, expression: typedExpression),
            type: opReturnType)
    }

    func checkTypeBinary(
        left: Syntax.Expression,
        op: Operator,
        right: Syntax.Expression,
        localScope: borrowing Semantic.LocalScope,
        context: borrowing Semantic.DeclarationsContext,
    ) throws(SemanticError) -> Semantic.Expression {

        let leftTyped = try left.checkType(
            with: .nothing,
            localScope: localScope,
            context: context)
        let rightTyped = try right.checkType(
            with: .nothing,
            localScope: localScope,
            context: context)

        guard
            let opReturnType = context.operatorDeclarations[
                .init(left: leftTyped.type, right: rightTyped.type, op: op)]
        else {
            throw .invalidOperation(
                expression: self,
                leftType: leftTyped.type,
                rightType: rightTyped.type)
        }
        return .init(
            expression: .binary(op, left: leftTyped, right: rightTyped),
            type: opReturnType)
    }

    func checkFunctionCall(
        input: Semantic.TypeSpecifier,
        prefix: Syntax.Expression,
        arguments: [Syntax.Expression],
        localScope: borrowing Semantic.LocalScope,
        context: borrowing Semantic.DeclarationsContext
    ) throws(SemanticError) -> Semantic.Expression {

        let argumentsTyped = try arguments.checkType(
            with: input,
            localScope: localScope,
            context: context)
        switch prefix.expressionType {
        case let .access(accessPrefix, field):
            fatalError()
        case let .field(identifier):
            if let function =
                context.valueDeclarations[
                    .function(
                        .init(
                            identifier: identifier.getSemanticIdentifier(),
                            inputType: input,
                            arguments: argumentsTyped.mapValues { $0.type }))]
            {
            }
            fatalError()
        default:
            fatalError("Not implemented")
        }
    }

    func checkType(
        with input: Semantic.TypeSpecifier,
        localScope: borrowing Semantic.LocalScope,
        context: borrowing Semantic.DeclarationsContext,
    ) throws(SemanticError) -> Semantic.Expression {

        switch (input, self.expressionType) {
        case let (input, .literal(literal)):
            return try self.checkLiteral(
                with: input,
                literal: literal,
                localScope: localScope,
                context: context)
        // Unary
        case let (input, .unary(op, expression)):
            return try self.checkTypeUnary(
                with: input,
                op: op,
                expression: expression,
                localScope: localScope,
                context: context)
        // Binary
        case (.nothing, .binary(let op, let left, let right)):
            return try self.checkTypeBinary(
                left: left,
                op: op,
                right: right,
                localScope: localScope,
                context: context)
        case (_, .binary):
            throw .inputMismatch(
                expression: self,
                expected: .nothing,
                received: input)
        case let (input, .field(identifier)):
            if identifier.chain.count == 1,
                let field = identifier.chain.first,
                let fieldTypeInScope = localScope.scope[.named(field)]
            {
                return .init(
                    expression: .fieldInScope(.named(field)),
                    type: fieldTypeInScope)
            }
            if let value = context.valueDeclarations[
                .value(identifier.getSemanticIdentifier())]
            {
                fatalError(
                    "Not sure what to do here, this is a global static const")
            }
            fatalError("Field expression type checking is not implemented yet")
        // NOTE: should bindings shadow definitions in scope or context
        case let (.nothing, .access(prefix, fieldIdentifier)):
            let prefixTyped = try prefix.checkType(
                with: .nothing,
                localScope: localScope,
                context: context)

            let accessFieldType = try self.accessFieldType(
                type: prefixTyped.type,
                fieldIdentifier: fieldIdentifier,
                context: context)
            return .init(
                expression:
                    .access(prefix: prefixTyped, field: fieldIdentifier),
                type: accessFieldType)

        case (_, .access):
            throw .inputMismatch(
                expression: self,
                expected: .nothing,
                received: input)

        case let (input, .call(prefix, arguments)):
            return try self.checkFunctionCall(
                input: input,
                prefix: prefix,
                arguments: arguments,
                localScope: localScope,
                context: context)

        // fatalError("Call expression type checking is not implemented yet")

        case (let input, .piped(left: let left, right: let right)):
            // TODO: join the piped expression
            fatalError("Piped expression type checking is not implemented yet")
        case let (input, .function(signature, expression)):
            // NOTE: here I shoul infer signature if not present
            fatalError(
                "Function expression type checking is not implemented yet")
        default:
            fatalError()
        }
        throw .unsupportedYet("Expression type checking is not implemented yet")
    }

    func accessFieldType(
        type: Semantic.TypeSpecifier,
        fieldIdentifier: String,
        context: borrowing Semantic.DeclarationsContext
    ) throws(SemanticError) -> Semantic.TypeSpecifier {

        switch type {
        case .nothing, .never:
            throw .undefinedField(expression: self, field: fieldIdentifier)
        case .raw(let rawType):
            return try self.accessFieldType(
                rawType: rawType,
                fieldIdentifier: fieldIdentifier,
                context: context)
        case .nominal(let typeIdentifier):
            guard
                let rawType =
                    context.typeDeclarations[typeIdentifier]?
                    .getRawType(
                        typeDeclarations: context.typeDeclarations)
            else {
                throw .undefinedType(
                    expression: self, identifier: typeIdentifier)
            }
            return try self.accessFieldType(
                rawType: rawType,
                fieldIdentifier: fieldIdentifier,
                context: context)
        }
    }

    func accessFieldType(
        rawType: Semantic.RawTypeSpecifier,
        fieldIdentifier: String,
        context: borrowing Semantic.DeclarationsContext
    ) throws(SemanticError) -> Semantic.TypeSpecifier {

        switch rawType {
        case let .record(record):
            if let accessedFieldType = record[.named(fieldIdentifier)] {
                return accessedFieldType
            }

            if fieldIdentifier.first == "_",
                let unnamedTag = UInt64(fieldIdentifier.dropFirst()),
                let accessedFieldType = record[.unnamed(unnamedTag)]
            {
                return accessedFieldType
            }
            throw .undefinedField(expression: self, field: fieldIdentifier)
        default:
            fatalError("Accessing field type is not implemented for \(rawType)")

        }
    }

}
