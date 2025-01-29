
// MARK: - the syntax tree source
// ------------------------------

struct NodeLocation: Encodable {
    struct Point: Comparable, Encodable {
        let line: Int
        let column: Int
        static func < (lhs: Point, rhs: Point) -> Bool {
            lhs.line < rhs.line || lhs.line == rhs.line && lhs.column < rhs.column
        }
    }
    let pointRange: Range<Point>
    let range: Range<Int>
    let sourceName: String
}

struct Source {
    let content: String
    let name: String
}

protocol SyntaxNode {
    var location: NodeLocation { get }
}

struct Project: Encodable {
    let statements: [Statement]
    let main: FunctionDefinition
}

enum Statement: Encodable {
    case typeDefinition(TypeDefinition)
    case functionDefinition(FunctionDefinition)
    // case implementationStatement(ImplementationStatement)
    // case constantsStatement(ConstantsStatement)
}

// MARK: - type definitions
// ------------------------


struct ParamDefinition: Encodable, SyntaxNode {
    let name: String
    let type: TypeIdentifier
    let defaultValue: Expression.Simple?
    let location: NodeLocation
}

enum TypeDefinition: Encodable {
    case simple(Simple)
    case meta(Meta)


    struct Simple: Encodable, SyntaxNode {
        let identifier: NominalType
        let params: [ParamDefinition]
        let location: NodeLocation
    }

    struct Meta: Encodable, SyntaxNode {
        let identifier: NominalType
        let cases: [Simple]
        let location: NodeLocation
    }
}

// MARK: - function definitions
// ----------------------------

struct FunctionDefinition: Encodable, SyntaxNode {
    let inputType: TypeIdentifier?
    let name: String
    let params: [ParamDefinition]
    let outputType: TypeIdentifier
    let body: Expression
    let location: NodeLocation
}

// MARK: - types
// -------------

enum TypeIdentifier: Encodable {
    case nominal(NominalType)
    case structural(StructuralType)
}

enum NominalType: Encodable {
    struct TypeName: Encodable, SyntaxNode {
        let name: String
        let location: NodeLocation
    }

    case specific(TypeName)
    case generic(GenericType)


    struct GenericType: Encodable {
        let name: TypeName
        let associatedTypes: [TypeIdentifier]
    }
}

enum StructuralType: Encodable {
    indirect case lambda(Lambda)
    case tuple(Tuple)

    struct Lambda: Encodable, SyntaxNode {
        let input: [TypeIdentifier]
        let output: TypeIdentifier
        let location: NodeLocation
    }

    struct Tuple: Encodable, SyntaxNode {
        let types: [TypeIdentifier]
        let location: NodeLocation
    }
}


// MARK: - Expressions
// -------------------

enum Expression: Encodable {
    case simple(Simple)
    case call(Call)
    indirect case branched(Branched)
    case piped(Piped)

    indirect enum Simple: Encodable {

        case nothing
        case never
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
        case mod(left: Simple, right: Simple)
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

        // Fields
        case field(String)
        case access(Access)

        struct Access: Encodable {
            let accessed: Simple
            let field: String
        }
    }

    struct Call: Encodable {

        enum Command: Encodable {
            case field(String)
            case type(TypeIdentifier)
        }

        struct Argument: Encodable {
            let name: String
            let value: Simple
        }

        let command: Command
        let arguments: [Argument]

    }

    struct Branched: Encodable {
        let branches: [Branch]
        let lastBranch: Expression?

        struct Branch: Encodable {
            let captureGroup: [Expression]
            let body: Body

            enum Body: Encodable {
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
