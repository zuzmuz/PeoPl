// MARK: Language Semantic Tree
// ============================
// This file defines the semantic tree structure of valid type checked
// Peopl code.

enum Semantic {

    // typealias DefinitionHash = Int
    enum Tag: Hashable {
        case named(String)
        case unnamed(UInt64)

        func hash(into hasher: inout Hasher) {
            switch self {
            case let .named(name):
                hasher.combine(name)
            case let .unnamed(index):
                hasher.combine("_\(index)")
            }
        }

        static func == (
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

    struct ScopedIdentifier: Hashable {
        let chain: [String]
    }

    struct OperatorField: Hashable {
        let left: TypeSpecifier
        let right: TypeSpecifier
        let op: Operator
    }

    typealias TypeLookupMap = [ScopedIdentifier: Syntax.TypeDefinition]
    typealias TypeDeclarationsMap = [ScopedIdentifier: TypeSpecifier]
    typealias ValueLookupMap = [ExpressionSignature: Syntax.ValueDefinition]
    typealias ValueDeclarationsMap = [ExpressionSignature: TypeSpecifier]
    typealias ValueDefinitionsMap = [ExpressionSignature: Expression]

    enum ExpressionSignature: Hashable {
        case function(FunctionSignature)
        case value(ScopedIdentifier)
    }

    struct FunctionSignature: Hashable {
        let identifier: ScopedIdentifier
        let inputType: TypeSpecifier
        let arguments: [Tag: TypeSpecifier]
    }

    struct DefinitionsContext {
        let valueDefinitions: ValueDefinitionsMap
        // let operators: [OperatorField: Expression]
    }

    struct DeclarationsContext {
        let typeDeclarations: TypeDeclarationsMap
        let valueDeclarations: ValueDeclarationsMap
        let operatorDeclarations: [OperatorField: TypeSpecifier]
        // stores values based on identifier only for better error reporting
    }

    struct Context {
        let definitions: DefinitionsContext
    }

    struct LocalScope {
        let scope: [Tag: TypeSpecifier]
    }

    enum IntrinsicType: Hashable {
        case uint
        case int
        case float
        case bool
    }

    enum RawTypeSpecifier: Hashable {
        case intrinsic(IntrinsicType)
        case record([Tag: TypeSpecifier])
        case choice([Tag: TypeSpecifier])
        case function(Function)
    }

    enum TypeSpecifier: Hashable {
        case raw(RawTypeSpecifier)
        case nominal(ScopedIdentifier)
    }

    struct Function: Hashable {
    }

    struct Expression {
        let expressionType: ExpressionType
        let type: TypeSpecifier

        indirect enum ExpressionType {
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
            // case fieldInScope(Tag)
        }

        static let nothing = Expression(
            expressionType: .nothing, type: .nothing)
    }
}
