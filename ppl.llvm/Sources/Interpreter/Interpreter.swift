


protocol Evaluable {
    func evaluate() -> Expression
}

extension Statement {
    func evaluate() -> Expression {
        .simple(.nothing)
    }
}

extension Project {
    func evalualte() -> Expression {
        .simple(.nothing)
    }
}
