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
                lhs.line < rhs.line
                    || lhs.line == rhs.line && lhs.column < rhs.column
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

    // MARK: - source
    // --------------

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
        let definitions: [Definition]
    }

    enum Definition: SyntaxNode {
        case typeDefinition(TypeDefinition)
        case valueDefinition(ValueDefinition)

        var location: NodeLocation {
            return switch self {
            case let .typeDefinition(typeDefinition):
                typeDefinition.location
            case let .valueDefinition(valueDefinition):
                valueDefinition.location
            }
        }
    }

    struct ScopedIdentifier: SyntaxNode {
        let chain: [String]
        let location: NodeLocation
    }

    struct TypeDefinition: SyntaxNode {
        let identifier: ScopedIdentifier
        let arguments: [TypeField]
        let definition: TypeSpecifier
        let location: NodeLocation
    }

    struct ValueDefinition: SyntaxNode {
        let identifier: ScopedIdentifier
        let arguments: [TypeField]
        let definition: Expression
        let location: NodeLocation
    }

    // MARK: - type definitions
    // ------------------------

    enum TypeSpecifier: SyntaxNode {
        case nothing(location: NodeLocation)
        case never(location: NodeLocation)
        case product(Product)
        case sum(Sum)
        case subset(Subset)
        case existential(Existential)
        case universal(Universal)
        case belonging(Belonging)
        case nominal(Nominal)
        indirect case function(Function)

        var location: NodeLocation {
            return switch self {
            case let .nothing(location): location
            case let .never(location): location
            case let .product(product): product.location
            case let .sum(sum): sum.location
            case let .subset(subset): subset.location
            case let .existential(existential): existential.location
            case let .universal(universal): universal.location
            case let .belonging(belonging): belonging.location
            case let .nominal(nominal): nominal.location
            case let .function(function): function.location
            }
        }
    }

    struct TaggedTypeSpecifier: SyntaxNode {
        let identifier: String
        let type: TypeSpecifier
        let location: NodeLocation
    }

    struct HomogeneousTypeProduct: SyntaxNode {

        enum Exponent {
            case literal(UInt64)
            case identifier(ScopedIdentifier)
        }

        let typeSpecifier: TypeSpecifier
        let count: Exponent
        let location: NodeLocation
    }

    enum TypeField: SyntaxNode {
        case typeSpecifier(TypeSpecifier)
        case taggedTypeSpecifier(TaggedTypeSpecifier)
        case homogeneousTypeProduct(HomogeneousTypeProduct)

        var location: NodeLocation {
            return switch self {
            case let .typeSpecifier(typeSpecifier):
                typeSpecifier.location
            case let .homogeneousTypeProduct(homogeneousTypeProduct):
                homogeneousTypeProduct.location
            case let .taggedTypeSpecifier(taggedTypeSpecifier):
                taggedTypeSpecifier.location
            }
        }
    }

    struct Product: SyntaxNode {
        let typeFields: [TypeField]
        let location: NodeLocation
    }

    struct Sum: SyntaxNode {
        let typeFields: [TypeField]
        let location: NodeLocation
    }

    struct Subset: SyntaxNode {
        let typeFields: [TypeField]
        let location: NodeLocation
    }

    struct Existential: SyntaxNode {
        let type: String
        let alias: String?
        let location: NodeLocation
    }

    struct Universal: SyntaxNode {
        let type: String
        let location: NodeLocation
    }

    struct Belonging: SyntaxNode {
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

    struct TaggedExpression: SyntaxNode {
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

        indirect enum ExpressionType {

            case literal(Literal)

            // Unary
            case unary(Operator, expression: Expression)
            case binary(Operator, left: Expression, right: Expression)

            // Compounds
            case function(signature: Function?, expression: Expression)

            // Scope
            case call(prefix: Expression, arguments: [Expression])
            case initializer(prefix: Nominal?, arguments: [Expression])
            case access(prefix: Expression, field: String)
            case field(ScopedIdentifier)
            case binding(String)
            case taggedExpression(TaggedExpression)

            case branched(Branched)
            case piped(left: Expression, right: Expression)
        }
        struct Branched: SyntaxNode {
            let branches: [Branch]
            let location: NodeLocation

            struct Branch: SyntaxNode {
                let matchExpression: Expression
                let guardExpression: Expression?
                let body: Expression
                let location: NodeLocation
            }
        }
    }
}
