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
    let typeDefinitions: [NominalType: TypeDefinition]
    init(context: some DeclarationContext) {
        // TODO: here should also be handled the dependencies and whatnots

        let definitions = context.getTypeDefinitions()
        let resolutions = TypeDeclarationChecker.resolveTypeDefinitions(definitions: definitions)

        self.types = resolutions.types
        self.typesIdentifiers = [
            Builtins.i32: Builtins.i32,
            Builtins.f64: Builtins.f64,
            Builtins.string: Builtins.string,
            Builtins.bool: Builtins.bool,
            .nothing(): .nothing(),
            .never(): .never(),
        ]
        self.typeDefinitions = [:]
    }

    static private func resolveTypeDefinitions(
        definitions: [TypeDefinition]
    ) -> (
        types: [TypeDefinition: TypeDefinition],
        errors: [SemanticError]
    ) {
        let typesLocations = definitions.reduce(into: [:]) { acc, type in
            acc[type] = (acc[type] ?? []) + [type]
        }

        let errors = typesLocations.compactMap { type, types in
            if types.count > 1 {
                return TypeSemanticError.redeclaration(locations: types.map { $0.location })
            } else {
                return nil
            }
        }

        let types = typesLocations.compactMapValues { types in
            return types.first
        }
        
        return (types: types, errors: errors)
    }

    static private func detectCircularDependencies(
        types: [NominalType: TypeDefinition]
    ) -> [TypeSemanticError] {
        
        enum NodeState {
            case visiting
            case visited
        }

        var nodeStates: [NominalType: NodeState] = [:]
        var cycles: [TypeSemanticError] = []

        func checkCyclicalDependency(typeIdentifier: TypeIdentifier) {
            switch typeIdentifier {
            case let .nominal(nominal):
                checkCyclicalDependency(nominal: nominal)
            case let .unnamedTuple(tuple):
                tuple.types.forEach { typeIdentifier in
                    checkCyclicalDependency(typeIdentifier: typeIdentifier)
                }
            case let .namedTuple(tuple):
                tuple.types.forEach { tupleParam in
                    checkCyclicalDependency(typeIdentifier: tupleParam.type)
                }
            case let .union(union):
                union.types.forEach { typeIdentifier in
                    checkCyclicalDependency(typeIdentifier: typeIdentifier)
                }
            default:
                break
            }
        }

        func checkCyclicalDependency(nominal: NominalType) {
            if nodeStates[nominal] == .visited {
                return
            }
            if nodeStates[nominal] == .visiting {
                cycles.append(.cyclicType(cyclicType: nominal))
                return 
            }
            nodeStates[nominal] = .visiting
            guard let typeDefinition = types[nominal] else { return /*type checker should catch this error*/ }

            switch typeDefinition {
            case let .simple(simple):
                simple.params.forEach { param in
                    checkCyclicalDependency(typeIdentifier: param.type)
                }
            case let .sum(sum):
                sum.cases.forEach { simpleCase in
                    simpleCase.params.forEach { param in
                        checkCyclicalDependency(typeIdentifier: param.type)
                    }
                }
            }
            nodeStates[nominal] = .visited
        }
        
        types.forEach { nominal, typeDefinition in
            checkCyclicalDependency(nominal: nominal)
        }

        return cycles
    }
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
