extension Syntax.Expression {
    func checkType(
        with input: Semantic.TypeSpecifier,
        localScope: borrowing Semantic.LocalScope,
        context: borrowing Semantic.DeclarationsContext,
    ) throws(SemanticError) -> Semantic.Expression {

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

        // Binary
        case (.nothing, .binary(let op, let left, let right)):
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
        case (_, .binary):
            throw .inputMismatch(
                expression: self,
                expected: .nothing,
                received: input)
        case (.nothing, .access(let prefix, let fieldIdentifier)):
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
            fatalError("Call expression type checking is not implemented yet")

        case (let input, .piped(left: let left, right: let right)):
            // TODO: join the piped expression
            fatalError("Piped expression type checking is not implemented yet")
        case let (input, .function(signature, expression)):
            // NOTE: here I shoul infer signature if not present
            fatalError("Function expression type checking is not implemented yet")
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
