extension Semantic.Context {
    func display() -> String {
        self.definitions.display()
    }
}

extension Semantic.DefinitionsContext {
    func display() -> String {
        self.valueDefinitions.map { signature, expression in
            "sign: \(signature.display()) -> exp: \(expression.display())"
        }.joined(separator: "\n---\n")

    }
}

extension Semantic.ExpressionSignature {
    func display() -> String {
        switch self {
        case let .function(function):
            function.display()
        case let .value(value):
            value.display()
        }
    }
}

extension Semantic.FunctionSignature {
    func display() -> String {
        // TODO: display type arguments
        "\(self.identifier.display())"
    }
}

extension Semantic.ScopedIdentifier {
    func display() -> String {
        self.chain.joined(separator: "::")
    }
}

extension Semantic.Tag {
    func display() -> String {
        switch self {
        case let .named(name):
            name
        case let .unnamed(value):
            "_\(value)"
        }
    }
}

extension Semantic.TypeSpecifier {
    func display() -> String {
        switch self {
        case let .nominal(nominal):
            nominal.display()
        case let .raw(raw):
            "()"
        }
    }
}

extension Semantic.Expression {
    func display() -> String {
        switch self.expressionType {
        case let .intLiteral(value):
            return "\(value)"
        case let .floatLiteral(value):
            return "\(value)"
        case let .boolLiteral(value):
            return "\(value)"
        case let .input:
            return "\(self.type.display())(in)"
        case let .fieldInScope(tag):
            return "\(tag.display())"
        case let .unary(op, expression):
            return
                "\(self.type.display())(\(op.rawValue) \(expression.display()))"
        case let .binary(op, left, right):
            return
                "\(self.type.display())(\(left.display()) \(op.rawValue) \(right.display()))"
        case let .call(signature, input, arguments):
            return "\(signature.display())(in: \(input.display()), )"
        case let .branching(branches: branches):
            return branches.map { "guard: \($0.guard.display()), body: \($0.body.display())" }
                .joined(separator: "\n")
        default:
            print(self.expressionType)
            return ""
        }
    }
}
