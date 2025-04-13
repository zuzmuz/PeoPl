// MARK: - the syntax tree source
// ------------------------------

enum Operator: String {
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

enum Syntax {
    struct NodeLocation: Equatable, Comparable {
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
            lhs.sourceName < rhs.sourceName
                || lhs.sourceName == rhs.sourceName
                    && lhs.pointRange.lowerBound < rhs.pointRange.lowerBound
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

    struct Project {
        let modules: [String: Module]
    }

    struct Module {
        let statements: [Statement]
    }

    enum Statement: SyntaxNode {
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

    struct ParamDefinition: SyntaxNode {
        let name: String
        let type: TypeIdentifier
        // let defaultValue: Expression.Simple?
        let location: NodeLocation
    }

    enum TypeDefinition: SyntaxNode {
        case simple(Simple)
        case sum(Sum)

        struct Simple: SyntaxNode {
            let identifier: NominalType
            let params: [ParamDefinition]
            let location: NodeLocation
        }

        struct Sum: SyntaxNode {
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

    struct FunctionIdentifier {
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

    struct FunctionDefinition: SyntaxNode {
        let inputType: TypeIdentifier?
        let functionIdentifier: FunctionIdentifier
        let params: [ParamDefinition]
        let outputType: TypeIdentifier
        let body: Expression?
        let location: NodeLocation
    }

    struct OperatorOverloadDefinition: SyntaxNode {
        let left: TypeIdentifier
        let op: Operator
        let right: TypeIdentifier
        let outputType: TypeIdentifier
        let body: Expression?
        let location: NodeLocation
    }

    // MARK: - types
    // -------------

    enum TypeIdentifier: SyntaxNode, Sendable {
        case nothing(location: NodeLocation)
        case never(location: NodeLocation)
        case nominal(NominalType)
        case lambda(StructuralType.Lambda)
        case namedTuple(StructuralType.NamedTuple)
        case unnamedTuple(StructuralType.UnnamedTuple)
        case union(UnionType)

        var location: NodeLocation {
            return switch self {
            case let .nothing(location):
                location
            case let .never(location):
                location
            case let .nominal(nominalType):
                nominalType.location
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

    struct FlatNominalType: SyntaxNode {
        static let typeName = "type_name"
        static let typeArguments = "type_arguments"
        let typeName: String
        let typeArguments: [TypeIdentifier]
        let location: NodeLocation
    }

    struct NominalType: SyntaxNode {
        static let flatNominalType = "flat_nominal_type"
        let chain: [FlatNominalType]
        let location: NodeLocation

        var typeName: String {
            // WARN: considering no type arguments
            return chain.map { $0.typeName }.joined(separator: ".")
        }
    }

    enum StructuralType {
        struct Lambda: SyntaxNode {
            // TODO: input and output should be 1 and multiple inputs should be tupled
            let input: [TypeIdentifier]
            let output: [TypeIdentifier]
            let location: NodeLocation
        }

        struct UnnamedTuple: SyntaxNode {
            let types: [TypeIdentifier]
            let location: NodeLocation
        }

        struct NamedTuple {
            let types: [ParamDefinition]
            let location: NodeLocation
        }
    }

    struct UnionType {
        let types: [TypeIdentifier]
        let location: NodeLocation
    }

    // MARK: - Expressions
    // -------------------

    struct Expression: SyntaxNode {
        let expressionType: ExpressionType
        let location: NodeLocation

        init(expressionType: ExpressionType, location: NodeLocation) {
            self.expressionType = expressionType
            self.location = location
        }

        indirect enum ExpressionType: Sendable {
            case nothing
            case never
            // Literals
            case intLiteral(UInt64)
            case floatLiteral(Double)
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

        enum Prefix {
            case simple(Expression)
            case type(NominalType)
        }

        struct Argument: SyntaxNode, Sendable {
            let name: String
            let value: Expression
            let location: NodeLocation
        }

        struct Call: SyntaxNode {
            let command: Prefix
            let arguments: [Argument]
            let location: NodeLocation

            init(command: Prefix, arguments: [Argument], location: NodeLocation) {
                self.command = command
                self.arguments = arguments
                self.location = location
            }
        }

        struct Access: SyntaxNode {
            let accessed: Prefix
            let field: String
            let location: NodeLocation
        }

        struct Branched: SyntaxNode {
            let branches: [Branch]
            let lastBranch: Expression?
            let location: NodeLocation

            init(branches: [Branch], lastBranch: Expression?, location: NodeLocation) {
                self.branches = branches
                self.lastBranch = lastBranch
                self.location = location
            }

            struct Branch: SyntaxNode {

                enum CaptureGroup {
                    case simple(Expression)
                    case type(NominalType)
                    case paramDefinition(ParamDefinition)
                    case argument(Argument)
                }


                let captureGroup: [CaptureGroup]
                let body: Body
                let location: NodeLocation

                init(captureGroup: [CaptureGroup], body: Body, location: NodeLocation) {
                    self.captureGroup = captureGroup
                    self.body = body
                    self.location = location
                }

                enum Body {
                    case simple(Expression)
                    case looped(Expression)
                }
            }
        }
    }
}
