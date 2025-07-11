// MARK: - Language Syntax Tree
// ============================
// This file defines the complete Abstract Syntax Tree (AST) for PeoPl

// MARK: - Core Operators
// ----------------------

/// Defines all operators supported by the language, including arithmetic, logical, and comparison operators
public enum Operator: String, Codable, Sendable {
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
public enum Syntax {

    // MARK: - Source Location Tracking
    // --------------------------------

    /// Represents the location of a syntax node in the source code
    public struct NodeLocation: Comparable, Equatable, Codable, Sendable {
        /// A point in the source code defined by line and column numbers
        public struct Point: Comparable, Equatable, Codable, Sendable {
            let line: Int
            let column: Int
            public static func < (lhs: Point, rhs: Point) -> Bool {
                lhs.line < rhs.line
                    || lhs.line == rhs.line && lhs.column < rhs.column
            }
        }
        public let pointRange: Range<Point>
        public let range: Range<Int>

        public static func < (lhs: NodeLocation, rhs: NodeLocation) -> Bool {
            lhs.pointRange.lowerBound < rhs.pointRange.lowerBound
        }

        static let nowhere = NodeLocation(
            pointRange: Point(
                line: 0, column: 0)..<Point(
                    line: 0, column: 0),
            range: 0..<0)

        public init(from decoder: any Decoder) throws {
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
    public struct Source {
        /// source code text
        let content: String
        /// file name identifer
        let name: String
    }

    /// Protocol that all syntax tree nodes must implement for source location tracking
    public protocol SyntaxNode: Codable {
        var location: NodeLocation { get }
    }

    // MARK: - Project Structure
    // -------------------------

    /// Top-level container representing an entire program or project
    /// Maps module names to their corresponding module definitions
    public struct Project: Codable {
        let modules: [String: Module]
    }

    public protocol ModuleParser {
        func parseModule(source: Source) -> Module
    }

    /// A compilation unit containing a list of top-level definitions
    /// Modules are basically files
    public struct Module: Codable {
        let sourceName: String
        let definitions: [Definition]
        let syntaxErrors: [Syntax.Error]

        init(
            sourceName: String,
            definitions: [Definition],
            syntaxErrors: [Syntax.Error] = []
        ) {
            self.sourceName = sourceName
            self.definitions = definitions
            self.syntaxErrors = syntaxErrors
        }

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
    public struct ScopedIdentifier: SyntaxNode, Sendable {
        let chain: [String]
        public let location: NodeLocation

        init(
            chain: [String],
            location: NodeLocation = .nowhere
        ) {
            self.chain = chain
            self.location = location
        }
    }

    /// Defines a new type with an optional parameter list
    /// Can define type aliases, algebraic data types, or constrained types
    public struct TypeDefinition: SyntaxNode, Sendable {
        let identifier: ScopedIdentifier
        let arguments: [TypeField]
        let typeSpecifier: TypeSpecifier
        public let location: NodeLocation

        init(
            identifier: ScopedIdentifier,
            arguments: [TypeField] = [],
            typeSpecifier: TypeSpecifier,
            location: NodeLocation = .nowhere
        ) {
            self.identifier = identifier
            self.arguments = arguments
            self.typeSpecifier = typeSpecifier
            self.location = location
        }
    }

    /// Defines a value (function, constant, or computed expression)
    public struct ValueDefinition: SyntaxNode, Sendable {
        let identifier: ScopedIdentifier
        let arguments: [TypeField]
        let expression: Expression
        public let location: NodeLocation

        init(
            identifier: ScopedIdentifier,
            arguments: [TypeField] = [],
            expression: Expression,
            location: NodeLocation = .nowhere
        ) {
            self.identifier = identifier
            self.arguments = arguments
            self.expression = expression
            self.location = location
        }
    }

    // MARK: - Type System
    // -------------------

    /// The core type specification language
    /// This represents the full spectrum of types available in the language
    public enum TypeSpecifier: SyntaxNode, Sendable {
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

        public var location: NodeLocation {
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
    public struct TaggedTypeSpecifier: SyntaxNode, Sendable {
        let tag: String
        let typeSpecifier: TypeSpecifier
        public let location: NodeLocation

        init(
            tag: String,
            typeSpecifier: TypeSpecifier,
            location: NodeLocation = .nowhere
        ) {
            self.tag = tag
            self.typeSpecifier = typeSpecifier
            self.location = location
        }
    }

    /// Represents homogeneous collections with a compile-time known size
    /// Used for arrays, vectors, or other fixed-size collections
    public struct HomogeneousTypeProduct: SyntaxNode, Sendable {

        /// The size/count can be either a literal number or a type-level identifier
        enum Exponent: Codable {
            case literal(UInt64)
            case identifier(ScopedIdentifier)
        }

        let typeSpecifier: TypeSpecifier
        let count: Exponent
        public let location: NodeLocation

        init(
            typeSpecifier: TypeSpecifier,
            count: Exponent,
            location: NodeLocation = .nowhere
        ) {
            self.typeSpecifier = typeSpecifier
            self.count = count
            self.location = location
        }
    }

    /// Flexible container for different kinds of type fields in compound types
    /// A type field can either be an untagged type specifier, a tagged specifier or a homogeneous product.
    /// Useful for defining composible types
    public enum TypeField: SyntaxNode, Sendable {
        case typeSpecifier(TypeSpecifier)
        case taggedTypeSpecifier(TaggedTypeSpecifier)
        case homogeneousTypeProduct(HomogeneousTypeProduct)

        public var location: NodeLocation {
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
    public struct Product: SyntaxNode, Sendable {
        let typeFields: [TypeField]
        public let location: NodeLocation

        init(
            typeFields: [TypeField] = [],
            location: NodeLocation = .nowhere
        ) {
            self.typeFields = typeFields
            self.location = location
        }
    }

    /// Represents tagged unions
    public struct Sum: SyntaxNode, Sendable {
        let typeFields: [TypeField]
        public let location: NodeLocation

        init(
            typeFields: [TypeField] = [],
            location: NodeLocation = .nowhere
        ) {
            self.typeFields = typeFields
            self.location = location
        }
    }

    /// Represents type constraints,
    /// A subset is a colletion of types that constitute a subset of all types.
    /// The subset conforms to certain constraints,
    /// therefore can behave as an unbounded union of all types belonging to the subset
    /// or a generic constraint for generic types
    public struct Subset: SyntaxNode, Sendable {
        let typeFields: [TypeField]
        public let location: NodeLocation

        init(
            typeFields: [TypeField] = [],
            location: NodeLocation = .nowhere
        ) {
            self.typeFields = typeFields
            self.location = location
        }
    }

    /// Represents existential types,
    /// An opaque type belonging to a subset, statically discoverable at compile time
    public struct Existential: SyntaxNode, Sendable {
        let type: ScopedIdentifier
        let alias: String?
        public let location: NodeLocation

        init(
            type: ScopedIdentifier,
            alias: String? = nil,
            location: NodeLocation = .nowhere
        ) {
            self.type = type
            self.alias = alias
            self.location = location
        }
    }

    /// Represents universal types,
    /// An erased type that can be used to represent any type belonging to a subset
    public struct Universal: SyntaxNode, Sendable {
        let type: ScopedIdentifier
        public let location: NodeLocation

        init(
            type: ScopedIdentifier,
            location: NodeLocation = .nowhere
        ) {
            self.type = type
            self.location = location
        }
    }

    /// Represents constrained generic types,
    /// Used to bind generic types to a subset of types
    public struct Belonging: SyntaxNode, Sendable {
        let alias: String
        let subset: ScopedIdentifier
        public let location: NodeLocation

        init(
            alias: String,
            subset: ScopedIdentifier,
            location: NodeLocation = .nowhere
        ) {
            self.alias = alias
            self.subset = subset
            self.location = location
        }
    }

    /// Nominal type: a named type with optional type arguments
    /// References user-defined types, built-in types, or generic instantiations
    public struct Nominal: SyntaxNode, Sendable {
        let identifier: ScopedIdentifier
        let typeArguments: [TypeSpecifier]
        public let location: NodeLocation

        init(
            identifier: ScopedIdentifier,
            typeArguments: [TypeSpecifier] = [],
            location: NodeLocation = .nowhere
        ) {
            self.identifier = identifier
            self.typeArguments = typeArguments
            self.location = location
        }
    }

    /// Function type: represents the type of functions and procedures
    /// Supports both traditional and dependently-typed function signatures
    /// - inputType: Optional input type for the function, can be nil for procedures
    public struct Function: SyntaxNode, Sendable {
        let inputType: TypeField?
        let arguments: [TypeField]
        let outputType: TypeSpecifier
        public let location: NodeLocation

        init(
            inputType: TypeField? = nil,
            arguments: [TypeField] = [],
            outputType: TypeSpecifier,
            location: NodeLocation = .nowhere
        ) {
            self.inputType = inputType
            self.arguments = arguments
            self.outputType = outputType
            self.location = location
        }
    }

    // MARK: - Expressions
    // -------------------

    /// An expression with a label/tag for pattern matching and named parameters
    struct TaggedExpression: SyntaxNode {
        let tag: String
        let expression: Expression
        let location: NodeLocation

        init(
            identifier: String,
            expression: Expression,
            location: NodeLocation = .nowhere
        ) {
            self.tag = identifier
            self.expression = expression
            self.location = location
        }
    }

    /// Core expression node representing all computations and values in the language
    public struct Expression: SyntaxNode, Sendable {
        let expressionType: ExpressionType
        public let location: NodeLocation

        init(
            expressionType: ExpressionType,
            location: NodeLocation = .nowhere
        ) {
            self.expressionType = expressionType
            self.location = location
        }

        /// Literal values that can appear directly in source code
        enum Literal: Equatable, Codable {
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

            init(
                branches: [Branch],
                location: NodeLocation = .nowhere
            ) {
                self.branches = branches
                self.location = location
            }

            /// A single branch in a pattern match expression
            struct Branch: SyntaxNode {
                /// Pattern to match against, if no match expression, nothing is the match expression
                let matchExpression: Expression
                /// Optional guard condition
                let guardExpression: Expression?
                let body: Expression
                let location: NodeLocation

                init(
                    matchExpression: Expression,
                    guardExpression: Expression? = nil,
                    body: Expression,
                    location: NodeLocation = .nowhere
                ) {
                    self.matchExpression = matchExpression
                    self.guardExpression = guardExpression
                    self.body = body
                    self.location = location
                }
            }
        }
    }
}
