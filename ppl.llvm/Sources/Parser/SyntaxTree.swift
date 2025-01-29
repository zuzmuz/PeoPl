
// MARK: - the syntax tree source
// ------------------------------

struct SyntaxTree: Encodable {
    let statements: [Statement]
}

enum Statement: Encodable {
    case typeDefinition(TypeDefinition)
    case functionDefinition(FunctionDefinition)
    // case implementationStatement(ImplementationStatement)
    // case constantsStatement(ConstantsStatement)
}

// MARK: - type definitions
// ------------------------


struct ParamDefinition: Encodable {
    let name: String
    let type: TypeIdentifier
}

enum TypeDefinition: Encodable {
    case simple(Simple)
    case meta(Meta)


    struct Simple: Encodable {
        let identifier: NominalType
        let params: [ParamDefinition]
    }

    struct Meta: Encodable {
        let identifier: NominalType
        let cases: [Simple]
    }
}

// MARK: - function definitions
// ----------------------------

struct FunctionDefinition: Encodable {
    let inputType: TypeIdentifier?
    let name: String
    let params: [ParamDefinition]
    let outputType: TypeIdentifier
    let body: String
}

// MARK: - types
// -------------

enum TypeIdentifier: Encodable {
    case nominal(NominalType)
    case structural(StructuralType)
}

enum NominalType: Encodable {
    case specific(String)
    case generic(GenericType)


    struct GenericType: Encodable {
        let name: String
        let associatedTypes: [TypeIdentifier]
    }
}

enum StructuralType: Encodable {
    indirect case lambda(Lambda)
    case tuple([TypeIdentifier])

    struct Lambda: Encodable {
        let input: [TypeIdentifier]
        let output: TypeIdentifier
    }
}


// MARK: - Expressions


