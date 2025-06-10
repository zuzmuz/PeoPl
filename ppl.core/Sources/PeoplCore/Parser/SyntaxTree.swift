// MARK: - Language Syntax Tree
// ============================
// This file defines the complete Abstract Syntax Tree (AST) for PeoPl

// MARK: - Core Operators
// ----------------------

/// Defines all operators supported by the language, including arithmetic, logical, and comparison operators
enum Operator: String, Codable {
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

// MARK: - Syntax Tree Namespace
// ------------------------------

/// Main namespace containing all syntax tree node definitions
enum Syntax {

    // MARK: - Source Location Tracking
    // --------------------------------

    /// Represents the location of a syntax node in the source code
    struct NodeLocation: Comparable, Equatable, Codable {
        /// A point in the source code defined by line and column numbers
        struct Point: Comparable, Equatable, Codable {
            let line: Int
            let column: Int
            static func < (lhs: Point, rhs: Point) -> Bool {
                lhs.line < rhs.line
                    || lhs.line == rhs.line && lhs.column < rhs.column
            }
        }
        let pointRange: Range<Point>
        let range: Range<Int>

        static func < (lhs: NodeLocation, rhs: NodeLocation) -> Bool {
            lhs.pointRange.lowerBound < rhs.pointRange.lowerBound
        }

        static let nowhere = NodeLocation(
            pointRange: Point(
                line: 0, column: 0)..<Point(
                    line: 0, column: 0),
            range: 0..<0)

        init(from decoder: any Decoder) throws {
            let container = try decoder.container(
                keyedBy: CodingKeys.self)
            if container.allKeys.isEmpty {
                self = .nowhere
            } else {
                self.pointRange = try container.decode(
                    Range<Point>.self, forKey: .pointRange)
                self.range = try container.decode(
                    Range<Int>.self, forKey: .range)
            }
        }

        init(pointRange: Range<Point>, range: Range<Int>) {
            self.pointRange = pointRange
            self.range = range
        }
    }

    // MARK: - Source Code Representation
    // -----------------------------------

    /// Represents a source file with its content and identifier
    struct Source {
        /// source code text
        let content: String
        /// file name identifer
        let name: String
    }

    /// Protocol that all syntax tree nodes must implement for source location tracking
    protocol SyntaxNode: Codable {
        var location: NodeLocation { get }
    }

    // MARK: - Project Structure
    // -------------------------

    /// Top-level container representing an entire program or project
    /// Maps module names to their corresponding module definitions
    struct Project: Codable {
        let modules: [String: Module]
    }

    /// A compilation unit containing a list of top-level definitions
    /// Modules are basically files
    struct Module: Codable {
        let sourceName: String
        let definitions: [Definition]
    }

    /// Top-level definitions that can appear at module scope
    /// The language supports two kinds of top-level definitions: types and values
    enum Definition: SyntaxNode, Codable {
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

    /// Represents a potentially qualified identifier (e.g., Module::SubModule::identifier)
    /// Used for referencing definitions across module boundaries
    /// Examples:
    /// - Simple identifier: ["foo"] represents `foo`
    /// - Qualified identifier: ["Module", "foo"] represents `Module::foo`
    /// - Deeply nested: ["A", "B", "C", "foo"] represents `A::B::C::foo`
    struct ScopedIdentifier: SyntaxNode {
        let chain: [String]
        let location: NodeLocation
    }

    /// Defines a new type with an optional parameter list
    /// Can define type aliases, algebraic data types, or constrained types
    struct TypeDefinition: SyntaxNode {
        let identifier: ScopedIdentifier
        let arguments: [TypeField]
        let definition: TypeSpecifier
        let location: NodeLocation
    }

    /// Defines a value (function, constant, or computed expression)
    struct ValueDefinition: SyntaxNode {
        let identifier: ScopedIdentifier
        let arguments: [TypeField]
        let definition: Expression
        let location: NodeLocation
    }

    // MARK: - Type System
    // -------------------

    /// The core type specification language
    /// This represents the full spectrum of types available in the language
    enum TypeSpecifier: SyntaxNode, Sendable {
        /// Unit type (empty tuple)
        case nothing(location: NodeLocation)
        /// Unreachable type
        case never(location: NodeLocation)
        /// Tuples/Records
        case product(Product)
        /// Tagged unions
        case sum(Sum)
        /// Type constraints, e.g., contracts, protocols, interfaces, traits, concepts
        case subset(Subset)
        // ∃ types (existential quantification), opaque type known at compile time
        case existential(Existential)
        // ∀ types (universal quantification), erased type unknown at compile time
        case universal(Universal)
        // ∈ types, constrained generic types
        case belonging(Belonging)
        // Named types with type arguments
        case nominal(Nominal)
        // Function types
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

