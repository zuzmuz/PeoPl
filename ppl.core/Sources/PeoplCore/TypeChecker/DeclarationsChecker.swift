protocol DeclarationContext {
    func getFunctionDefinitions() -> [FunctionDefinition]
    func getTypeDefinitions() -> [TypeDefinition]
}

extension Module: DeclarationContext {
    func getFunctionDefinitions() -> [FunctionDefinition] {
        return self.statements.compactMap { statement in
            if case let .functionDefinition(functionDefinition) = statement {
                return functionDefinition
            } else {
                return nil
            }
        }
    }

    func getTypeDefinitions() -> [TypeDefinition] {
        return self.statements.compactMap { statement in
            if case let .typeDefinition(typeDefinition) = statement {
                return typeDefinition
            } else {
                return nil
            }
        }
    }
}

extension Project: DeclarationContext {
    func getFunctionDefinitions() -> [FunctionDefinition] {
        return self.modules.flatMap { source, module in
            return module.getFunctionDefinitions()
        }
    }

    func getTypeDefinitions() -> [TypeDefinition] {
        return self.modules.flatMap { source, module in
            return module.getTypeDefinitions()
        }
    }
}

struct TypeDeclarationChecker {
    let types: [TypeDefinition: TypeDefinition]
    let typesIdentifiers: [TypeIdentifier: TypeIdentifier]
    init(context: some DeclarationContext) {
        // TODO: here should also be handled the dependencies and whatnots
        self.types = [:]
        self.typesIdentifiers = [
            Builtins.i32: Builtins.i32,
            Builtins.f64: Builtins.f64,
            Builtins.string: Builtins.string,
            .nothing(): .nothing(),
            .never(): .never(),
        ]
    }

    // TODO: for building independent files
    // init(module: Module) {
    // }
}

struct FunctionDeclarationChecker {
    let functions: [FunctionDefinition: FunctionDefinition]
    let functionsIdentifiers: [FunctionIdentifier: [FunctionDefinition]]
    let functionsInputTypeIdentifiers: [TypeIdentifier: [FunctionDefinition]]
    let errors: [SemanticError]

    init(context: some DeclarationContext, typeDeclarationChecker: TypeDeclarationChecker) {
        let definitions = context.getFunctionDefinitions()
        let resolutions = FunctionDeclarationChecker.resolveFunctionDefinitions(
            definitions: definitions,
            typeDeclarationChecker: typeDeclarationChecker)

        self.functions = resolutions.functions

        self.functionsIdentifiers = self.functions.reduce(into: [:]) { acc, element in
            acc[element.key.functionIdentifier] =
                (acc[element.key.functionIdentifier] ?? []) + [element.key]
        }
        self.functionsInputTypeIdentifiers = self.functions.reduce(into: [:]) { acc, element in
            acc[element.key.inputType] = (acc[element.key.inputType] ?? []) + [element.key]
        }

        let typeCheckErrors = self.functions.flatMap { function, _ in
            var errors: [SemanticError] = []
            if typeDeclarationChecker.typesIdentifiers[function.inputType] == nil {
                errors.append(
                    FunctionSemanticError.typeNotInScope(
                        location: function.inputType.location,
                        type: function.inputType,
                        typesInScope: typeDeclarationChecker.typesIdentifiers.keys))
            }
            function.params.forEach { param in
                if typeDeclarationChecker.typesIdentifiers[param.type] == nil {
                    errors.append(
                        FunctionSemanticError.typeNotInScope(
                            location: param.location,
                            type: param.type,
                            typesInScope: typeDeclarationChecker.typesIdentifiers.keys))
                }
            }
            if typeDeclarationChecker.typesIdentifiers[function.outputType] == nil {
                errors.append(
                    FunctionSemanticError.typeNotInScope(
                        location: function.outputType.location,
                        type: function.outputType,
                        typesInScope: typeDeclarationChecker.typesIdentifiers.keys))
            }
            return errors
        }

        self.errors = resolutions.errors + typeCheckErrors
    }

    static private func resolveFunctionDefinitions(
        definitions: [FunctionDefinition],
        typeDeclarationChecker: TypeDeclarationChecker
    ) -> (
        functions: [FunctionDefinition: FunctionDefinition],
        errors: [SemanticError]
    ) {

        let functionsLocations = definitions.reduce(into: [:]) { acc, function in
            acc[function] = (acc[function] ?? []) + [function]
        }

        let errors = functionsLocations.compactMap { function, functions in
            if functions.count > 1 {
                return FunctionSemanticError.redeclaration(locations: functions.map { $0.location })
            } else {
                return nil
            }
        }

        let functions = functionsLocations.compactMapValues { functions in
            return functions.first
        }
        return (functions: functions, errors: errors)
    }
}
