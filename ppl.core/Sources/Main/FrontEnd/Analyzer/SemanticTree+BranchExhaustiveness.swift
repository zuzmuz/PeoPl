extension Syntax.Expression {
    func getPattern(
        localScope: borrowing Semantic.LocalScope,
        context: borrowing Semantic.DeclarationsContext
    ) throws(Semantic.Error) -> Semantic.Pattern {

        switch self {
        case .literal, .binary:
            return try .value(
                self.checkType(
                    with: .nothing,
                    localScope: localScope,
                    context: context))
        case let .nominal(nominal):
            if nominal.identifier.chain == ["_"] {
                return .wildcard
            } else {
                return try .value(
                    self.checkType(
                        with: .nothing,
                        localScope: localScope,
                        context: context))
            }
            
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
                try call.arguments.getPattern(
                    localScope: localScope, context: context))
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

extension [Syntax.Expression] {
    func getPattern(
        localScope: borrowing Semantic.LocalScope,
        context: borrowing Semantic.DeclarationsContext
    ) throws(Semantic.Error) -> [Semantic.Tag: Semantic.Pattern] {
        var patterns: [Semantic.Tag: Semantic.Pattern] = [:]
        var fieldCounter = UInt64(0)
        for expression in self {
            switch expression {
            case let .taggedExpression(taggedExpression):
                let expressionTag = Semantic.Tag.named(taggedExpression.tag)
                if patterns[expressionTag] != nil {
                    throw .init(
                        location: taggedExpression.location,
                        errorChoice: .duplicatedExpressionFieldName)
                }
                patterns[expressionTag] =
                    try taggedExpression.expression.getPattern(
                        localScope: localScope,
                        context: context)
            default:
                let expressionTag = Semantic.Tag.unnamed(fieldCounter)
                fieldCounter += 1
                // WARN: this might be buggy, I guess I should put this outside the switch
                if patterns[expressionTag] != nil {
                    throw .init(
                        location: expression.location,
                        errorChoice: .duplicatedExpressionFieldName)
                }
                patterns[expressionTag] =
                    try expression.getPattern(
                        localScope: localScope,
                        context: context)
            }
        }
        return patterns
    }
}

extension Semantic.Pattern {
    func typeCheck(
        with input: Semantic.Expression,
        localScope: borrowing Semantic.LocalScope,
        context: borrowing Semantic.DeclarationsContext
    ) throws(Semantic.PatternError) -> [Semantic.Tag: Semantic.Expression] {
        switch self {
        case .wildcard: return [:]
        case let .binding(tag):
            return [tag: input]
        case let .value(expression):
            if expression.type != input.type {
                throw .bindingTypeMismatch
            } else {
                return [:]
            }
        case let .destructor(patterns):
            let rawType = input.type.getRawType(
                typeDeclarations: context.typeDeclarations)
            switch rawType {
            case let .record(fields):
                guard fields.count == patterns.count else {
                    throw .numberOfPatternMismatch(
                        expected: fields.count, received: patterns.count)
                }

                var bindings: [Semantic.Tag: Semantic.Expression] = [:]

                for (tag, expression) in fields {
                }

                fatalError("implementing destructor pattern matching")
            default:
                // TODO: this is not maybe wrong
                throw .numberOfPatternMismatch(
                    expected: 1, received: patterns.count)

            }
        case let .constructor(tag, pattern):
            fatalError()
        // patterns.reduce(into: [:]) { pattern in
        //     pattern.type
        // }
        }
    }
}
