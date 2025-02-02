// MARK: - the syntax tree source
// ------------------------------

struct NodeLocation: Encodable {
    struct Point: Comparable, Encodable, Equatable {
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
    let modules: [Module]
}

struct Module: Encodable {
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

struct ParamDefinition: Encodable, SyntaxNode {
    let name: String
    let type: TypeIdentifier
    // let defaultValue: Expression.Simple?
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
    let inputType: TypeIdentifier
    let scope: NominalType?
    let name: String
    let params: [ParamDefinition]
    let outputType: TypeIdentifier
    // let body: Expression
    let location: NodeLocation
}

// MARK: - types
// -------------

enum TypeIdentifier: Encodable, Equatable {
    case nothing
    case never
    case nominal(NominalType)
    case lambda(StructuralType.Lambda)
    case tuple(StructuralType.Tuple)
}

struct FlatNominalType: Encodable, SyntaxNode, Equatable {
    static let typeName = "type_name"
    static let typeArguments = "type_arguments"
    var typeName: String
    var typeArguments: [TypeIdentifier]
    var location: NodeLocation

    static func == (lhs: FlatNominalType, rhs: FlatNominalType) -> Bool {
        lhs.typeName == rhs.typeName && lhs.typeArguments == rhs.typeArguments
    }
}

struct NominalType: Encodable, SyntaxNode, Equatable {
    static let flatNominalType = "flat_nominal_type"
    var chain: [FlatNominalType]
    var location: NodeLocation

    static func == (lhs: NominalType, rhs: NominalType) -> Bool {
        lhs.chain == rhs.chain
    }
}

enum StructuralType {
    struct Lambda: Encodable, SyntaxNode, Equatable {
        let input: [TypeIdentifier]
        let output: [TypeIdentifier]
        let location: NodeLocation

        static func == (lhs: Lambda, rhs: Lambda) -> Bool {
            lhs.input == rhs.input && lhs.output == rhs.output
        }
    }

    struct Tuple: Encodable, SyntaxNode, Equatable {
        let types: [TypeIdentifier]
        let location: NodeLocation

        static func == (lhs: Tuple, rhs: Tuple) -> Bool {
            lhs.types == rhs.types
        }
    }
}

// MARK: - Expressions
// -------------------

struct Expression: Encodable, SyntaxNode {
    let location: NodeLocation
    let expressionType: ExpressionType

    indirect enum ExpressionType: Encodable {
        case nothing
        case never
        // Literals
        case intLiteral(Int)
        case floatLiteral(Float)
        case stringLiteral(String)
        case boolLiteral(Bool)

        // Unary
        case positive(Expression)
        case negative(Expression)
        case not(Expression)

        // Binary
        // Additives
        case plus(left: Expression, right: Expression)
        case minus(left: Expression, right: Expression)
        // Multiplicatives
        case times(left: Expression, right: Expression)
        case by(left: Expression, right: Expression)
        case mod(left: Expression, right: Expression)
        // Comparatives
        case equal(left: Expression, right: Expression)
        case different(left: Expression, right: Expression)
        case lessThan(left: Expression, right: Expression)
        case lessThanEqual(left: Expression, right: Expression)
        case greaterThan(left: Expression, right: Expression)
        case greaterThanEqual(left: Expression, right: Expression)
        // Logical
        case or(left: Expression, right: Expression)
        case and(left: Expression, right: Expression)

        // Compounds
        case tuple([Expression])
        case parenthesized(Expression)
        case lambda(Expression)

        // Scope
        case call(Call)
        case access(Access)
        case field(String)

        case branched(Branched)
        case piped(Piped)

    }

    struct Call: Encodable {

        enum Command: Encodable {
            case simple(Expression)
            case type(TypeIdentifier)
        }

        struct Argument: Encodable {
            let name: String
            let value: Expression
        }

        let command: Command
        let arguments: [Argument]
    }

    struct Access: Encodable {
        let accessed: Expression
        let field: String
    }


    struct Branched: Encodable {
        let branches: [Branch]
        let lastBranch: Expression?

        struct Branch: Encodable {
            let captureGroup: [Expression]
            let body: Body

            enum Body: Encodable {
                case simple(Expression)
                indirect case looped(Expression)
            }
        }
    }

    enum Piped: Encodable {
        case normal(left: Expression, right: Expression)
        case unwrapping(left: Expression, right: Expression)
    }
}
