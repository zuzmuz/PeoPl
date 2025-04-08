struct LocalScope {
    let fields: [String: TypeIdentifier]
}

/// Contains the semantic context of a module
struct SemanticContext {
    let types: [NominalType: TypeDefinition]
    let functions: [FunctionDefinition: FunctionDefinition]
    let functionsIdentifiers: [FunctionIdentifier: [FunctionDefinition]]
    let functionsInputTypeIdentifiers: [TypeIdentifier: [FunctionDefinition]]
    let operators: [OperatorOverloadDefinition: OperatorOverloadDefinition]

    static let empty = SemanticContext(
        types: [:],
        functions: [:],
        functionsIdentifiers: [:],
        functionsInputTypeIdentifiers: [:],
        operators: [:]
    )
}

enum SemanticAnalysisResult {
    case context(SemanticContext)
    case errors([SemanticError])

    func get() throws -> SemanticContext {
        switch self {
        case let .context(context):
            return context
        case let .errors(errors):
            throw errors
        }
    }
}

protocol SemanticAnalyzer: TypeDeclarationChecker, FunctionDeclarationChecker {
    func semanticCheck() -> SemanticAnalysisResult
}

extension SemanticAnalyzer {
    func semanticCheck() -> SemanticAnalysisResult {

        let builtins = Builtins.getBuiltinContext()
        let (typesDefinitions, typeErrors) = self.resolveTypeDefinitions(builtins: builtins)

        let (
            functions,
            functionsIdentifiers,
            functionsInputTypeIdentifiers,
            operators,
            functionErrors
        ) = self.resolveFunctionDefinitions(
            typesDefinitions: typesDefinitions,
            builtins: builtins)

        let semanticContext = SemanticContext(
            types: typesDefinitions,
            functions: functions,
            functionsIdentifiers: functionsIdentifiers,
            functionsInputTypeIdentifiers: functionsInputTypeIdentifiers,
            operators: operators)

        // NOTE: this might be handy when generating IR. function bodies that didn't change don't need regeneration
        let checkedFunctions = functions.mapValues { definition -> Result<FunctionDefinition, ExpressionSemanticError> in
            do throws(ExpressionSemanticError) {
                guard let bodyWithInferredType = try definition.body?.checkType(
                    with: definition.inputType,
                    localScope: LocalScope(
                        fields: definition.params.reduce(into: [:]) { $0[$1.name] = $1.type }
                    ),
                    context: semanticContext
                ) else { return .failure(.emptyFunctionBody(functionDefinition: definition)) }
                // WARN: currently returning error for empty bodies,
                // should handle template methods for contracts or interfaces
                if bodyWithInferredType.typeIdentifier != definition.outputType {
                    return .failure(.returnTypeMismatch(
                        functionDefinition: definition,
                        expectedReturnType: definition.outputType,
                        receivedType: bodyWithInferredType.typeIdentifier))
                } else {
                    return .success(.init(
                        inputType: definition.inputType,
                        functionIdentifier: definition.functionIdentifier,
                        params: definition.params,
                        outputType: definition.outputType,
                        body: bodyWithInferredType,
                        location: definition.location))
                }
            } catch {
                return .failure(error)
            }
        }

        let functionBodyErrors = checkedFunctions.compactMap { _, result in
            if case let .failure(error) = result {
                return error
            } else {
                return nil
            }
        }
        let allErrors = typeErrors.map { SemanticError.type($0) } +
                        functionErrors.map { SemanticError.function($0) } +
                        functionBodyErrors.map { SemanticError.expression($0) }

        if allErrors.count > 0 {
            return .errors(allErrors)
        }

        let verifiedFunctions = checkedFunctions.mapValues { result -> FunctionDefinition in
            return try! result.get()
        }

        // TODO: type checking for operators also
        return .context(
            SemanticContext(
                types: typesDefinitions,
                functions: verifiedFunctions,
                functionsIdentifiers: functionsIdentifiers,
                functionsInputTypeIdentifiers: functionsInputTypeIdentifiers,
                operators: operators))
    }
}

extension Project: SemanticAnalyzer {
    func getTypeDeclarations() -> [TypeDefinition] {
        return self.modules.flatMap { source, module in
            return module.getTypeDeclarations()
        }
    }

    func getFunctionDeclarations() -> [FunctionDefinition] {
        return self.modules.flatMap { source, module in
            return module.getFunctionDeclarations()
        }
    }

    func getOperatorOverloadDeclarations() -> [OperatorOverloadDefinition] {
        return self.modules.flatMap { source, module in
            return module.getOperatorOverloadDeclarations()
        }
    }
}

extension Module: SemanticAnalyzer {
    func getTypeDeclarations() -> [TypeDefinition] {
        return self.statements.compactMap { statement in
            if case let .typeDefinition(typeDefinition) = statement {
                return typeDefinition
            } else {
                return nil
            }
        }
    }

    func getFunctionDeclarations() -> [FunctionDefinition] {
        return self.statements.compactMap { statement in
            if case let .functionDefinition(functionDefinition) = statement {
                return functionDefinition
            } else {
                return nil
            }
        }
    }

    func getOperatorOverloadDeclarations() -> [OperatorOverloadDefinition] {
        return self.statements.compactMap { statement in
            if case let .operatorOverloadDefinition(definition) = statement {
                return definition
            } else {
                return nil
            }
        }
    }
}

