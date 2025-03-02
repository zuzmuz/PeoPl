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
    case operatorOverloadDefinition(OperatorOverloadDefinition)
    // case implementationStatement(ImplementationStatement)
    // case constantsStatement(ConstantsStatement)

    var location: NodeLocation {
        return switch self {
        case let .typeDefinition(typeDefinition):
            typeDefinition.location
        case let .functionDefinition(functionDefinition):
            functionDefinition.location
        case let .operatorOverloadDefinition(operatorOverloadDefinition):
            operatorOverloadDefinition.location
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

    var identifier: NominalType {
        return switch self {
        case let .simple(simple):
            simple.identifier
        case let .sum(sum):
            sum.identifier
        }
    }

    var allParams: [ParamDefinition] {
        return switch self {
        case let .simple(simple):
            simple.params
        case let .sum(sum):
            sum.cases.flatMap { simple in
                simple.params
            }
        }
    }
}

// MARK: - function definitions
// ----------------------------

enum Operator: String, Encodable {
    case plus = "+"
    case minus = "-"
    case times = "*"
    case by = "/"
    case modulo = "%"
    case not = "not"
    case and = "and"
    case or = "or"
    case equal = "="
    case different = "!="
    case lessThan = "<"
    case lessThanOrEqual = "<="
    case greaterThan = ">"
    case greaterThanOrEqual = ">="
}

struct FunctionIdentifier: Encodable {
    let scope: NominalType?
    let name: String

    var fullName: String {
        if let scope {
            return "\(scope.chain.map { $0.typeName }.joined(separator: ".")).\(name)"
        } else {
            return name
        }
    }
}

struct FunctionDefinition: Encodable, SyntaxNode {
    let inputType: TypeIdentifier
    let functionIdentifier: FunctionIdentifier
    let params: [ParamDefinition]
    let outputType: TypeIdentifier
    let body: Expression?
    let location: NodeLocation
}

struct OperatorOverloadDefinition: Encodable, SyntaxNode {
    let left: ParamDefinition
    let op: Operator
    let right: ParamDefinition
    let outputType: TypeIdentifier
    let body: Expression?
    let location: NodeLocation
}

// MARK: - types
// -------------

enum TypeIdentifier: Encodable, SyntaxNode, Sendable {
    case unkown(location: NodeLocation = .nowhere)
    // case undefinedNumber(location: NodeLocation = .nowhere)
    // case undefinedDecimalNumber(location: NodeLocation = .nowhere)
    case nothing(location: NodeLocation = .nowhere)
    case never(location: NodeLocation = .nowhere)
    case nominal(NominalType)
    case lambda(StructuralType.Lambda)
    case namedTuple(StructuralType.NamedTuple)
    case unnamedTuple(StructuralType.UnnamedTuple)
    case union(UnionType)

    var location: NodeLocation {
        return switch self {
        case let .unkown(location):
            location
        // case let .undefinedNumber(location):
        //     location
        // case let .undefinedDecimalNumber(location):
        //     location
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
        case let .union(unionType):
            unionType.location
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

    var typeName: String {
        // WARN: considering no type arguments
        return chain.map { $0.typeName }.joined(separator: ".")
    }
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

struct UnionType: Encodable, SyntaxNode {
    let types: [TypeIdentifier]
    let location: NodeLocation
}

// MARK: - Expressions
// -------------------

struct Expression: Encodable, SyntaxNode {
    let expressionType: ExpressionType
    let location: NodeLocation
    let typeIdentifier: TypeIdentifier // TODO: Maybe this should not be a stored property like this but part of the expression type
    // being part of the expression type means no inconsistencies for expression like literal and nothing

    init(expressionType: ExpressionType, location: NodeLocation) {
        self.expressionType = expressionType
        self.location = location
        self.typeIdentifier = .unkown(location: .nowhere) 
    }

    init(
        expressionType: ExpressionType,
        location: NodeLocation,
        typeIdentifier: TypeIdentifier
    ) {
        self.expressionType = expressionType
        self.location = location
        self.typeIdentifier = typeIdentifier
    }


    indirect enum ExpressionType: Encodable, Sendable {
        case nothing
        case never
        // Literals
        case intLiteral(Int)
        case floatLiteral(Float)
        case stringLiteral(String)
        case boolLiteral(Bool)

        // Unary
        case unary(Operator, expression: Expression)
        case binary(Operator, left: Expression, right: Expression)

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
        let typeIdentifier: TypeIdentifier

        init(command: Prefix, arguments: [Argument], location: NodeLocation) {
            self.command = command
            self.arguments = arguments
            self.location = location
            self.typeIdentifier = .unkown() 
        }

        init(
            command: Prefix,
            arguments: [Argument],
            location: NodeLocation,
            typeIdentifier: TypeIdentifier
        ) {
            self.command = command
            self.arguments = arguments
            self.location = location
            self.typeIdentifier = typeIdentifier 
        }
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
        let typeIdentifier: TypeIdentifier

        init(branches: [Branch], lastBranch: Expression?, location: NodeLocation) {
            self.branches = branches
            self.lastBranch = lastBranch
            self.location = location
            self.typeIdentifier = .unkown()
        }

        init(
            branches: [Branch],
            lastBranch: Expression?,
            location: NodeLocation,
            typeIdentifier: TypeIdentifier
        ) {
            self.branches = branches
            self.lastBranch = lastBranch
            self.location = location
            self.typeIdentifier = typeIdentifier
        }


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
            let typeIdentifier: TypeIdentifier

            init(captureGroup: [CaptureGroup], body: Body, location: NodeLocation) {
                self.captureGroup = captureGroup
                self.body = body
                self.location = location
                self.typeIdentifier = .unkown()
            }

            init(
                captureGroup: [CaptureGroup],
                body: Body,
                location: NodeLocation,
                typeIdentifier: TypeIdentifier
            ) {
                self.captureGroup = captureGroup
                self.body = body
                self.location = location
                self.typeIdentifier = typeIdentifier
            }

            enum Body: Encodable {
                case simple(Expression)
                case looped(Expression)
            }
        }
    }
}
