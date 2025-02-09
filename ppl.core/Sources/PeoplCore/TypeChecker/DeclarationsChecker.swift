
struct TypeChecker {
    let typeSymbols: [String]

    func symbolCheck() {
    }

    func typeChecks() {
    }

    func functionCheck() {
    }
}

struct TypeDeclarationChecker {
    let types: [TypeDefinition: TypeDefinition]
    let typesIdentifiers: [TypeIdentifier: TypeIdentifier]
    init(project: Project) {
        // TODO: here should also be handled the dependencies and whatnots
        self.types = [:]
        self.typesIdentifiers = [
            Builtins.i32: Builtins.i32,
            Builtins.f64: Builtins.f64,
            Builtins.string: Builtins.string
        ]
    }

    // TODO: for building independent files
    // init(module: Module) {
    // }
}

extension Module {
    func getFunctionDefinitions() -> [FunctionDefinition] {
        return self.statements.compactMap { statement in
            if case let .functionDefinition(functionDefinition) = statement {
                return functionDefinition
            } else {
                return nil
            }
        }
    }
}

extension Project {
    func getFunctionDefinitions() -> [FunctionDefinition] {
        return self.modules.flatMap { source, module in
            return module.getFunctionDefinitions()
        }
    }
}

struct FunctionDeclarationChecker {
    let functions: [FunctionDefinition: FunctionDefinition]
    let functionsSymbols: [String: [FunctionDefinition]]
    let inputFunctions: [TypeIdentifier: [FunctionDefinition]]
    let errors: [SemanticError]

    init(project: Project, typeDeclarationChecker: TypeDeclarationChecker) {
        let definitions = project.getFunctionDefinitions()
        let resolutions = FunctionDeclarationChecker.resolveFunctionDefinitions(
            definitions: definitions,
            typeDeclarationChecker: typeDeclarationChecker)

        self.functions = resolutions.functions

        self.functionsSymbols = self.functions.reduce(into: [:]) { acc, element in
            acc[element.key.name] = (acc[element.key.name] ?? []) + [element.key]
        }
        self.inputFunctions = self.functions.reduce(into: [:]) { acc, element in
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
            return errors
            
        }


        self.errors = resolutions.errors
    }

    static private func resolveFunctionDefinitions(
        definitions: [FunctionDefinition],
        typeDeclarationChecker: TypeDeclarationChecker
    ) -> (functions: [FunctionDefinition: FunctionDefinition],
          errors: [SemanticError]) {

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

