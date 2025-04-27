enum Typed {

    typealias Identifier = String
    typealias TypeIdentifier = String
    typealias ParamDefinition = (name: String, type: TypeSpecifier)

    enum TypeSpecifier {
        case nothing
        case never
        case nominal(TypeIdentifier)
        case unnamedTuple([TypeSpecifier])
        case namedTuple([ParamDefinition])
    }

    enum Builtins {}

    typealias Argument = (name: String, value: Expression)

    indirect enum Expression {

        struct Callable {}
        struct Branch {}

        case nothing
        case never
        case intLiteral(value: UInt64)
        case floatLiteral(value: Double)
        case stringLiteral(value: String)
        case boolLiteral(value: Bool)
        case unary(Operator, expression: Expression, type: TypeSpecifier)
        case binary(Operator, left: Expression, right: Expression, type: TypeSpecifier)
        case unnamedTuple([Expression], type: TypeSpecifier)
        case namedTuple([Argument], type: TypeSpecifier)
        // case lambda(Expression, type: TypeIdentifier)
        case call(Callable, type: TypeSpecifier)
        // case access(Expression.Access, type: TypeIdentifier)
        case field(String, type: TypeSpecifier)
        case branched([Branch], type: TypeSpecifier)
        case piped(left: Expression, right: Expression, type: TypeSpecifier)

        var type: TypeSpecifier {
            switch self {
            case .nothing:
                return .nothing
            case .never:
                return .never
            case .intLiteral:
                return Builtins.i64
            case .floatLiteral:
                return Builtins.f64
            case .stringLiteral:
                return Builtins.string
            case .boolLiteral:
                return Builtins.bool
            case .unary(_, _, let type),
                .binary(_, _, _, let type),
                .unnamedTuple(_, let type),
                .namedTuple(_, let type),
                .call(_, let type),
                // .access(_, let type),
                .field(_, let type),
                .branched(_, let type),
                .piped(_, _, let type):
                return type
            }
        }
    }

    struct LocalScope {
        let fields: [Identifier: TypeSpecifier]
    }
}

struct SemanticContext {
    let types: [Typed.TypeIdentifier: Syntax.TypeDefinition]
    // let functions: [FunctionDefinition: FunctionDefinition]
}
