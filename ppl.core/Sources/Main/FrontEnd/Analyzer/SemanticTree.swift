// MARK: Language Semantic Tree

// ============================
// This file defines the semantic tree structure of valid type checked
// Peopl code.

#if ANALYZER

public enum Semantic {
	public enum Tag: Hashable, Sendable {
		case input
		case named(String)
		case unnamed(UInt64)

		public func hash(into hasher: inout Hasher) {
			hasher.combine(id)
		}

		private var id: AnyHashable {
			switch self {
			case .input:
				// semantic input is a special tag
				return "#input#"
			case let .named(name):
				return name
			case let .unnamed(index):
				return "_\(index)"
			}
		}

		public static func == (
			lhs: Semantic.Tag,
			rhs: Semantic.Tag
		) -> Bool {
			return lhs.id == rhs.id
		}
	}

	public struct QualifiedIdentifier: Hashable, Sendable {
		let chain: [String]
	}

	public struct OperatorField: Hashable {
		let left: TypeSpecifier
		let right: TypeSpecifier
		let op: Operator
	}

	public typealias TypeLookupMap =
		[QualifiedIdentifier: Syntax.Definition]
	public typealias TypeDeclarationsMap = [QualifiedIdentifier: TypeSpecifier]
	public typealias FunctionLookupMap =
		[FunctionSignature: Syntax.Definition]
	public typealias FunctionDeclarationsMap =
		[FunctionSignature: TypeSpecifier]
	public typealias FunctionDefinitionsMap = [FunctionSignature: Expression]

	public enum ExpressionSignature: Hashable {
		case function(FunctionSignature)
		case value(QualifiedIdentifier)
	}

	public struct FunctionSignature: Hashable, Sendable {
		let identifier: QualifiedIdentifier
		let inputType: (tag: Tag, type: TypeSpecifier)
		let arguments: [Tag: TypeSpecifier]

		public func hash(into hasher: inout Hasher) {
			hasher.combine(identifier)
			hasher.combine(inputType.type)
			hasher.combine(Set(arguments.keys))
		}

		public static func == (
			lhs: Self,
			rhs: Self
		) -> Bool {
			return lhs.identifier == rhs.identifier
				&& lhs.inputType.type == rhs.inputType.type
				&& lhs.arguments.keys == rhs.arguments.keys
		}
	}

	public struct DefinitionsContext {
		let functionDefinitions: FunctionDefinitionsMap
		// let operators: [OperatorField: Expression]
		let typeDefinitions: TypeDeclarationsMap
	}

	public struct DeclarationsContext {
		let typeDeclarations: TypeDeclarationsMap
		let functionDeclarations: FunctionDeclarationsMap
		let operatorDeclarations: [OperatorField: TypeSpecifier]
		// stores values based on identifier only for better error reporting
	}

	public typealias LocalScope = [Tag: TypeSpecifier]

	public enum IntrinsicType: Hashable, Sendable {
		case uint
		case int
		case float
		case bool
	}

	public enum RawTypeSpecifier: Hashable, Sendable {
		case intrinsic(IntrinsicType)
		case record([Tag: TypeSpecifier])
		case choice([Tag: TypeSpecifier])
		case function(Function)
	}

	public enum TypeSpecifier: Hashable, Sendable {
		case raw(RawTypeSpecifier)
		case nominal(QualifiedIdentifier)
	}

	public struct Function: Hashable, Sendable {
		// FIX: what should I do with this, I kind of forgot
	}

	// FIX: these might be useful we'll see
	public struct FunctionDefinition: Sendable {
		let signature: FunctionSignature
		let body: Expression
	}

	public struct TypeDefinition: Sendable {
		let identifier: QualifiedIdentifier
		let rawType: RawTypeSpecifier
	}

	public indirect enum Expression: Sendable {
		case nothing
		case never
		case intLiteral(UInt64)
		case floatLiteral(Double)
		case stringLiteral(String)
		case boolLiteral(Bool)

		case input(type: TypeSpecifier)
		// NOTE: I might need this or not
		// case argument(tag: Tag, type: TypeSpecifier)
		case unary(Operator, expression: Expression, type: TypeSpecifier)
		case binary(
			Operator,
			left: Expression,
			right: Expression,
			type: TypeSpecifier
		)

		case initializer(
			type: TypeSpecifier,
			arguments: [Tag: Expression]
		)

		case call(
			signature: FunctionSignature,
			input: Expression,
			arguments: [Tag: Expression],
			type: TypeSpecifier
		)

		case fieldInScope(
			tag: Tag,
			type: TypeSpecifier
		)

		case access(
			expression: Expression,
			field: Tag,
			type: TypeSpecifier
		)

		case branched(
			matrix: DecompositionMatrix,
			type: TypeSpecifier
		)

		var type: TypeSpecifier {
			switch self {
			case .nothing: .nothing
			case .never: .never
			case .intLiteral: .int
			case .floatLiteral: .float
			case .boolLiteral: .bool
			case .stringLiteral: fatalError("not implemented")
			case let .input(type): type
			case let .unary(_, _, type): type
			case let .binary(_, _, _, type): type
			case let .initializer(type, _): type
			case let .call(_, _, _, type): type
			case let .fieldInScope(_, type): type
			case let .access(_, _, type): type
			case let .branched(_, type): type
			}
		}
	}

	public struct DecompositionMatrix: Sendable {
		struct Row: Sendable {
			let pattern: Pattern
			let bindings: [Tag: Expression]
			let guardExpression: Expression
			let body: Expression
		}

		let rows: [Row]
	}

	/// Match expression patterns
	/// This represents constructors of pattern in a match expression
	public enum Pattern: Sendable {
		/// the wildcard case, the pattern that matches any expression
		case wildcard
		/// matches any expression while binding the expression to a tag
		case binding(Tag)
		/// matches to an expression, usually a literal value or a constant
		case value(Expression)
		/// destructs records into multiple patterns
		case destructor([Tag: Pattern])
		/// to match for tags in choice types
		indirect case constructor(tag: Tag, pattern: Pattern)
	}
}

#endif
