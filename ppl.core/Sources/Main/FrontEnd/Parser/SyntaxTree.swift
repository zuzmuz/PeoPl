// MARK: - Language Syntax Tree

// ============================
// This file defines the complete Abstract Syntax Tree (AST) for PeoPl

// MARK: - Core Operators

// ----------------------

/// Defines all operators supported by the language, including arithmetic,
/// logical, and comparison operators
public enum Operator: String, Codable, Sendable {
	case plus = "+"
	case minus = "-"
	case times = "*"
	case by = "/"
	case modulo = "%"

	case not
	case and
	case or

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
				line: 0, column: 0
			) ..< Point(
				line: 0, column: 0
			),
			range: 0 ..< 0
		)

		public init(from decoder: any Decoder) throws {
			let container = try decoder.container(
				keyedBy: CodingKeys.self
			)
			if container.allKeys.isEmpty {
				self = .nowhere
			} else {
				pointRange = try container.decode(
					Range<Point>.self, forKey: .pointRange
				)
				range = try container.decode(
					Range<Int>.self, forKey: .range
				)
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

	/// Protocol that all syntax tree nodes must implement for source location
	/// tracking
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
		static func parseModule(source: Source) -> Module
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
	/// # Attributes:
	/// - identifier: The name of the definition, can be qualified
	/// - typeSpecifier: Optional type specification for the definition, the type
	/// can be infered from the expression and is optional
	/// - typeArguments: Optional type arguments for generic definitions
	/// - definition: The expression that defines the value or type
	public struct Definition: SyntaxNode, Sendable {
		let identifier: QualifiedIdentifier
		let typeSpecifier: TypeSpecifier?
		let typeArguments: [TypeField]
		let definition: Expression
		public let location: NodeLocation

		init(
			identifier: QualifiedIdentifier,
			typeSpecifier: TypeSpecifier? = nil,
			typeArguments: [TypeField] = [],
			definition: Expression,
			location: NodeLocation = .nowhere
		) {
			self.identifier = identifier
			self.typeSpecifier = typeSpecifier
			self.typeArguments = typeArguments
			self.definition = definition
			self.location = location
		}
	}

	/// Represents a potentially qualified identifier (e.g.,
	/// Module::SubModule::identifier)
	/// Used for referencing definitions across module boundaries
	/// Examples:
	/// - Simple identifier: ["foo"] represents `foo`
	/// - Qualified identifier: ["Module", "foo"] represents `Module\foo`
	/// - Deeply nested: ["A", "B", "C", "foo"] represents `A\B\C\foo`
	public struct QualifiedIdentifier: SyntaxNode, Sendable {
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
		case recordType(RecordType)
		/// Tagged unions
		case choiceType(ChoiceType)
		/// Named types with type arguments
		case nominal(Nominal)
		/// Function types
		indirect case function(FunctionType)

		public var location: NodeLocation {
			return switch self {
			case let .nothing(location): location
			case let .never(location): location
			case let .recordType(product): product.location
			case let .choiceType(sum): sum.location
			case let .nominal(nominal): nominal.location
			case let .function(function): function.location
			}
		}
	}

	/// A type field with a label/tag for record types and function parameters
	public struct TaggedTypeSpecifier: SyntaxNode, Sendable {
		let tag: String
		let typeSpecifier: TypeSpecifier?
		public let location: NodeLocation

		init(
			tag: String,
			typeSpecifier: TypeSpecifier?,
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
			case identifier(QualifiedIdentifier)
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
	/// A type field can either be an untagged type specifier, a tagged specifier
	/// or a homogeneous product.
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
	public struct RecordType: SyntaxNode, Sendable {
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
	public struct ChoiceType: SyntaxNode, Sendable {
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

	/// Nominal type: a named type with optional type arguments
	/// References user-defined types, built-in types, or generic instantiations
	public struct Nominal: SyntaxNode, Sendable {
		let identifier: QualifiedIdentifier
		let typeArguments: [Expression]
		public let location: NodeLocation

		init(
			identifier: QualifiedIdentifier,
			typeArguments: [Expression] = [],
			location: NodeLocation = .nowhere
		) {
			self.identifier = identifier
			self.typeArguments = typeArguments
			self.location = location
		}
	}

	/// Function type: represents the type of functions
	/// Supports both traditional and dependently-typed function signatures
	/// - inputType: Optional input type for the function
	public struct FunctionType: SyntaxNode, Sendable {
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
	public struct TaggedExpression: SyntaxNode, Sendable {
		let tag: String
		let expression: Expression
		public let location: NodeLocation

		init(
			identifier: String,
			expression: Expression,
			location: NodeLocation = .nowhere
		) {
			tag = identifier
			self.expression = expression
			self.location = location
		}
	}

	/// Core expression node representing all computations and values in the
	/// language
	public indirect enum Expression: Codable, Sendable, SyntaxNode {
		case literal(Literal)
		case unary(Unary)
		case binary(Binary)
		case nominal(Nominal)
		case typeSpecifier(TypeSpecifier)
		case function(Function)
		case call(Call)
		case access(Access)
		case binding(Binding)
		case taggedExpression(TaggedExpression)
		case branched(Branched)
		case piped(Pipe)

		public var location: Syntax.NodeLocation {
			switch self {
			case let .literal(literal):
				literal.location
			case let .unary(unary):
				unary.location
			case let .binary(binary):
				binary.location
			case let .nominal(nominal):
				nominal.location
			case let .typeSpecifier(typeSpecifier):
				typeSpecifier.location
			case let .function(function):
				function.location
			case let .call(call):
				call.location
			case let .access(access):
				access.location
			case let .binding(binding):
				binding.location
			case let .taggedExpression(taggedExpression):
				taggedExpression.location
			case let .branched(branched):
				branched.location
			case let .piped(piped):
				piped.location
			}
		}
	}

	public struct Literal: SyntaxNode, Sendable {
		public enum Value: Equatable, Codable, Sendable {
			case nothing
			case never
			case intLiteral(UInt64)
			case floatLiteral(Double)
			case stringLiteral(String)
			case boolLiteral(Bool)
		}

		let value: Value
		public let location: NodeLocation

		init(value: Value, location: NodeLocation = .nowhere) {
			self.value = value
			self.location = location
		}
	}

	public struct Unary: SyntaxNode, Sendable {
		let op: Operator
		let expression: Expression
		public let location: NodeLocation

		init(
			op: Operator,
			expression: Expression,
			location: NodeLocation = .nowhere
		) {
			self.op = op
			self.expression = expression
			self.location = location
		}
	}

	public struct Binary: SyntaxNode, Sendable {
		let op: Operator
		let left: Expression
		let right: Expression
		public let location: NodeLocation

		init(
			op: Operator,
			left: Expression,
			right: Expression,
			location: NodeLocation = .nowhere
		) {
			self.op = op
			self.left = left
			self.right = right
			self.location = location
		}
	}

	public struct Function: SyntaxNode, Sendable {
		let signature: FunctionType?
		let body: Expression
		public let location: NodeLocation

		init(
			signature: FunctionType? = nil,
			body: Expression,
			location: NodeLocation = .nowhere
		) {
			self.signature = signature
			self.body = body
			self.location = location
		}
	}

	public struct Call: SyntaxNode, Sendable {
		let prefix: Expression?
		let arguments: [Expression]
		public let location: NodeLocation

		init(
			prefix: Expression?,
			arguments: [Expression] = [],
			location: NodeLocation = .nowhere
		) {
			self.prefix = prefix
			self.arguments = arguments
			self.location = location
		}
	}

	public struct Access: SyntaxNode, Sendable {
		let prefix: Expression
		let field: String
		public let location: NodeLocation

		init(
			prefix: Expression,
			field: String,
			location: NodeLocation = .nowhere
		) {
			self.prefix = prefix
			self.field = field
			self.location = location
		}
	}

	public struct Binding: SyntaxNode, Sendable {
		let identifier: String
		public let location: NodeLocation

		init(
			identifier: String,
			location: NodeLocation = .nowhere
		) {
			self.identifier = identifier
			self.location = location
		}
	}

	public struct Branched: SyntaxNode, Sendable {
		let branches: [Branch]
		public let location: NodeLocation

		init(
			branches: [Branch],
			location: NodeLocation = .nowhere
		) {
			self.branches = branches
			self.location = location
		}

		/// A single branch in a pattern match expression
		struct Branch: SyntaxNode, Sendable {
			/// Pattern to match against, if no match expression, nothing is the match
			/// expression
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

	public struct Pipe: SyntaxNode, Sendable {
		let left: Expression
		let right: Expression
		public let location: NodeLocation

		init(
			left: Expression,
			right: Expression,
			location: NodeLocation = .nowhere
		) {
			self.left = left
			self.right = right
			self.location = location
		}
	}
}
