extension [Syntax.Expression] {
    /// Transforms a list of syntax expressions to a tagged list of semantic expressions.
    /// If an expression of the list is a tagged expressions,
    /// then the semantic expression is deconstructed.
    /// If the expression is untagged then an implicit tag is assigned to it, which is the index.
    /// # Params
    /// - with: the type specifier of the input expression
    /// - localScope: the local scope of the current context
    /// - context: the declarations context of the current module
    ///
    /// # Returns
    /// Dictionary of tagged expressions, where the tag is either a named tag or an unnamed tag
    ///
    /// # throws
    /// ``Semantic.Error`` if there is a duplicated expression field name or if the type checking fails
    public func checkType(
        with input: Semantic.Expression,
        localScope: borrowing Semantic.LocalScope,
        context: borrowing Semantic.DeclarationsContext
    ) throws(Semantic.Error) -> [Semantic.Tag: Semantic.Expression] {

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
        with input: Semantic.Expression,
        literal: Syntax.Expression.Literal,
        localScope: borrowing Semantic.LocalScope,
        context: borrowing Semantic.DeclarationsContext,
    ) throws(Semantic.Error) -> Semantic.Expression {

        switch (input.type, literal) {
        case (_, .never):
            return .init(expressionType: .never, type: .never)
        case (.nothing, .nothing):
            return .init(expressionType: .nothing, type: .nothing)
        case (.nothing, .intLiteral(let value)):
            return .init(expressionType: .intLiteral(value), type: .int)
        case (.nothing, .floatLiteral(let value)):
            return .init(expressionType: .floatLiteral(value), type: .float)
        case (.nothing, .stringLiteral(let value)):
            throw .notImplemented("String literal type checking is not implemented yet")
        // return .init(expression: .stringLiteral(value), type: .string)
        case (.nothing, .boolLiteral(let value)):
            return .init(expressionType: .boolLiteral(value), type: .bool)
        default:
            throw .inputMismatch(
                expression: self,
                expected: .nothing,
                received: input.type)
        }
    }

    func checkTypeUnary(
        with input: Semantic.Expression,
        op: Operator,
        expression: Syntax.Expression,
        localScope: borrowing Semantic.LocalScope,
        context: borrowing Semantic.DeclarationsContext,
    ) throws(Semantic.Error) -> Semantic.Expression {
        // multiple consecutive unary operations are not allowed
        // because things like `+ * - exp` are allowed syntactically
        if case .unary = expression.expressionType {
            throw .consecutiveUnary(expression: self)
        }

        let typedExpression = try expression.checkType(
            with: .nothing,
            localScope: localScope,
            context: context)

        guard
            let opReturnType = context.operatorDeclarations[
                .init(left: input.type, right: typedExpression.type, op: op)]
        else {
            throw .invalidOperation(
                expression: self,
                leftType: input.type,
                rightType: typedExpression.type)
        }

        switch input.type {
        case .nothing:
            return .init(
                expressionType: .unary(op, expression: typedExpression),
                type: opReturnType)
        // if input is not nothing than this expression is considered a binary expression
        default:
            return .init(
                expressionType: .binary(
                    op, left: input, right: typedExpression),
                type: opReturnType)
        }
    }

