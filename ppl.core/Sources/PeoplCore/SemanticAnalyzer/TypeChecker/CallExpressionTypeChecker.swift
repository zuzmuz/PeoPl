extension Expression.Call: ExpressionTypeChecker {

    enum Callable {
        case function(
            identifier: FunctionIdentifier,
            input: TypeIdentifier,
            typedCommand: Expression.Prefix)
        case type(
            name: NominalType,
            typedCommand: Expression.Prefix)
    }

    func checkType(
        with input: TypeIdentifier,
        localScope: LocalScope,
        context: borrowing SemanticContext
    ) throws(ExpressionSemanticError) -> Expression.Call {
        let callable: Callable
        switch self.command {
        case let .simple(expression):
            switch expression.expressionType {
            case let .field(functionName):
                callable = .function(
                    identifier: FunctionIdentifier(scope: nil, name: functionName),
                    input: input,
                    typedCommand: self.command)
            case let .access(access):
                switch access.accessed {
                case let .type(type):
                    callable = .function(
                        identifier: FunctionIdentifier(scope: type, name: access.field),
                        input: input,
                        typedCommand: self.command)
                case let .simple(accessedExpression):
                    let typedExpression = try accessedExpression.checkType(
                        with: input, localScope: localScope, context: context)

                    callable = .function(
                        identifier: FunctionIdentifier(scope: nil, name: access.field),
                        input: typedExpression.typeIdentifier,
                        typedCommand: .simple(
                        .init(
                            expressionType: .access(
                                .init(
                                    accessed: .simple(typedExpression),
                                    field: access.field,
                                    location: access.location)),
                            location: expression.location,
                            typeIdentifier: typedExpression.typeIdentifier)))
                }
            case let .lambda(lambda):
                throw .unsupportedYet("Direct lambda calls")
            default:
                throw .callingUncallable(
                    expression: expression,
                    type: try expression.checkType(
                        with: input, localScope: localScope, context: context).typeIdentifier
                )
            }
        case let .type(type):
            callable = .type(name: type, typedCommand: self.command)
        }
        
        let typedArguments = try self.arguments.map { argument throws(ExpressionSemanticError) in
            Expression.Argument(
                name: argument.name,
                value: try argument.value.checkType(
                    with: .nothing(),
                    localScope: localScope,
                    context: context),
                location: argument.location)
        }
        let paramDefinitions = try typedArguments.map { argument throws(ExpressionSemanticError) in
            ParamDefinition(
                name: argument.name,
                type: argument.value.typeIdentifier,
                location: .nowhere)
        }

        return switch callable {
        case let .function(functionIdentifier, callee, typedCommand):
            try self.typeCheckFunctionCall(
                functionIdentifier: functionIdentifier,
                callee: callee,
                typedCommand: typedCommand,
                paramDefinitions: paramDefinitions,
                typedArguments: typedArguments,
                localScope: localScope,
                context: context)
        case let .type(nominalType, typedCommand):
            try self.typeCheckTypeInitializer(
                nominalType: nominalType,
                typedCommand: typedCommand,
                paramDefinitions: paramDefinitions,
                typedArguments: typedArguments,
                localScope: localScope,
                context: context)
        }
    }

    private func typeCheckFunctionCall(
        functionIdentifier: FunctionIdentifier,
        callee: TypeIdentifier,
        typedCommand: Expression.Prefix,
        paramDefinitions: [ParamDefinition],
        typedArguments: [Expression.Argument],
        localScope: LocalScope,
        context: borrowing SemanticContext
    ) throws(ExpressionSemanticError) -> Self {
        if functionIdentifier.scope == nil, 
            let localFunction = localScope.fields[functionIdentifier.name],
            case let .lambda(lambda) = localFunction
        { // might be calling a local lambda
            // TODO: implement lambda call type checking
            throw .unsupportedYet("Calling a lambda")
        }

        let functionDefinition = FunctionDefinition(
            inputType: callee,
            functionIdentifier: functionIdentifier,
            params: paramDefinitions,
            outputType: .nothing(),
            body: .empty,
            location: .nowhere)

        if let function = context.functions[functionDefinition] {
            // return function.outputType
            return .init(
                command: typedCommand,
                arguments: typedArguments,
                location: self.location,
                typeIdentifier: function.outputType)
        }

        // Handling different errors

        guard let functionsWithSameIdentifier = context.functionsIdentifiers[functionIdentifier],
            functionsWithSameIdentifier.count > 0 else 
        {
            throw .undifienedFunction(call: self, function: functionIdentifier)
        }

        if let inputTypeFunctions = context.functionsInputTypeIdentifiers[callee] {
            let validFunctionsForInput = inputTypeFunctions.filter { 
                $0.functionIdentifier == functionDefinition.functionIdentifier
            }

            if validFunctionsForInput.count == 0 {
                throw .undifinedFunctionOnInput(
                    call: self,
                    input: callee,
                    function: functionDefinition.functionIdentifier
                )
            }

            throw .argumentMismatch(
                call: self,
                givenArguments: paramDefinitions,
                inputType: callee,
                function: functionIdentifier)
        } else {
            throw .undifinedFunctionOnInput(
                call: self,
                input: callee,
                function: functionIdentifier)

        }
    }

    private func typeCheckTypeInitializer(
        nominalType: NominalType,
        typedCommand: Expression.Prefix,
        paramDefinitions: [ParamDefinition],
        typedArguments: [Expression.Argument],
        localScope: LocalScope,
        context: SemanticContext
    ) throws(ExpressionSemanticError) -> Self {

        return self
    }
}
