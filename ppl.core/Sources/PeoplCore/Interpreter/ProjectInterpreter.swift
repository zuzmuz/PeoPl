
extension Project: Evaluable {
    func evaluate(
        with input: Evaluation, and scope: EvaluationScope
    ) -> Result<Evaluation, SemanticError> {

        let functions = self.modules.flatMap { (name, module) in
            module.statements.compactMap { statement in
                if case let .functionDefinition(function) = statement { 
                    return function
                }
                return nil
            }
        }

        let functionsDictionary = functions.reduce(into: [:]) { accumulated, function in
            accumulated[function] = (accumulated[function] ?? []) + [function.location]
        }

        let duplicates = functionsDictionary.filter { $1.count > 1 }

        if duplicates.count > 0 {
            return .failure(.duplicateDefinitions(locations: duplicates.flatMap { key, value in
                value
            }))
        }
        
        // TODO: maybe should consider pattern matching on input and scope
        let main = functionsDictionary.filter { key, value in key.name == "main" }

        guard let main = main.first?.key else {
            return .failure(.mainFunctionNotFound)
        }

        let modifiedScope = EvaluationScope(
            locals: scope.locals, 
            functions: scope.functions.merging(functionsDictionary.reduce(into: [:]) { acc, function in 
                acc[function.key] = function.key.body
            }, uniquingKeysWith: { $1 })
        )

        return main.body.evaluate(with: input, and: modifiedScope)
    }
}


extension Module: Evaluable {
    func evaluate(
        with input: Evaluation, and scope: EvaluationScope
    ) -> Result<Evaluation, SemanticError> {
        let main = self.statements.filter { statement in
            if case let .functionDefinition(functionDefinition) = statement {
                return functionDefinition.name == "main"
            }
            return false
        }
        guard main.count == 1, let main = main.first, case let .functionDefinition(main) = main else {
            return .failure(.mainFunctionNotFound)
        }
        return main.body.evaluate(with: input, and: scope)
    }
}

