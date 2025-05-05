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
                lhs.line < rhs.line || lhs.line ==
                rhs.line && lhs.column < rhs.column
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
        let type: TypeSpecifier
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

    struct ScopedIdentifier: SyntaxNode {
        let identifier: String
        let scope: NominalType?
        let location: NodeLocation
    }

    struct FunctionDefinition: SyntaxNode {
        let inputType: TypeSpecifier?
        let identifier: ScopedIdentifier
        let params: [ParamDefinition]
        let outputType: TypeSpecifier
        let body: Expression?
        let location: NodeLocation
    }

    struct OperatorOverloadDefinition: SyntaxNode {
        let left: TypeSpecifier
        let op: Operator
        let right: TypeSpecifier
        let outputType: TypeSpecifier
        let body: Expression?
        let location: NodeLocation
    }

    // MARK: - types
    // -------------

    enum TypeSpecifier: SyntaxNode, Sendable {
        case nothing(location: NodeLocation)
        case never(location: NodeLocation)
        case nominal(NominalType)
        case namedTuple(StructuralType.NamedTuple)
        case unnamedTuple(StructuralType.UnnamedTuple)

        var location: NodeLocation {
            return switch self {
            case let .nothing(location):
                location
            case let .never(location):
                location
            case let .nominal(nominalType):
                nominalType.location
            case let .namedTuple(namedTuple):
                namedTuple.location
            case let .unnamedTuple(unnamedTuple):
                unnamedTuple.location
            }
        }
    }

    struct NominalType: SyntaxNode {
        let chain: [String]
        let location: NodeLocation

        var typeName: String {
            return chain.map { $0 }.joined(separator: "::")
        }
    }

    enum StructuralType {
        struct UnnamedTuple: SyntaxNode {
            let types: [TypeSpecifier]
            let location: NodeLocation
        }

        struct NamedTuple {
            let types: [ParamDefinition]
            let location: NodeLocation
        }
    }

    // MARK: - Expressions
    // -------------------

    struct Expression: SyntaxNode {
        let expressionType: ExpressionType
        let location: NodeLocation

        enum Literal {
            case nothing
            case never
            case intLiteral(UInt64)
            case floatLiteral(Double)
            case stringLiteral(String)
            case boolLiteral(Bool)
        }

        indirect enum ExpressionType: Sendable {

            case literal(Literal)

            // Unary
            case unary(Operator, expression: Expression)
            case binary(Operator, left: Expression, right: Expression)

            // Compounds
            case unnamedTuple([Expression])
            case namedTuple([Argument])
            case lambda(Expression)

            // Scope
            case functionCall(prefix: Expression, arguments: [Argument])
            case typeInitializer(prefix: NominalType, arguments: [Argument])
            case access(prefix: Expression, field: String)
            case field(ScopedIdentifier)

            case branched(Branched)
            case piped(left: Expression, right: Expression)
        }

        struct Argument: SyntaxNode, Sendable {
            let name: String
            let value: Expression
            let location: NodeLocation
        }

        struct Branched: SyntaxNode, Sendable {
            let branches: [Branch]
            let location: NodeLocation

            struct Branch: SyntaxNode, Sendable {

                enum MatchExpression: Sendable {
                    case literal(Expression.Literal)
                    case field(ScopedIdentifier)
                    case binding(String)
                    case tupleBinding([MatchExpression])
                    case typeBinding(
                        prefix: NominalType,
                        arguments: [BindingArgument])
                }

                struct BindingArgument: SyntaxNode {
                    let name: String
                    let value: MatchExpression
                    let location: NodeLocation
                }

                let matchExpression: MatchExpression
                let guardExpression: Expression?
                let body: Body
                let location: NodeLocation

                enum Body {
                    case simple(Expression)
                    case looped(Expression)
                }
            }
        }
    }
}
