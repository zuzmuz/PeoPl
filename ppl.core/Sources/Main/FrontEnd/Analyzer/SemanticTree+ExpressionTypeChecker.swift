extension Semantic.FunctionSignature {
    public func checkBody(
        body: Syntax.Expression,
        outputType: Semantic.TypeSpecifier,
        context: borrowing Semantic.DeclarationsContext
    ) throws(Semantic.Error) -> Semantic.Expression {
        let inputExpression: Semantic.Expression
        let localScope: [Semantic.Tag: Semantic.TypeSpecifier]

        switch self.inputType.tag {
        case .input, .unnamed:
            localScope = self.arguments
            inputExpression = .input(type: self.inputType.type)
        case .named:
            localScope = self.arguments.merging(
                [self.inputType.tag: self.inputType.type]
            ) { $1 }
            inputExpression = .input(type: .nothing)
        }

        let bodyExpression = try body.checkType(
            with: inputExpression,
            localScope: localScope,
            context: context)

        if bodyExpression.type != outputType {
            throw .init(
                location: body.location,
                errorChoice: .functionBodyOutputTypeMismatch(
                    expected: outputType, received: bodyExpression.type))
        }

        return bodyExpression
    }
}

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
            switch expression {
            case let .taggedExpression(taggedExpression):
                let expressionTag = Semantic.Tag.named(taggedExpression.tag)
                if expressions[expressionTag] != nil {
                    throw .init(
                        location: taggedExpression.location,
                        errorChoice: .duplicatedExpressionFieldName)
                }
                expressions[expressionTag] =
                    try taggedExpression.expression.checkType(
                        with: input,
                        localScope: localScope,
                        context: context)
            default:
                let expressionTag = Semantic.Tag.unnamed(fieldCounter)
                fieldCounter += 1
                // WARN: this might be buggy, I guess I should put this outside the switch
                if expressions[expressionTag] != nil {
                    throw .init(
                        location: expression.location,
                        errorChoice: .duplicatedExpressionFieldName)
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

extension Syntax.Literal {
    func checkType(
        with input: Semantic.Expression,
        localScope: borrowing Semantic.LocalScope,
        context: borrowing Semantic.DeclarationsContext,
    ) throws(Semantic.Error) -> Semantic.Expression {

        switch (input, self.value) {
        case (_, .never):
            return .never
        case (.nothing, .nothing):
            return .nothing
        case (.nothing, .intLiteral(let value)):
            return .intLiteral(value)
        case (.nothing, .floatLiteral(let value)):
            return .floatLiteral(value)
        case (.nothing, .stringLiteral(let value)):
            throw .init(
                location: self.location,
                errorChoice: .notImplemented(
                    "String literal type checking is not implemented yet"))
        // return .init(expression: .stringLiteral(value), type: .string)
        case (.nothing, .boolLiteral(let value)):
            return .boolLiteral(value)
        default:
            throw .init(
                location: self.location,
                errorChoice: .inputMismatch(
                    expected: .nothing,
                    received: input.type))
        }
    }
}

extension Syntax.Unary {
    func checkType(
        with input: Semantic.Expression,
        localScope: borrowing Semantic.LocalScope,
        context: borrowing Semantic.DeclarationsContext,
    ) throws(Semantic.Error) -> Semantic.Expression {
        // multiple consecutive unary operations are not allowed
        // because things like `+ * - exp` are allowed syntactically
        if case .unary = self.expression {
            throw .init(
                location: expression.location,
                errorChoice: .consecutiveUnary)
        }

        let typedExpression = try expression.checkType(
            with: .nothing,
            localScope: localScope,
            context: context)

        guard
            let opReturnType = context.operatorDeclarations[
                .init(left: input.type, right: typedExpression.type, op: op)]
        else {
            throw .init(
                location: expression.location,
                errorChoice: .invalidOperation(
                    leftType: input.type,
                    op: op,
                    rightType: typedExpression.type))
        }

        switch input.type {
        case .nothing:
            return .unary(op, expression: typedExpression, type: opReturnType)
        // if input is not nothing than this expression is considered a binary expression
        default:
            return .binary(
                op, left: input, right: typedExpression, type: opReturnType)
        }
    }
}

extension Syntax.Binary {
    func checkType(
        with input: Semantic.Expression,
        localScope: borrowing Semantic.LocalScope,
        context: borrowing Semantic.DeclarationsContext,
    ) throws(Semantic.Error) -> Semantic.Expression {
        let leftTyped = try self.left.checkType(
            with: .nothing,
            localScope: localScope,
            context: context)

        // FIX: this is problematic in case of an expression starting with an unary
        // this is only a error if a binary expression is nested inside another one
        if case .unary = left {
            throw .init(
                location: self.location,
                errorChoice: .consecutiveUnary)
        }

        let rightTyped = try self.right.checkType(
            with: .nothing,
            localScope: localScope,
            context: context)

        if case .unary = right {
            throw .init(
                location: self.location,
                errorChoice: .consecutiveUnary)
        }

        guard
            let opReturnType = context.operatorDeclarations[
                .init(left: leftTyped.type, right: rightTyped.type, op: op)]
        else {
            throw .init(
                location: self.location,
                errorChoice: .invalidOperation(
                    leftType: leftTyped.type,
                    op: op,
                    rightType: rightTyped.type))
        }
        return .binary(
            op, left: leftTyped, right: rightTyped, type: opReturnType)
    }
}

extension Syntax.Call {
    func checkType(
        with input: Semantic.Expression,
        localScope: borrowing Semantic.LocalScope,
        context: borrowing Semantic.DeclarationsContext,
    ) throws(Semantic.Error) -> Semantic.Expression {
        let argumentsTyped = try arguments.checkType(
            with: .nothing,
            localScope: localScope,
            context: context)

        switch self.prefix {
        case let .access(access):
            throw .init(
                location: access.location,
                errorChoice: .notImplemented(
                    "Not ready for this yet accessing field in function call"))
        case let .nominal(nominal):
            // the nominal is a type initializer
            if let typeSpecifier = context.typeDeclarations[
                nominal.identifier.getSemanticIdentifier()]
            {
                return .initializer(
                    type: typeSpecifier,
                    arguments: argumentsTyped)
            }

            let functionSignature: Semantic.FunctionSignature =
                .init(
                    identifier: nominal.identifier.getSemanticIdentifier(),
                    inputType: (tag: .input, type: input.type),
                    arguments: argumentsTyped.mapValues { $0.type })

            // the nominal is a function call
            if let functionOutputType =
                context.functionDeclarations[functionSignature]
            {
                return .call(
                    signature: functionSignature,
                    input: input,
                    arguments: argumentsTyped,
                    type: functionOutputType)
            }

            throw .init(
                location: self.location,
                errorChoice: .undefinedCall(signature: functionSignature))
        case .none:
            // literal tuple
            return .initializer(
                type: .raw(.record(argumentsTyped.mapValues { $0.type })),
                arguments: argumentsTyped
            )

        default:
            throw .init(
                location: self.location,
                errorChoice: .notImplemented(
                    "function call prefix \(String(describing: prefix)) not implemented"
                ))
        }
    }
}

extension Syntax.Branched {
    func checkType(
        with input: Semantic.Expression,
        localScope: Semantic.LocalScope,
        context: borrowing Semantic.DeclarationsContext,
    ) throws(Semantic.Error) -> Semantic.Expression {
        fatalError()
        // let branches =
        //     try self.branches.map { branch throws(Semantic.Error) in
        //         let pattern =
        //             try branch.matchExpression.getPattern(
        //                 localScope: localScope, context: context
        //             )
        //         
        //         let bindings = pattern.getBindings()
        //         if Set(bindings).count < bindings.count {
        //             throw .init(
        //                 location: branch.location,
        //                 errorChoice: .duplicateBindings)
        //         }
        //
        //
        //         let extendedLocalScope = localScope
        //
        //         let guardExpression =
        //             try branch.guardExpression?.checkType(
        //                 with: .nothing,
        //                 localScope: extendedLocalScope,
        //                 context: context)
        //             ?? .boolLiteral(true)
        //
        //         if guardExpression.type != .bool {
        //             throw .init(
        //                 location: self.location,
        //                 errorChoice: .guardShouldReturnBool(
        //                     received: guardExpression.type))
        //         }
        //
        //         let bodyExpression =
        //             try branch.body.checkType(
        //                 with: .nothing,
        //                 localScope: extendedLocalScope,
        //                 context: context)
        //
        //         return 
        //     }
        //
        // // removing duplicate types while keeping order
        // let branchesType: [Semantic.TypeSpecifier] =
        //     branches.reduce(into: []) { arr, branch in
        //         let branchType = branch.body.type
        //
        //         // Never type can be ignored
        //         if !arr.contains(branchType) && branchType != .never {
        //             arr.append(branchType)
        //         }
        //     }
        //
        // let type: Semantic.TypeSpecifier
        // if branchesType.isEmpty {
        //     type = .never
        // } else if branchesType.count == 1, let branchType = branchesType.first {
        //     type = branchType
        // } else {
        //     type = .raw(
        //         .choice(
        //             branchesType
        //                 .enumerated()
        //                 .reduce(into: [:]) { acc, element in
        //                     acc[.unnamed(UInt64(element.offset))] =
        //                         element.element
        //                 }))
        // }
        // return .branching(branches: branches, type: type)
    }

    // private static func validateExhaustiveness(
    //     input: Semantic.Expression,
    //     branches: [Semantic.Branch],
    //     context: borrowing Semantic.DeclarationsContext
    // ) throws(Semantic.Error) {
    //
    // }
}

extension Syntax.Binding {
    func checkType(
        with input: Semantic.Expression,
        localScope: borrowing Semantic.LocalScope,
        context: borrowing Semantic.DeclarationsContext,
    ) throws(Semantic.Error) -> Semantic.Expression {
        throw .init(location: self.location, errorChoice: .bindingNotAllowed)
    }
}

extension Syntax.Pipe {
    func checkType(
        with input: Semantic.Expression,
        localScope: borrowing Semantic.LocalScope,
        context: borrowing Semantic.DeclarationsContext,
    ) throws(Semantic.Error) -> Semantic.Expression {
        let leftTyped = try left.checkType(
            with: input,
            localScope: localScope,
            context: context)

        switch right {
        case let .branched(branched):
            return try branched.checkType(
                with: leftTyped,
                localScope: localScope,
                context: context)
        default:
            return try right.checkType(
                with: leftTyped,
                localScope: localScope,
                context: context)
        }
    }
}

extension Syntax.Expression {

    // func accessFieldType(
    //     type: Semantic.TypeSpecifier,
    //     fieldIdentifier: String,
    //     context: borrowing Semantic.DeclarationsContext
    // ) throws(Semantic.Error) -> Semantic.TypeSpecifier {
    //
    //     switch type {
    //     case .nothing, .never:
    //         throw .undefinedField(expression: self, field: fieldIdentifier)
    //     case .raw(let rawType):
    //         return try self.accessFieldType(
    //             rawType: rawType,
    //             fieldIdentifier: fieldIdentifier,
    //             context: context)
    //     case .nominal(let typeIdentifier):
    //         guard
    //             let rawType =
    //                 context.typeDeclarations[typeIdentifier]?
    //                 .getRawType(
    //                     typeDeclarations: context.typeDeclarations)
    //         else {
    //             throw .undefinedType(
    //                 expression: self, identifier: typeIdentifier)
    //         }
    //         return try self.accessFieldType(
    //             rawType: rawType,
    //             fieldIdentifier: fieldIdentifier,
    //             context: context)
    //     }
    // }
    //
    // func accessFieldType(
    //     rawType: Semantic.RawTypeSpecifier,
    //     fieldIdentifier: String,
    //     context: borrowing Semantic.DeclarationsContext
    // ) throws(Semantic.Error) -> Semantic.TypeSpecifier {
    //
    //     switch rawType {
    //     case let .record(record):
    //         if let accessedFieldType = record[.named(fieldIdentifier)] {
    //             return accessedFieldType
    //         }
    //
    //         if fieldIdentifier.first == "_",
    //             let unnamedTag = UInt64(fieldIdentifier.dropFirst()),
    //             let accessedFieldType = record[.unnamed(unnamedTag)]
    //         {
    //             return accessedFieldType
    //         }
    //         throw .undefinedField(expression: self, field: fieldIdentifier)
    //     default:
    //         throw .notImplemented(
    //             "Accessing field type is not implemented for \(rawType)")
    //
    //     }
    // }

    func checkType(
        with input: Semantic.Expression,
        localScope: borrowing Semantic.LocalScope,
        context: borrowing Semantic.DeclarationsContext,
    ) throws(Semantic.Error) -> Semantic.Expression {

        switch (input.type, self) {
        case let (_, .literal(literal)):
            return try literal.checkType(
                with: input,
                localScope: localScope,
                context: context)
        // Unary
        case let (_, .unary(unary)):
            return try unary.checkType(
                with: input,
                localScope: localScope,
                context: context)
        // Binary
        case let (.nothing, .binary(binary)):
            return try binary.checkType(
                with: input,
                localScope: localScope,
                context: context)
        case (_, .binary):
            throw .init(
                location: self.location,
                errorChoice: .inputMismatch(
                    expected: .nothing,
                    received: input.type))
        case let (_, .nominal(nominal)):
            if nominal.identifier.chain.count == 1,
                let field = nominal.identifier.chain.first,
                let fieldTypeInScope = localScope[.named(field)]
            {  // NOTE: named and unnamed are equivalent, but I should figure out how to switch between the two
                return .fieldInScope(tag: .named(field), type: fieldTypeInScope)
            }
            // TODO: qualified identifiers might be compile time expressions or globals
            throw .init(
                location: self.location,
                errorChoice: .notImplemented(
                    "Field expression type checking is not implemented yet"))
        // NOTE: should bindings shadow definitions in scope or context
        case let (.nothing, .access(access)):
            // let prefixTyped = try prefix.checkType(
            //     with: input,
            //     localScope: localScope,
            //     context: context)
            //
            // let accessFieldType = try self.accessFieldType(
            //     type: prefixTyped.type,
            //     fieldIdentifier: fieldIdentifier,
            //     context: context)
            throw .init(
                location: self.location,
                errorChoice: .notImplemented(
                    "access field expression type checking is not implemented yet"
                ))
        // return .init(
        //     expressionType:
        //         .access(prefix: prefixTyped, field: fieldIdentifier),
        //     type: accessFieldType)

        case (_, .access):
            throw .init(
                location: self.location,
                errorChoice: .inputMismatch(
                    expected: .nothing,
                    received: input.type))

        case let (_, .call(call)):
            return try call.checkType(
                with: input,
                localScope: localScope,
                context: context)

        case let (_, .branched(branched)):
            return try branched.checkType(
                with: input,
                localScope: localScope,
                context: context)

        case let (_, .piped(piped)):
            return try piped.checkType(
                with: input,
                localScope: localScope,
                context: context)

        case (_, .binding):
            throw .init(
                location: self.location,
                errorChoice: .bindingNotAllowed)
        case let (input, .function(function)):
            // NOTE: here I shoul infer signature if not present
            throw .init(
                location: self.location,
                errorChoice: .notImplemented(
                    "Function expression type checking is not implemented yet"))
        default:
            throw .init(
                location: self.location,
                errorChoice: .notImplemented(
                    "abstract expression type checking is not implemented yet"))

        }
        throw .init(
            location: self.location,
            errorChoice: .notImplemented(
                "Expression type checking is not implemented yet"))
    }
}