    func checkTypeBinary(
        left: Syntax.Expression,
        op: Operator,
        right: Syntax.Expression,
        localScope: borrowing Semantic.LocalScope,
        context: borrowing Semantic.DeclarationsContext,
    ) throws(Semantic.Error) -> Semantic.Expression {

        let leftTyped = try left.checkType(
            with: .init(expressionType: .nothing, type: .nothing),
            localScope: localScope,
            context: context)

        if case .unary = left.expressionType {
            throw .consecutiveUnary(expression: self)
        }

        let rightTyped = try right.checkType(
            with: .init(expressionType: .nothing, type: .nothing),
            localScope: localScope,
            context: context)

        if case .unary = right.expressionType {
            throw .consecutiveUnary(expression: self)
        }

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
            expressionType: .binary(op, left: leftTyped, right: rightTyped),
            type: opReturnType)
    }

    func checkFunctionCall(
        input: Semantic.Expression,
        prefix: Syntax.Expression,
        arguments: [Syntax.Expression],
        localScope: borrowing Semantic.LocalScope,
        context: borrowing Semantic.DeclarationsContext
    ) throws(Semantic.Error) -> Semantic.Expression {

        let argumentsTyped = try arguments.checkType(
            with: .nothing,
            localScope: localScope,
            context: context)

        switch prefix.expressionType {
        case let .access(accessPrefix, field):
            throw .notImplemented("Not ready for this yet accessing field in function call")
        case let .field(identifier):
            let functionSignature: Semantic.FunctionSignature =
                .init(
                    identifier: identifier.getSemanticIdentifier(),
                    inputType: (tag: .input, type: input.type),
                    arguments: argumentsTyped.mapValues { $0.type })
            let signature: Semantic.ExpressionSignature = .function(
                functionSignature)

            if let functionOutputType = context.valueDeclarations[signature] {
                return .init(
                    expressionType: .call(
                        signature: functionSignature,
                        input: input,
                        arguments: argumentsTyped),
                    type: functionOutputType)
            } else {
                throw .undefinedCall(expression: prefix)
            }
        default:
            throw .notImplemented("function call prefix \(prefix.expressionType) not implemented")
        }
    }

    func checkBranched(
        input: Semantic.Expression,
        branched: Syntax.Expression.Branched,
        localScope: Semantic.LocalScope,
        context: borrowing Semantic.DeclarationsContext
    ) throws(Semantic.Error) -> Semantic.Expression {
        let branches =
            try branched.branches.map { branch throws(Semantic.Error) in
                let bindingExpression =
                    try branch.matchExpression.checkBindingExpression(
                        input: input, localScope: localScope, context: context
                    )
                let extendedLocalScope =
                    localScope.merging(bindingExpression.bindings) { $1 }

                let guardExpression =
                    try branch.guardExpression?.checkType(
                        with: .nothing,
                        localScope: extendedLocalScope,
                        context: context)
                    ?? .init(
                        expressionType: .boolLiteral(true), type: .bool)

                if guardExpression.type != .bool {
                    throw .guardShouldReturnBool(expression: self)
                }

                let bodyExpression =
                    try branch.body.checkType(
                        with: .nothing,
                        localScope: extendedLocalScope,
                        context: context)

                return (
                    match: bindingExpression,
                    guard: guardExpression,
                    body: bodyExpression
                )
            }

        // removing duplicate types while keeping order
        let branchesType: [Semantic.TypeSpecifier] =
            branches.reduce(into: []) { arr, branch in
                let branchType = branch.body.type

                // Never type can be ignored
                if !arr.contains(branchType) && branchType != .never {
                    arr.append(branchType)
                }
            }

        let type: Semantic.TypeSpecifier
        if branchesType.count == 1, let branchType = branchesType.first {
            type = branchType
        } else {
            type = .raw(
                .choice(
                    branchesType
                        .enumerated()
                        .reduce(into: [:]) { acc, element in
                            acc[.unnamed(UInt64(element.offset))] =
                                element.element
                        }))
        }
        return .init(
            expressionType: .branching(branches: branches),
            type: type)
    }

    func checkBindingExpression(
        input: Semantic.Expression,
        localScope: borrowing Semantic.LocalScope,
        context: borrowing Semantic.DeclarationsContext
    ) throws(Semantic.Error) -> Semantic.BindingExpression {
        switch (input.type, self.expressionType) {
        case (.nothing, .literal(.nothing)):
            return .init(
                condition: .init(
                    expressionType: .boolLiteral(true),
                    type: .bool),
                bindings: [:])
        case (_, .literal(.nothing)):
            throw .bindingMismatch(expression: self)
        case let (_, .binding(binding)):
            return .init(
                condition: .init(
                    expressionType: .boolLiteral(true),
                    type: .bool),
                bindings: [Semantic.Tag.named(binding): input.type])
        // TODO: more complicated pattern matching
        case let (inputType, .literal(literal)):
            let literalTyped = try self.checkLiteral(
                with: .nothing,
                literal: literal,
                localScope: localScope,
                context: context)
            if inputType != literalTyped.type {
                throw .inputMismatch(
                    expression: self,
                    expected: inputType,
                    received: literalTyped.type)
            }
            return .init(
                condition: .init(
                    expressionType: .binary(
                        .equal,
                        left: input,
                        right: literalTyped),
                    type: .bool),
                bindings: [:])
        // TODO: other complex pattern matching requires expression to be an initializer expression
        default:
            throw .notImplemented("Advanced pattern matching is not implemented yet")
        }
    }

    func checkPipe(
        input: Semantic.Expression,
        left: Syntax.Expression,
        right: Syntax.Expression,
        localScope: borrowing Semantic.LocalScope,
        context: borrowing Semantic.DeclarationsContext
    ) throws(Semantic.Error) -> Semantic.Expression {
        let leftTyped = try left.checkType(
            with: input,
            localScope: localScope,
            context: context)

        switch right.expressionType {
        case let .branched(branched):
            return try self.checkBranched(
                input: leftTyped,
                branched: branched,
                localScope: localScope,
                context: context)
        default:
            return try right.checkType(
                with: leftTyped,
                localScope: localScope,
                context: context)
        }
    }

    func accessFieldType(
        type: Semantic.TypeSpecifier,
        fieldIdentifier: String,
        context: borrowing Semantic.DeclarationsContext
    ) throws(Semantic.Error) -> Semantic.TypeSpecifier {

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
    ) throws(Semantic.Error) -> Semantic.TypeSpecifier {

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
            throw .notImplemented("Accessing field type is not implemented for \(rawType)")

        }
    }

    func checkType(
        with input: Semantic.Expression,
        localScope: borrowing Semantic.LocalScope,
        context: borrowing Semantic.DeclarationsContext,
    ) throws(Semantic.Error) -> Semantic.Expression {

        switch (input.type, self.expressionType) {
        case let (_, .literal(literal)):
            return try self.checkLiteral(
                with: input,
                literal: literal,
                localScope: localScope,
                context: context)
        // Unary
        case let (_, .unary(op, expression)):
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
                received: input.type)
        case let (_, .field(identifier)):
            if identifier.chain.count == 1,
                let field = identifier.chain.first,
                let fieldTypeInScope = localScope[.named(field)]
            {  // NOTE: named and unnamed are equivalent, but I should figure out how to switch between the two
                return .init(
                    expressionType: .fieldInScope(.named(field)),
                    type: fieldTypeInScope)
            }
            throw .notImplemented("Field expression type checking is not implemented yet")
        // NOTE: should bindings shadow definitions in scope or context
        case let (.nothing, .access(prefix, fieldIdentifier)):
            let prefixTyped = try prefix.checkType(
                with: input,
                localScope: localScope,
                context: context)

            let accessFieldType = try self.accessFieldType(
                type: prefixTyped.type,
                fieldIdentifier: fieldIdentifier,
                context: context)
            throw .notImplemented("access field expression type checking is not implemented yet")
        // return .init(
        //     expressionType:
        //         .access(prefix: prefixTyped, field: fieldIdentifier),
        //     type: accessFieldType)

        case (_, .access):
            throw .inputMismatch(
                expression: self,
                expected: .nothing,
                received: input.type)

        case let (_, .call(prefix, arguments)):
            return try self.checkFunctionCall(
                input: input,
                prefix: prefix,
                arguments: arguments,
                localScope: localScope,
                context: context)

        case let (_, .branched(branched)):
            return try self.checkBranched(
                input: input,
                branched: branched,
                localScope: localScope,
                context: context)

        case let (_, .piped(left, right)):
            return try self.checkPipe(
                input: input,
                left: left,
                right: right,
                localScope: localScope,
                context: context)

        case (_, .binding):
            throw .bindingNotAllowed(expression: self)
        case let (input, .function(signature, expression)):
            // NOTE: here I shoul infer signature if not present
            throw .notImplemented(
                "Function expression type checking is not implemented yet")
        default:
            throw .notImplemented("abstract expression type checking is not implemented yet")

        }
        throw .notImplemented("Expression type checking is not implemented yet")
    }

}
