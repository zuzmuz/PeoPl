extension Expression.Call: TypeChecker {
    func checkType(
        with input: TypeIdentifier,
        localScope: LocalScope,
        context: borrowing TypeCheckerContext
    ) throws(ExpressionSemanticError) -> TypeIdentifier {
        let functionIdentifier: FunctionIdentifier
        let calleeInputType: TypeIdentifier
        switch self.command {
        case let .simple(expression):
            switch expression.expressionType {
            case let .field(functionName):
                functionIdentifier = FunctionIdentifier(scope: nil, name: functionName)
                calleeInputType = input
            case let .access(access):
                switch access.accessed {
                case let .type(type):
                    functionIdentifier = FunctionIdentifier(scope: type, name: access.field)
                    calleeInputType = input
                case let .simple(expression):
                    calleeInputType = try expression.checkType(
                        with: input, localScope: localScope, context: context)
                    functionIdentifier = FunctionIdentifier(scope: nil, name: access.field)
                }
            case let .lambda(lambda):
                throw .unsupportedYet("Direct lambda calls")
            default:
                throw .callingUncallable(
                    expression: expression,
                    type: try expression.checkType(
                        with: input, localScope: localScope, context: context)
                )
            }
        case let .type(type):
            throw .unsupportedYet("Type initializers")
        }
        
        
        let argumentsTypes = try self.arguments.map { argument throws(ExpressionSemanticError) in
            ParamDefinition(
                name: argument.name,
                type: try argument.value.checkType(
                    with: .nothing(),
                    localScope: localScope,
                    context: context),
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
            inputType: calleeInputType,
            functionIdentifier: functionIdentifier,
            params: argumentsTypes,
            outputType: .nothing(),
            body: .empty,
            location: .nowhere)

        if let function = context.functions[functionDefinition] {
            return function.outputType
        }

        // Handling different errors

        guard let functionsWithSameIdentifier = context.functionsIdentifiers[functionIdentifier],
            functionsWithSameIdentifier.count > 0 else 
        {
            throw .undifienedFunction(call: self, function: functionIdentifier)
        }

        if let inputTypeFunctions = context.functionsInputTypeIdentifiers[calleeInputType] {
            let validFunctionsForInput = inputTypeFunctions.filter { 
                $0.functionIdentifier == functionDefinition.functionIdentifier
            }

            if validFunctionsForInput.count == 0 {
                throw .undifinedFunctionOnInput(
                    call: self,
                    input: calleeInputType,
                    function: functionDefinition.functionIdentifier
                )
            }

            throw .argumentMismatch(
                call: self,
                givenArguments: argumentsTypes,
                inputType: calleeInputType,
                function: functionIdentifier)
        } else {
            throw .undifinedFunctionOnInput(
                call: self,
                input: calleeInputType,
                function: functionIdentifier)

        }
    }
}
