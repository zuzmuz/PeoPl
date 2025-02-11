// MARK: - the syntax tree source
// ------------------------------

struct NodeLocation: Encodable, Equatable, Comparable {
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

    static func < (lhs: NodeLocation, rhs: NodeLocation) -> Bool {
        lhs.sourceName < rhs.sourceName ||
        lhs.sourceName == rhs.sourceName &&
        lhs.pointRange.lowerBound < rhs.pointRange.lowerBound
    }

    static let nowhere = NodeLocation(
        pointRange: Point(
            line: 0, column: 0)..<Point(
            line: 0, column: 0),
        range: 0..<0,
        sourceName: "")
}

struct Source {
    let content: String
    let name: String
}

protocol SyntaxNode {
    var location: NodeLocation { get }
}

struct Project: Encodable {
    let modules: [String: Module]
}

struct Module: Encodable {
    let statements: [Statement]
}

enum Statement: Encodable, SyntaxNode {
    case typeDefinition(TypeDefinition)
    case functionDefinition(FunctionDefinition)
    // case implementationStatement(ImplementationStatement)
    // case constantsStatement(ConstantsStatement)

    var location: NodeLocation {
        return switch self {
        case let .typeDefinition(typeDefinition):
            typeDefinition.location
        case let .functionDefinition(functionDefinition):
            functionDefinition.location
        }
    }
}

// MARK: - type definitions
// ------------------------

struct ParamDefinition: Encodable, SyntaxNode {
    let name: String
    let type: TypeIdentifier
    // let defaultValue: Expression.Simple?
    let location: NodeLocation
}

enum TypeDefinition: Encodable, SyntaxNode {
    case simple(Simple)
    case sum(Sum)

    struct Simple: Encodable, SyntaxNode {
        let identifier: NominalType
        let params: [ParamDefinition]
        let location: NodeLocation
    }

    struct Sum: Encodable, SyntaxNode {
        let identifier: NominalType
        let cases: [Simple]
        let location: NodeLocation
    }

    var location: NodeLocation {
        return switch self {
        case let .simple(simple):
            simple.location
        case let .sum(sum):
            sum.location
        }
    }
}

// MARK: - function definitions
// ----------------------------

struct FunctionIdentifier: Encodable {
    let scope: NominalType?
    let name: String
}

struct FunctionDefinition: Encodable, SyntaxNode {
    let inputType: TypeIdentifier
    let functionIdentifier: FunctionIdentifier
    let params: [ParamDefinition]
    let outputType: TypeIdentifier
    let body: Expression
    let location: NodeLocation
}

// MARK: - types
// -------------

enum TypeIdentifier: Encodable, SyntaxNode, Sendable {
    case nothing(location: NodeLocation)
    case never(location: NodeLocation)
    case nominal(NominalType)
    case lambda(StructuralType.Lambda)
    case namedTuple(StructuralType.NamedTuple)
    case unnamedTuple(StructuralType.UnnamedTuple)

    var location: NodeLocation {
        return switch self {
        case let .nothing(location):
            location
        case let .never(location):
            location
        case let .nominal(nominal):
            nominal.location
        case let .lambda(lambda):
            lambda.location
        case let .namedTuple(namedTuple):
            namedTuple.location
        case let .unnamedTuple(unnamedTuple):
            unnamedTuple.location
        }
    }
}

struct FlatNominalType: Encodable, SyntaxNode {
    static let typeName = "type_name"
    static let typeArguments = "type_arguments"
    var typeName: String
    var typeArguments: [TypeIdentifier]
    var location: NodeLocation
}

struct NominalType: Encodable, SyntaxNode {
    static let flatNominalType = "flat_nominal_type"
    var chain: [FlatNominalType]
    var location: NodeLocation
}

enum StructuralType {
    struct Lambda: Encodable, SyntaxNode {
        // TODO: input and output should be 1 and multiple inputs should be tupled
        let input: [TypeIdentifier]
        let output: [TypeIdentifier]
        let location: NodeLocation
    }

    struct UnnamedTuple: Encodable, SyntaxNode {
        let types: [TypeIdentifier]
        let location: NodeLocation
    }

    struct NamedTuple: Encodable, SyntaxNode {
        let types: [ParamDefinition]
        let location: NodeLocation
    }
}

// MARK: - Expressions
// -------------------

struct Expression: Encodable, SyntaxNode {
    let expressionType: ExpressionType
    let location: NodeLocation

    static let empty = Expression(expressionType: .nothing, location: .nowhere)

    indirect enum ExpressionType: Encodable, Sendable {
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

        case multiplied(Expression)
        case divided(Expression)
        case moduled(Expression)
        case anded(Expression)
        case ored(Expression)

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
        case unnamedTuple([Expression])
        case namedTuple([Argument])
        case lambda(Expression)

        // Scope
        case call(Call)
        case access(Access)
        case field(String)

        case branched(Branched)
        case piped(left: Expression, right: Expression)
    }

    enum Prefix: Encodable {
        case simple(Expression)
        case type(NominalType)
    }

    struct Argument: Encodable, SyntaxNode, Sendable {
        let name: String
        let value: Expression
        let location: NodeLocation
    }

    struct Call: Encodable, SyntaxNode {
        let command: Prefix
        let arguments: [Argument]
        let location: NodeLocation
    }


    struct Access: Encodable, SyntaxNode {
        let accessed: Prefix
        let field: String
        let location: NodeLocation
    }

    struct Branched: Encodable, SyntaxNode {
        let branches: [Branch]
        let lastBranch: Expression?
        let location: NodeLocation

        enum CaptureGroup: Encodable {
            case simple(Expression)
            case type(NominalType)
            case paramDefinition(ParamDefinition)
            case argument(Argument)
        }

        struct Branch: Encodable, SyntaxNode {
            let captureGroup: [CaptureGroup]
            let body: Body
            let location: NodeLocation

            enum Body: Encodable {
                case simple(Expression)
                case looped(Expression)
            }
        }
    }
}