    /// A type field with a label/tag for record types and function parameters
    struct TaggedTypeSpecifier: SyntaxNode {
        let identifier: String
        let type: TypeSpecifier
        let location: NodeLocation
    }

    /// Represents homogeneous collections with a compile-time known size
    /// Used for arrays, vectors, or other fixed-size collections
    struct HomogeneousTypeProduct: SyntaxNode {

        /// The size/count can be either a literal number or a type-level identifier
        enum Exponent: Codable {
            case literal(UInt64)
            case identifier(ScopedIdentifier)
        }

        let typeSpecifier: TypeSpecifier
        let count: Exponent
        let location: NodeLocation
    }

    /// Flexible container for different kinds of type fields in compound types
    /// A type field can either be an untagged type specifier, a tagged specifier or a homogeneous product.
    /// Useful for defining composible types
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

    // MARK: - Algebraic Data Types
    // ----------------------------

    /// Represents tuples, records, and struct-like types
    struct Product: SyntaxNode {
        let typeFields: [TypeField]
        let location: NodeLocation
    }

    /// Represents tagged unions
    struct Sum: SyntaxNode {
        let typeFields: [TypeField]
        let location: NodeLocation
    }

    /// Represents type constraints,
    /// A subset is a colletion of types that constitute a subset of all types.
    /// The subset conforms to certain constraints,
    /// therefore can behave as an unbounded union of all types belonging to the subset
    /// or a generic constraint for generic types
    struct Subset: SyntaxNode {
        let typeFields: [TypeField]
        let location: NodeLocation
    }

    /// Represents existential types,
    /// An opaque type belonging to a subset, statically discoverable at compile time
    struct Existential: SyntaxNode {
        let type: ScopedIdentifier
        let alias: String?
        let location: NodeLocation
    }

    /// Represents universal types,
    /// An erased type that can be used to represent any type belonging to a subset
    struct Universal: SyntaxNode {
        let type: ScopedIdentifier
        let location: NodeLocation
    }

    /// Represents constrained generic types,
    /// Used to bind generic types to a subset of types
    struct Belonging: SyntaxNode {
        let alias: String
        let subset: ScopedIdentifier
        let location: NodeLocation
    }

    /// Nominal type: a named type with optional type arguments
    /// References user-defined types, built-in types, or generic instantiations
    struct Nominal: SyntaxNode {
        let identifier: ScopedIdentifier
        let typeArguments: [TypeSpecifier]
        let location: NodeLocation
    }

    /// Function type: represents the type of functions and procedures
    /// Supports both traditional and dependently-typed function signatures
    /// - inputType: Optional input type for the function, can be nil for procedures
    struct Function: SyntaxNode {
        let inputType: TypeSpecifier?
        let arguments: [TypeField]
        let outputType: TypeSpecifier
        let location: NodeLocation
    }

    // MARK: - Expressions
    // -------------------

    /// An expression with a label/tag for pattern matching and named parameters
    struct TaggedExpression: SyntaxNode {
        let identifier: String
        let expression: Expression
        let location: NodeLocation
    }

    /// Core expression node representing all computations and values in the language
    struct Expression: SyntaxNode {
        let expressionType: ExpressionType
        let location: NodeLocation

        /// Literal values that can appear directly in source code
        enum Literal: Codable {
            case nothing
            case never
            case intLiteral(UInt64)
            case floatLiteral(Double)
            case stringLiteral(String)
            case boolLiteral(Bool)
        }

        indirect enum ExpressionType: Sendable, Codable {
            case literal(Literal)

            /// Prefix operators expression
            case unary(Operator, expression: Expression)
            /// Infix operators expression
            case binary(Operator, left: Expression, right: Expression)

            /// Function expression,
            /// Contains optional signature that defines the function type
            case function(signature: Function?, expression: Expression)

            /// Function calls
            case call(prefix: Expression, arguments: [Expression])
            /// Instance initialization
            case initializer(prefix: Nominal?, arguments: [Expression])
            /// Object fields
            case access(prefix: Expression, field: String)
            /// A qualified field access
            case field(ScopedIdentifier)
            /// Local bindings
            case binding(String)

            case taggedExpression(TaggedExpression)

            /// Pattern matching with guards
            case branched(Branched)
            /// Piped expressions
            case piped(left: Expression, right: Expression)
        }

        /// Pattern matching construct with optional guards
        /// Provides the primary control flow mechanism in the language
        struct Branched: SyntaxNode {
            let branches: [Branch]
            let location: NodeLocation

            /// A single branch in a pattern match expression
            struct Branch: SyntaxNode {
                /// Pattern to match against
                let matchExpression: Expression
                /// Optional guard condition
                let guardExpression: Expression?
                let body: Expression
                let location: NodeLocation
            }
        }
    }
}
