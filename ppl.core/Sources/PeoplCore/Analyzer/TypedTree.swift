enum Typed {

    typealias FunctionIdentifier = String
    typealias TypeName = String
    typealias ParamDefinition = (name: String, type: TypeId)

    enum TypeId {
        case nothing
        case never
        case nominal(TypeName)
        case lambda
        case unnamedTuple([TypeId])
        case namedTuple([ParamDefinition])
        case union([TypeId])
    }

    enum Builtins {}

    typealias Argument = (name: String, value: Expression)
    // struct FunctionDefinition {
    //     let inputType: TypeId
    //     let nam: FunctionIdentifier
    //     let params: [ParamDefinition]
    //     let outputType: TypeId
    //     let body: Expression
    // }
    //
    // struct OperatorOverloadDefinition {
    //     let left: TypeId
    //     let op: String
    //     let right: TypeId
    //     let output: TypeId
    //     let body: Expression
    // }
    //
    // enum TypeDefinition {
    //     case simple(identifier: TypeName, params: [ParamDefinition])
    //     case sum(
    //         identifier: TypeName,
    //         cases: [(identifier: TypeName, params: ParamDefinition)])
    // }

    indirect enum Expression {

        struct Callable {}
        struct Branch {}

        case nothing
        case never
        case intLiteral(value: UInt64)
        case floatLiteral(value: Double)
        case stringLiteral(value: String)
        case boolLiteral(value: Bool)
        case unary(Operator, expression: Expression, type: TypeId)
        case binary(Operator, left: Expression, right: Expression, type: TypeId)
        case unnamedTuple([Expression], type: TypeId)
        case namedTuple([Argument], type: TypeId)
        // case lambda(Expression, type: TypeIdentifier)
        case call(Callable, type: TypeId)
        // case access(Expression.Access, type: TypeIdentifier)
        case field(String, type: TypeId)
        case branched([Branch], type: TypeId)
        case piped(left: Expression, right: Expression, type: TypeId)

        var type: TypeId {
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
                // .lambda(_, let type), // WARN: this might not be correct
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
        let fields: [String: TypeId]
    }

}
struct SemanticContext {
    // let types: [TypeName: Syntax.TypeDefinition]
    // let functions: [FunctionDefinition: FunctionDefinition]
}
