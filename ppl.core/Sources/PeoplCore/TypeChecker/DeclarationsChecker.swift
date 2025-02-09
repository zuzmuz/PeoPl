
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
    let typesSymbols: [String: TypeIdentifier]
}

struct FunctionDeclarationChecker {
    let functions: [FunctionDefinition: FunctionDefinition]
    let functionsSymbols: [String: [FunctionDefinition]]
    let inputFunctions: [TypeIdentifier: [FunctionDefinition]]

    init(project: Project, typeDeclarationChecker: TypeDeclarationChecker) {
        self.functions = [:]
        self.functionsSymbols = [:]
        self.inputFunctions = [:]
    }
}
