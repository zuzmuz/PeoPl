// MARK: Language Semantic Tree
// ============================
// This file defines the semantic tree structure of valid type checked
// Peopl code.

public enum Semantic {

    // typealias DefinitionHash = Int
    public enum Tag: Hashable, Sendable {
        case named(String)
        case unnamed(UInt64)

        public func hash(into hasher: inout Hasher) {
            switch self {
            case let .named(name):
                hasher.combine(name)
            case let .unnamed(index):
                hasher.combine("_\(index)")
            }
        }

        public static func == (
            lhs: Semantic.Tag,
            rhs: Semantic.Tag
        ) -> Bool {
            let lhsValue =
                switch lhs {
                case let .named(name):
                    name
                case let .unnamed(index):
                    "_\(index)"
                }
            let rhsValue =
                switch rhs {
                case let .named(name):
                    name
                case let .unnamed(index):
                    "_\(index)"
                }

            return lhsValue == rhsValue
        }
    }

    public struct ScopedIdentifier: Hashable, Sendable {
        let chain: [String]
    }

    public struct OperatorField: Hashable {
        let left: TypeSpecifier
        let right: TypeSpecifier
        let op: Operator
    }

    public typealias TypeLookupMap = [ScopedIdentifier: Syntax.TypeDefinition]
    public typealias TypeDeclarationsMap = [ScopedIdentifier: TypeSpecifier]
    public typealias ValueLookupMap =
        [ExpressionSignature: Syntax.ValueDefinition]
    public typealias ValueDeclarationsMap = [ExpressionSignature: TypeSpecifier]
    public typealias ValueDefinitionsMap = [ExpressionSignature: Expression]

    public enum ExpressionSignature: Hashable {
        case function(FunctionSignature)
        case value(ScopedIdentifier)
    }

    public struct FunctionSignature: Hashable, Sendable {
        public let identifier: ScopedIdentifier
        public let inputType: TypeSpecifier
        public let arguments: [Tag: TypeSpecifier]
    }

    public struct DefinitionsContext {
        public let valueDefinitions: ValueDefinitionsMap
        // let operators: [OperatorField: Expression]
    }

    public struct DeclarationsContext {
        public let typeDeclarations: TypeDeclarationsMap
        public let valueDeclarations: ValueDeclarationsMap
        public let operatorDeclarations: [OperatorField: TypeSpecifier]
        // stores values based on identifier only for better error reporting
    }

    public struct Context {
        public let definitions: DefinitionsContext
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
        case nominal(ScopedIdentifier)
    }

    public struct Function: Hashable, Sendable {
    }

    public struct Expression: Sendable {
        public let expressionType: ExpressionType
        public let type: TypeSpecifier

        public indirect enum ExpressionType: Sendable {
            case nothing
            case never
            case intLiteral(UInt64)
            case floatLiteral(Double)
            case stringLiteral(String)
            case boolLiteral(Bool)

            case input

            case unary(Operator, expression: Expression)
            case binary(
                Operator,
                left: Expression,
                right: Expression)

            case call(
                signature: FunctionSignature,
                input: Expression,
                arguments: [Tag: Expression])

            case branching(
                branches: [(
                    match: BindingExpression,
                    guard: Expression,
                    body: Expression
                )])

            // case branching(
            //     branches: [(match: Expression, body: Expression)])

            // case access(prefix: Expression, field: String)

            // TODO: function calls require an input, function signature and arguments

            // a.sdf(asd: asd) needs to be analyzed as 1 node
            // a.b.sdfds(asd: sdf)

            // case initializer(
            //     arguments: [Expression])
            //
            //
            // case field(Syntax.ScopedIdentifier)
            case fieldInScope(Tag)
        }

        static let nothing = Expression(
            expressionType: .nothing, type: .nothing)
    }

    public struct BindingExpression: Sendable {
        let condition: Expression
        let bindings: [Tag: TypeSpecifier]
        // TODO: figure out how to capture complicated expressions
    }
}
