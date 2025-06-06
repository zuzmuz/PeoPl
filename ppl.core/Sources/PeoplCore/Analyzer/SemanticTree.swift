// MARK: Language Semantic Tree
// ============================
// This file defines the semantic tree structure of valid type checked
// Peopl code.

enum Semantic {

    // typealias DefinitionHash = Int
    enum Tag: Hashable {
        case named(String)
        case unnamed(UInt64)
    }

    struct ScopedIdentifier: Hashable {
        let chain: [String]
    }

    struct OperatorField: Hashable {
        let left: TypeSpecifier
        let right: TypeSpecifier
        let op: Operator
    }

    struct Context {
        let typeDefinitions: [ScopedIdentifier: Semantic.RawTypeSpecifier]
        let valueDefinitions: [ScopedIdentifier: Semantic.Expression]
        let typeLookup: [ScopedIdentifier: Syntax.TypeDefinition]
        let valueLookup: [ScopedIdentifier: Syntax.ValueDefinition]
        let operators: [OperatorField: Expression]
    }

    struct LocalScope {
    }

    enum IntrinsicType: Hashable {
        case never
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

        // NOTE: Builtin types are nominal types that are mapped to raw intrinsic types
        // NOTE: Intrinsic types can't be directly used
        static let uint = TypeSpecifier.nominal(.init(chain: ["U32"]))
        static let int = TypeSpecifier.nominal(.init(chain: ["I32"]))
        static let float = TypeSpecifier.nominal(.init(chain: ["F64"]))
        static let string = TypeSpecifier.nominal(.init(chain: ["String"]))
        static let bool = TypeSpecifier.nominal(.init(chain: ["Bool"]))

        // FIX: Not like that
        static let nothing = TypeSpecifier.raw(.record([:]))
        static let never = TypeSpecifier.nominal(.init(chain: ["Never"]))
    }

    struct Function: Hashable {
    }

    struct Expression {
        let expression: ExpressionType
        let type: TypeSpecifier

        indirect enum ExpressionType {
            case intrinsic  // TODO: figure out.intrinsic functionality
            case nothing
            case never
            case intLiteral(UInt64)
            case floatLiteral(Double)
            case stringLiteral(String)
            case boolLiteral(Bool)

            case unary(Operator, expression: Expression)
            case binary(
                Operator,
                left: Expression,
                right: Expression)

            case call(
                prefix: Expression,
                arguments: [Expression])

            case initializer(
                arguments: [Expression])

            case access(prefix: Expression, field: String)

            case field(Syntax.ScopedIdentifier)
        }
    }
}
