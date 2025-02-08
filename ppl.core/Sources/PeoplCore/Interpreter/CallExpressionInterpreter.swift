// extension Expression.Access: Evaluable {
// }


extension Expression.Call: Evaluable {
    func evaluate(
        with input: Evaluation, and scope: EvaluationScope
    ) -> Result<Evaluation, SemanticError> {
        
        let argumentsResults = self.arguments.map { argument in
            argument.value.evaluate(with: .nothing, and: scope)
        }

        let errors = argumentsResults.compactMap { result in
            if case let .failure(error) = result {
                return error
            }
            return nil
        }

        if errors.count > 0 {
            return .failure(.combine(errors: errors))
        }

        let argumentsEvaluations = argumentsResults.compactMap { result in
            try? result.get()
        }

        switch self.command {
        case let .simple(expression):
            switch expression.expressionType {
            case let .field(functionName):

                let functionDefinition = FunctionDefinition(
                    inputType: input.typeIdentifier,
                    scope: nil,
                    name: functionName,
                    params: zip(self.arguments, argumentsEvaluations).map { argument, evaluation in
                        ParamDefinition(
                            name: argument.name,
                            type: evaluation.typeIdentifier,
                            location: .nowhere)
                    },
                    outputType: .nothing,
                    body: .init(location: .nowhere, expressionType: .nothing),
                    location: .nowhere)

                if let functionBody = scope.functions[functionDefinition] {
                    return functionBody.evaluate(with: input, and: scope)
                } else {
                    // TODO: error should be function not in scope
                    return .failure(.fieldNotInScope(location: location, fieldName: functionName))
                }
            default:
                return .failure(.notImplemented(location: location, description: "non nominal callables"))
            }
        case let .type(type):
            return .failure(.notImplemented(location: location, description: "type constructors"))
        }
        return .failure(.notImplemented(location: location, description: "call expressions"))
    }
}
