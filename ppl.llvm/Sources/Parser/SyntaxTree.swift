
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

enum Expression: Encodable {
    case simpleExpression(Simple)
    case callExpression(Call)
    case branchedExpression(Branched)
    case pipedExpression

    indirect enum Simple: Encodable {
        case intLiteral(Int)
        case floatLiteral(Float)
        case stringLiteral(String)
        case boolLiteral(Bool)

        case positive(Simple)
        case negative(Simple)
        case not(Simple)

        case add(left: Simple, right: Simple)
        case minus(left: Simple, right: Simple)
        case times(left: Simple, right: Simple)
        case by(left: Simple, right: Simple)

        case tuple([Expression])
        case parenthised(Expression)
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
