extension Expression.Call: ExpressionTypeChecker {
    func checkType(
        with input: TypeIdentifier,
        localScope: LocalScope,
        context: borrowing SemanticContext
    ) throws(ExpressionSemanticError) -> Expression.Call {
        let functionIdentifier: FunctionIdentifier
        let callee: TypeIdentifier
        let typedCommand: Expression.Prefix
        switch self.command {
        case let .simple(expression):
            switch expression.expressionType {
            case let .field(functionName):
                functionIdentifier = FunctionIdentifier(scope: nil, name: functionName)
                callee = input
                typedCommand = self.command
            case let .access(access):
                switch access.accessed {
                case let .type(type):
                    functionIdentifier = FunctionIdentifier(scope: type, name: access.field)
                    callee = input
                    typedCommand = self.command
                case let .simple(accessedExpression):
                    let typedExpression = try accessedExpression.checkType(
                        with: input, localScope: localScope, context: context)
                    functionIdentifier = FunctionIdentifier(scope: nil, name: access.field)
                    callee = typedExpression.typeIdentifier
                    typedCommand = .simple(
                        .init(
                            expressionType: .access(
                                .init(
                                    accessed: .simple(typedExpression),
                                    field: access.field,
                                    location: access.location)),
                            location: expression.location,
                            typeIdentifier: typedExpression.typeIdentifier))
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
            throw .unsupportedYet("Type initializers")
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
        let paramDefintions = try typedArguments.map { argument throws(ExpressionSemanticError) in
            ParamDefinition(
                name: argument.name,
                type: argument.value.typeIdentifier,
                location: .nowhere)
        }

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
            params: paramDefintions,
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
                givenArguments: paramDefintions,
                inputType: callee,
                function: functionIdentifier)
        } else {
            throw .undifinedFunctionOnInput(
                call: self,
                input: callee,
                function: functionIdentifier)

        }
    }
}
