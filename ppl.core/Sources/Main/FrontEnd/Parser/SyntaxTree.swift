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

	case exponent = "^"

	case not
	case and
	case or

	case bitwiseShiftLeft = "<<"
	case bitwiseShiftRight = ">>"

	case bitwiseNot = "~"
	case bitwiseAnd = "&"
	case bitwiseOr = "|"

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
			)..<Point(
				line: 0, column: 0
			),
			range: 0..<0
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

	/// Generic module parser protocol, implemented by specific parser.
	public protocol ModuleParser {
		/// Parser function to parse a source into a Module.
		/// The Module contains the AST representation of the source code
		/// # Params:
		///	- source: ``Syntax.Source`` The source code to be parsed, representing a file's name and its content
		/// # Returns:
		///	``Syntax.Module`` The parsed module containing the AST
		static func parseModule(source: Source) -> Module
	}

	/// A compilation unit containing a list of top-level definitions
	/// Modules are basically files
	public struct Module: Codable {
		let sourceName: String
		let definitions: [Expression]
		let syntaxErrors: [Syntax.Error]

		init(
			sourceName: String,
			definitions: [Expression],
			syntaxErrors: [Syntax.Error] = []
		) {
			self.sourceName = sourceName
			self.definitions = definitions
			self.syntaxErrors = syntaxErrors
		}
	}

	/// Represents a potentially qualified identifier (e.g.,
	/// Module\SubModule\identifier)
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

	// MARK: - Expressions

	// -------------------------

	/// Core expression node representing
	/// all computations and values in the language
	public indirect enum Expression: Codable, Sendable, SyntaxNode {
		/// Compile time constant literals
		case literal(Literal)
		/// Expression with prefix operator
		case unary(Unary)
		/// Expression with infix operator
		case binary(Binary)
		/// Nominal expression, represented by a ``QualifiedIdentifier``
		/// Represents user defined and builtin construct
		case nominal(QualifiedIdentifier)
		/// A Basic Product type definition
		case typeDefinition(TypeDefinition)
		/// Function definition, lambda expression
		case function(Function)
		/// Call expressions representing function calls, or type initializers, or even tuple instantiations
		case call(Call)
		/// Accessing a field of a record
		case access(Access)
		/// Binding expression inside a branch capture group
		case binding(Binding)
		/// Expression associated with a tag/label
		case taggedExpression(TaggedExpression)
		/// Branching expression for pattern matching
		case branched(Branched)
		/// Pipe expression for chaining operations
		case piped(Pipe)

		public var location: Syntax.NodeLocation {
			switch self {
			case .literal(let literal):
				literal.location
			case .unary(let unary):
				unary.location
			case .binary(let binary):
				binary.location
			case .nominal(let nominal):
				nominal.location
			case .typeDefinition(let record):
				record.location
			case .function(let function):
				function.location
			case .call(let call):
				call.location
			case .access(let access):
				access.location
			case .binding(let binding):
				binding.location
			case .taggedExpression(let taggedExpression):
				taggedExpression.location
			case .branched(let branched):
				branched.location
			case .piped(let piped):
				piped.location
			}
		}
	}

	/// Literals representing literal compile time constants
	public struct Literal: SyntaxNode, Sendable {
		/// Different literal options
		public enum Value: Equatable, Codable, Sendable {
			/// Nothing representing the unit type
			case nothing
			/// Type representing the empty set, used for fatal errors, panics, and unreachable states
			case never
			/// Integer literals
			case intLiteral(UInt64)
			/// Float literals
			case floatLiteral(Double)
			/// String literals
			case stringLiteral(String)
			/// Boolean literals
			case boolLiteral(Bool)
		}

		let value: Value
		public let location: NodeLocation

		init(value: Value, location: NodeLocation = .nowhere) {
			self.value = value
			self.location = location
		}
	}

	/// Expression with prefix operator
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

	/// Epxression with infix operator
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

	/// Record literal,
	/// Represents the building block of algebraic data structures
	public struct TypeDefinition: SyntaxNode, Sendable {
		let expressions: [Expression]
		public let location: NodeLocation

		init(
			expressions: [Expression],
			location: NodeLocation = .nowhere
		) {
			self.expressions = expressions
			self.location = location
		}
	}

	// MARK: - Function Definitions and Function Values

	/// Function expression
	/// Functions are the main data type, everything is a function.
	/// There is mainly two types of functions,
	/// compile time functions and runtime functions.
	/// Compile time functions represents generics and can be used for macros and code gen.
	/// TODO: get into compile time functions
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

	/// Function type: represents the type of functions
	/// Supports both traditional and dependently-typed function signatures
	/// - inputType: Optional input type for the function
	public struct FunctionType: SyntaxNode, Sendable {
		let inputType: Expression?
		let arguments: [Expression]
		let outputType: Expression
		public let location: NodeLocation

		init(
			inputType: Expression? = nil,
			arguments: [Expression] = [],
			outputType: Expression,
			location: NodeLocation = .nowhere
		) {
			self.inputType = inputType
			self.arguments = arguments
			self.outputType = outputType
			self.location = location
		}
	}

	/// Call expressions representing function calls,
	/// type initializers, and generic realizations
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

	/// Record field access
	/// Represents access to internal field of a product type
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

	/// Binding expression inside a branch capture group
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

	/// An expression with a label/tag for pattern matching and named parameters
	public struct TaggedExpression: SyntaxNode, Sendable {
		let tag: QualifiedIdentifier
		let typeSpecifier: Expression?
		let expression: Expression
		public let location: NodeLocation

		init(
			tag: QualifiedIdentifier,
			typeSpecifier: Expression?,
			expression: Expression,
			location: NodeLocation = .nowhere
		) {
			self.tag = tag
			self.typeSpecifier = typeSpecifier
			self.expression = expression
			self.location = location
		}
	}

	public struct DocString: Codable, Sendable, SyntaxNode {
		let content: String
		public let location: Syntax.NodeLocation
	}

	/// Branching expression for pattern matching

	/// # Attributes:
	///	- branches: List of branches in the pattern match
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

	/// Pipe expression for chaining operations
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
