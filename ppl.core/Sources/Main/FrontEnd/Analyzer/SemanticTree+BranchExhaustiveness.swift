extension Syntax.Expression {
    func getPattern(
        localScope: borrowing Semantic.LocalScope,
        context: borrowing Semantic.DeclarationsContext
    ) throws(Semantic.Error) -> Semantic.Pattern {

        switch self {
        case .literal, .binary, .nominal:
            return try .value(
                self.checkType(
                    with: .nothing,
                    localScope: localScope,
                    context: context))
        case let .unary(unary):
            if unary.op == .plus
                || unary.op == .minus
                || unary.op == .not
            {
                return try .value(
                    self.checkType(
                        with: .nothing,
                        localScope: localScope,
                        context: context))
            } else {
                throw .init(
                    location: location,
                    errorChoice: .illegalUnaryInMatch(op: unary.op))
            }
        case let .binding(binding):
            return .binding(.named(binding.identifier))
        case let .call(call):
            return .destructor(
                try call.arguments.map { argument throws(Semantic.Error) in
                    try argument.getPattern(
                        localScope: localScope, context: context)
                })
        case let .taggedExpression(taggedExpression):
            return .constructor(
                tag: .named(taggedExpression.tag),
                pattern: try taggedExpression.expression.getPattern(
                    localScope: localScope, context: context))
        default:
            throw .init(
                location: location,
                errorChoice: .notImplemented(
                    "advanced pattern matching feature"))
        }
    }
}

extension Semantic.Pattern {
    func getBindings() -> [Semantic.Tag] {
        switch self {
        case .wildcard, .value: return []
        case let .destructor(patterns):
            return patterns.flatMap { pattern in
                pattern.getBindings()
            }
        case let .constructor(_, pattern):
            return pattern.getBindings()
        case let .binding(binding):
            return [binding]
        }
    }
}
