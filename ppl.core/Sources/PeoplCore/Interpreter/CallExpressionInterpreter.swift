// extension Expression.Access: Evaluable {
//     func evaluate(
//         with input: Evaluation, and scope: EvaluationScope
//     ) -> Result<Evaluation, RuntimeError> {
//         
//     }
// }


extension Expression.Call: Evaluable {
    private func evaluateFunction(
        inputType: TypeIdentifier,
        scope namespace: NominalType?,
        name functionName: String,
        with input: Evaluation,
        and scope: EvaluationScope,
        argumentsEvaluations: [Evaluation]
    ) -> Result<Evaluation, RuntimeError> {

        let functionDefinition = FunctionDefinition(
            inputType: inputType,
            scope: namespace,
            name: functionName,
            params: zip(self.arguments, argumentsEvaluations).map { argument, evaluation in
                ParamDefinition(
                    name: argument.name,
                    type: evaluation.typeIdentifier,
                    location: .nowhere)
            },
            outputType: .nothing(location: .nowhere),
            body: .init(location: .nowhere, expressionType: .nothing),
            location: .nowhere)

        if let functionBody = scope.functions[functionDefinition] {
            var scope = scope
            scope.locals = zip(
                self.arguments, argumentsEvaluations
            ).reduce(into: [:]) { acc, evaluation in
                acc[evaluation.0.name] = evaluation.1
            }
            return functionBody.evaluate(with: input, and: scope)
        }
        return .failure(.fieldNotInScope(location: location, fieldName: functionName))
    }

    func evaluate(
        with input: Evaluation, and scope: EvaluationScope
    ) -> Result<Evaluation, RuntimeError> {
        
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
                return evaluateFunction(
                    inputType: input.typeIdentifier,
                    scope: nil,
                    name: functionName,
                    with: input,
                    and: scope,
                    argumentsEvaluations: argumentsEvaluations)
            case let .access(access):
                let callee: Evaluation
                switch access.accessed  {
                case let .simple(expression):
                    let result = expression.evaluate(with: input, and: scope)
                    if case let .success(evaluation) = result {
                        callee = evaluation
                    } else {
                        return result
                    }
                case let .type(type):
                    return .failure(.notImplemented(location: location, description: "constants"))
                }

                return evaluateFunction(
                    inputType: callee.typeIdentifier,
                    scope: nil,
                    name: access.field,
                    with: callee,
                    and: scope,
                    argumentsEvaluations: argumentsEvaluations)
            default:
                return .failure(.notImplemented(location: location, description: "non nominal callables"))
            }
        case let .type(type):
            return .failure(.notImplemented(location: location, description: "type constructors"))
        }
    }
}
