protocol DeclarationContext {
    func getOperatorOverloadDefinitions() -> [OperatorOverloadDefinition]
    func getFunctionDefinitions() -> [FunctionDefinition]
    func getTypeDefinitions() -> [TypeDefinition]
}

extension Module: DeclarationContext {

    func getOperatorOverloadDefinitions() -> [OperatorOverloadDefinition] {
        return self.statements.compactMap { statement in
            if case let .operatorOverloadDefinition(operatorOverloadDefinition) = statement {
                return operatorOverloadDefinition
            } else {
                return nil
            }
        }
    }

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
    
    func getOperatorOverloadDefinitions() -> [OperatorOverloadDefinition] {
        return self.modules.flatMap { source, module in
            return module.getOperatorOverloadDefinitions()
        }
    }

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
    let typeDefinitions: [NominalType: TypeDefinition]
    let errors: [TypeSemanticError]

    init(context: some DeclarationContext, builtins: some DeclarationContext) {
        // TODO: here should also be handled the dependencies and whatnots
        
        let definitions = context.getTypeDefinitions() + builtins.getTypeDefinitions()
        let resolutions = TypeDeclarationChecker.resolveTypeDefinitions(definitions: definitions)

        self.types = resolutions.types
        self.typeDefinitions = resolutions.types.reduce(into: [:]) { acc, element in
            switch element.value {
            case let .simple(simple):
                acc[simple.identifier] = element.key
            case let .sum(sum):
                acc[sum.identifier] = element.key
            }
        }

        let circularDependencies = TypeDeclarationChecker.detectCyclicalDependencies(types: self.typeDefinitions)

        self.errors = resolutions.errors + circularDependencies
    }

    static private func resolveTypeDefinitions(
        definitions: [TypeDefinition]
    ) -> (
        types: [TypeDefinition: TypeDefinition],
        errors: [TypeSemanticError]
    ) {
        let typesLocations = definitions.reduce(into: [:]) { acc, type in
            acc[type] = (acc[type] ?? []) + [type]
        }

        let errors: [TypeSemanticError] = typesLocations.compactMap { type, types in
            if types.count > 1 {
                return .redeclaration(locations: types.map { $0.location })
            } else {
                return nil
            }
        }

        let types = typesLocations.compactMapValues { types in
            return types.first
        }
        
        return (types: types, errors: errors)
    }

    static private func detectCyclicalDependencies(
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

    let operators: [OperatorOverloadDefinition: OperatorOverloadDefinition]

    let errors: [FunctionSemanticError]

    init(
        context: some DeclarationContext,
        builtins: some DeclarationContext,
        typeDeclarationChecker: TypeDeclarationChecker
    ) {
        let functionDefinitions = context.getFunctionDefinitions() + builtins.getFunctionDefinitions()
        let functionResolutions = FunctionDeclarationChecker.resolveDefinitions(
            definitions: functionDefinitions,
            typeDeclarationChecker: typeDeclarationChecker)

        let operatorDefinitions = context.getOperatorOverloadDefinitions() + builtins.getOperatorOverloadDefinitions()
        let operatorResolutions = FunctionDeclarationChecker.resolveDefinitions(
            definitions: operatorDefinitions,
            typeDeclarationChecker: typeDeclarationChecker)

        self.functions = functionResolutions.functions
        self.operators = operatorResolutions.functions

        self.functionsIdentifiers = self.functions.reduce(into: [:]) { acc, element in
            acc[element.key.functionIdentifier] =
                (acc[element.key.functionIdentifier] ?? []) + [element.key]
        }
        self.functionsInputTypeIdentifiers = self.functions.reduce(into: [:]) { acc, element in
            acc[element.key.inputType] = (acc[element.key.inputType] ?? []) + [element.key]
        }

        let functionTypeCheckErrors = self.functions.flatMap { function, _ in
            var errors: [FunctionSemanticError] = []
            
            function.inputType.getNominalTypesFromIdentifier().forEach { type in
                if typeDeclarationChecker.typeDefinitions[type] == nil {
                    errors.append(
                        .typeNotInScope(
                            location: type.location,
                            type: type,
                            typesInScope: typeDeclarationChecker.typeDefinitions.keys))
                }
            }
            function.params.forEach { param in
                param.type.getNominalTypesFromIdentifier().forEach { type in
                    if typeDeclarationChecker.typeDefinitions[type] == nil {
                        errors.append(
                            .typeNotInScope(
                                location: type.location,
                                type: type,
                                typesInScope: typeDeclarationChecker.typeDefinitions.keys))
                    }
                }
            }
            function.outputType.getNominalTypesFromIdentifier().forEach { type in
                if typeDeclarationChecker.typeDefinitions[type] == nil {
                    errors.append(
                        .typeNotInScope(
                            location: type.location,
                            type: type,
                            typesInScope: typeDeclarationChecker.typeDefinitions.keys))
                }
            }
            return errors
        }

        let operatorTypeCheckErrors = self.operators.flatMap { function, _ in
            var errors: [FunctionSemanticError] = []

            function.left.type.getNominalTypesFromIdentifier().forEach { type in
                if typeDeclarationChecker.typeDefinitions[type] == nil {
                    errors.append(
                        .typeNotInScope(
                            location: type.location,
                            type: type,
                            typesInScope: typeDeclarationChecker.typeDefinitions.keys))
                }
            }

            function.right.type.getNominalTypesFromIdentifier().forEach { type in
                if typeDeclarationChecker.typeDefinitions[type] == nil {
                    errors.append(
                        .typeNotInScope(
                            location: type.location,
                            type: type,
                            typesInScope: typeDeclarationChecker.typeDefinitions.keys))
                }
            }

            return errors
        }
        self.errors = functionResolutions.errors + functionTypeCheckErrors + operatorTypeCheckErrors
    }

    static private func resolveDefinitions<Definition>(
        definitions: [Definition],
        typeDeclarationChecker: TypeDeclarationChecker
    ) -> (
        functions: [Definition: Definition],
        errors: [FunctionSemanticError]
    ) where Definition: Hashable, Definition: SyntaxNode {
        let functionsLocations = definitions.reduce(into: [:]) { acc, function in
            acc[function] = (acc[function] ?? []) + [function]
        }

        let errors: [FunctionSemanticError] = functionsLocations.compactMap { function, functions in
            if functions.count > 1 {
                return .redeclaration(locations: functions.map { $0.location })
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
