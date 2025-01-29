
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
    let body: Expression?
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
// -------------------

enum Expression: Encodable {
    case simple(Simple)
    case call(Call)
    case branched(Branched)
    case piped(Piped)

    indirect enum Simple: Encodable {
        // Literals
        case intLiteral(Int)
        case floatLiteral(Float)
        case stringLiteral(String)
        case boolLiteral(Bool)
        
        // Unary
        case positive(Simple)
        case negative(Simple)
        case not(Simple)

        // Binary
        // Additives
        case plus(left: Simple, right: Simple)
        case minus(left: Simple, right: Simple)
        // Multiplicatives
        case times(left: Simple, right: Simple)
        case by(left: Simple, right: Simple)
        // Comparatives
        case equal(left: Simple, right: Simple)
        case different(left: Simple, right: Simple)
        case lessThan(left: Simple, right: Simple)
        case lessThanEqual(left: Simple, right: Simple)
        case greaterThan(left: Simple, right: Simple)
        case greaterThanEqual(left: Simple, right: Simple)
        // Logical
        case or(left: Simple, right: Simple)
        case and(left: Simple, right: Simple)
        
        // Compounds
        case tuple([Expression])
        case parenthesized(Expression)
        case lambda(Expression)
        case field(String)
        case access(Simple, field: String)
    }

    struct Call: Encodable {

        enum Command: Encodable {
            case field(String)
            case type(TypeIdentifier)
        }

        let command: Command
        let arguments: [Argument]

    }

    struct Argument: Encodable {
        let name: String
        let value: Simple
    }

    struct Branched: Encodable {
        let branches: [Branch]
        let lastBranch: Branch?

        struct Branch: Encodable {
            let captureGroup: [Expression]
            let body: BranchBody

            enum BranchBody: Encodable {
                case simple(Simple)
                case call(Call)
                indirect case looped(Expression)
            }
        }
    }

    indirect enum Piped: Encodable {
        case normal(left: Expression, right: Expression)
        case unwrapping(left: Expression, right: Expression)
    }
}
