
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

        // let functionsDictionary = functions.reduce(into: [:]) { accumulated, function in
        //     if 
        //     accumulated[function.name] = function
        // }
        // 
        // let main = func


        return .success(.nothing)
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

