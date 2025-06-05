// MARK: Language Semantic Tree
// ============================
// This file defines the semantic tree structure of valid type checked
// Peopl code.

enum Semantic {

    // typealias DefinitionHash = Int
    typealias Tag = String
    struct ScopedIdentifier: Hashable {
        let chain: [String]
    }

    struct OperatorField: Hashable {
        let left: TypeSpecifier
        let right: TypeSpecifier
        let op: Operator
    }

    struct Context {
        let typeDefinitions:
            [ScopedIdentifier: (
                type: TypeSpecifier,
                definition: Syntax.TypeDefinition
            )]

        let valueDefinition:
            [ScopedIdentifier: (
                value: Expression,
                definition: Syntax.ValueDefinition
            )]

        let operators: [OperatorField: Expression] = [
            .init(left: .int, right: .int, op: .plus): .init(
                expression: .builtin, type: .int),
            .init(left: .nothing, right: .int, op: .plus): .init(
                expression: .builtin, type: .int),
            .init(left: .int, right: .int, op: .minus): .init(
                expression: .builtin, type: .int),
            .init(left: .nothing, right: .int, op: .plus): .init(
                expression: .builtin, type: .int),
            .init(left: .int, right: .int, op: .times): .init(
                expression: .builtin, type: .int),
            .init(left: .int, right: .int, op: .by): .init(
                expression: .builtin, type: .int),
            .init(left: .int, right: .int, op: .modulo): .init(
                expression: .builtin, type: .int),

            .init(left: .float, right: .float, op: .plus): .init(
                expression: .builtin, type: .float),
            .init(left: .nothing, right: .float, op: .plus): .init(
                expression: .builtin, type: .float),
            .init(left: .float, right: .float, op: .minus): .init(
                expression: .builtin, type: .float),
            .init(left: .nothing, right: .int, op: .plus): .init(
                expression: .builtin, type: .int),
            .init(left: .float, right: .float, op: .times): .init(
                expression: .builtin, type: .float),
            .init(left: .float, right: .float, op: .by): .init(
                expression: .builtin, type: .float),

            .init(left: .int, right: .int, op: .equal): .init(
                expression: .builtin, type: .bool),
            .init(left: .int, right: .int, op: .different): .init(
                expression: .builtin, type: .bool),
            .init(left: .int, right: .int, op: .lessThan): .init(
                expression: .builtin, type: .bool),
            .init(left: .int, right: .int, op: .lessThanOrEqual): .init(
                expression: .builtin, type: .bool),
            .init(left: .int, right: .int, op: .greaterThan): .init(
                expression: .builtin, type: .bool),
            .init(left: .int, right: .int, op: .greaterThanOrEqual): .init(
                expression: .builtin, type: .bool),

            .init(left: .float, right: .float, op: .equal): .init(
                expression: .builtin, type: .bool),
            .init(left: .float, right: .float, op: .different): .init(
                expression: .builtin, type: .bool),
            .init(left: .float, right: .float, op: .lessThan): .init(
                expression: .builtin, type: .bool),
            .init(left: .float, right: .float, op: .lessThanOrEqual): .init(
                expression: .builtin, type: .bool),
            .init(left: .float, right: .float, op: .greaterThan): .init(
                expression: .builtin, type: .bool),
            .init(left: .float, right: .float, op: .greaterThanOrEqual): .init(
                expression: .builtin, type: .bool),

            .init(left: .string, right: .string, op: .equal): .init(
                expression: .builtin, type: .bool),
            .init(left: .string, right: .string, op: .different): .init(
                expression: .builtin, type: .bool),

            .init(left: .bool, right: .bool, op: .equal): .init(
                expression: .builtin, type: .bool),
            .init(left: .bool, right: .bool, op: .different): .init(
                expression: .builtin, type: .bool),
            .init(left: .bool, right: .bool, op: .and): .init(
                expression: .builtin, type: .bool),
            .init(left: .bool, right: .bool, op: .or): .init(
                expression: .builtin, type: .bool),
            .init(left: .nothing, right: .bool, op: .not): .init(
                expression: .builtin, type: .bool),
        ]

        init(
            typeDefinitions:
                [ScopedIdentifier: (
                    type: TypeSpecifier,
                    definition: Syntax.TypeDefinition
                )],
            valueDefinition:
                [ScopedIdentifier: (
                    value: Expression,
                    definition: Syntax.ValueDefinition
                )]

        ) {
            self.typeDefinitions = typeDefinitions
            self.valueDefinition = valueDefinition
        }
    }

    struct LocalScope {
    }

    enum TypeSpecifier: Hashable {
        case nothing
        case never
        case tuple([TypeSpecifier])
        case record([Tag: TypeSpecifier])
        case union([TypeSpecifier])
        case choice([Tag: TypeSpecifier])
        case nominal(ScopedIdentifier)  // TODO: consider generic
        case function(Function)

        static let int = TypeSpecifier.nominal(.init(chain: ["I32"]))
        static let float = TypeSpecifier.nominal(.init(chain: ["F64"]))
        static let string = TypeSpecifier.nominal(.init(chain: ["String"]))
        static let bool = TypeSpecifier.nominal(.init(chain: ["Bool"]))
    }

    struct Function: Hashable {
    }

    struct Expression {
        let expression: ExpressionType
        let type: TypeSpecifier

        indirect enum ExpressionType {
            case builtin  // TODO: figure out builtin functionality
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
