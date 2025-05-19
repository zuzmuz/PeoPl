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
        case expression(ValueField)

        var location: NodeLocation {
            return switch self {
            case let .typeDefinition(typeDefinition):
                typeDefinition.location
            case let .expression(valueField):
                valueField.location
        }
    }

    struct TypeDefinition: SyntaxNode {
        let identifer: String
        let definition: TypeSpecifier
        let location: NodeLocation
    }

    // MARK: - type definitions
    // ------------------------

    struct TypeField: SyntaxNode {
        let identifier: String
        let type: TypeSpecifier
        let location: NodeLocation
    }
    
    enum TypeSpecifier: SyntaxNode {
        case nothing(location: NodeLocation)
        case never(location: NodeLocation)
        case tuple(Tuple)
        case record(Record)
        case union(Union)
        case choice(Choice)
        case subset(Subset)
        case some(ExistentialType)
        case any(DynamicType)
        case nominal(Nominal)
        indirect case function(Function)

        var location: NodeLocation {
            return switch self {
                case let .nothing(location): location
                case let .never(location): location
                case let .tuple(tuple): tuple.location
                case let .record(record): record.location
                case let .union(union): union.location
                case let .choice(choice): choice.location
                case let .subset(subset): subset.location
                case let .some(some): some.location
                case let .any(any): any.location
                case let .nominal(nominal): nominal.location
                case let .function(function): function.location
            }
        }
    }

    struct Tuple: SyntaxNode {
        let types: [TypeSpecifier]
        let location: NodeLocation
    }

    struct Record: SyntaxNode {
        let typeFields: [TypeField]
        let location: NodeLocation
    }

    struct Union: SyntaxNode {
        let types: [TypeSpecifier]
        let location: NodeLocation
    }

    struct Choice: SyntaxNode {
        let typeFields: [TypeField]
        let location: NodeLocation
    }

    struct Subset: SyntaxNode {
        let typeFields: [TypeField]
        let location: NodeLocation
    }

    struct ExistentialType: SyntaxNode {
        let type: String
        let alias: String?
        let location: NodeLocation
    }

    struct DynamicType: SyntaxNode {
        let type: String
        let alias: String?
        let location: NodeLocation
    }

    struct Nominal: SyntaxNode {
        let identifier: String
        let typeArguments: [TypeSpecifier]
        let location: NodeLocation
    }

    struct Function: SyntaxNode {
        let inputType: TypeSpecifier?
        let arguments: [TypeField]
        let outputType: TypeSpecifier
        let location: NodeLocation
    }

    // MARK: - Expressions
    // -------------------
    
    
    struct ValueField: SyntaxNode {
        let identifier: String
        let expression: Expression
        let location: NodeLocation
    }

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
