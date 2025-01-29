
enum Evaluation: Encodable {
    case nothing
    case int(Int)
    case float(Float)
    case string(String)
    case bool(Bool)
    // case nominalType ...
}

protocol Evaluable {
    func evaluate() -> Result<Evaluation, SemanticError>
}


extension Project: Evaluable {
    func evaluate() -> Result<Evaluation, SemanticError> {
        self.main.body.evaluate()
    }
}

extension Expression: Evaluable {
    func evaluate() -> Result<Evaluation, SemanticError> {
        switch self {
        case .branched(_):
            .failure(.notImplemented)
        case let .call(call):
            call.evaluate()
        case .piped(_):
            .failure(.notImplemented)
        case let .simple(simple):
            simple.evaluate()
        }
    }
}

extension Expression.Simple: Evaluable {
    func evaluate() -> Result<Evaluation, SemanticError> {
        switch self {
        case .nothing:
            .success(.nothing)
        case let .intLiteral(int):
            .success(.int(int))
        case let .floatLiteral(float):
            .success(.float(float))
        case let .stringLiteral(string):
            .success(.string(string))
        case let .boolLiteral(bool):
            .success(.bool(bool))
        case let .positive(simple):
            simple.evaluate()
        case let .negative(simple):
            switch simple.evaluate() {
            case let .success(.int(int)):
                .success(.int(-int))
            case let .success(.float(float)):
                .success(.float(-float))
            default:
                .failure(.invalidOperation)
            }
        case let .not(simple):
            switch simple.evaluate() {
            case let .success(.bool(bool)):
                .success(.bool(!bool))
            default:
                .failure(.invalidOperation)
            }
        case let .plus(left, right):
            switch (left.evaluate(), right.evaluate()) {
            case let (.success(.int(left)), .success(.int(right))):
                .success(.int(left + right))
            case let (.success(.float(left)), .success(.float(right))):
                .success(.float(left + right))
            default:
                .failure(.invalidOperation)
            }
        case let .minus(left, right):
            switch (left.evaluate(), right.evaluate()) {
            case let (.success(.int(left)), .success(.int(right))):
                .success(.int(left - right))
            case let (.success(.float(left)), .success(.float(right))):
                .success(.float(left - right))
            default:
                .failure(.invalidOperation)
            }
        case let .times(left, right):
            switch (left.evaluate(), right.evaluate()) {
            case let (.success(.int(left)), .success(.int(right))):
                .success(.int(left * right))
            case let (.success(.float(left)), .success(.float(right))):
                .success(.float(left * right))
            default:
                .failure(.invalidOperation)
            }
        case let .by(left, right):
            switch (left.evaluate(), right.evaluate()) {
            case let (.success(.int(left)), .success(.int(right))):
                .success(.int(left / right))
            case let (.success(.float(left)), .success(.float(right))):
                .success(.float(left / right))
            default:
                .failure(.invalidOperation)
            }
        case let .mod(left, right):
            switch (left.evaluate(), right.evaluate()) {
            case let (.success(.int(left)), .success(.int(right))):
                .success(.int(left % right))
            default:
                .failure(.invalidOperation)
            }
        case let .equal(left, right):
            switch (left.evaluate(), right.evaluate()) {
            case let (.success(.int(left)), .success(.int(right))):
                .success(.bool(left == right))
            case let (.success(.float(left)), .success(.float(right))):
                .success(.bool(left == right))
            case let (.success(.string(left)), .success(.string(right))):
                .success(.bool(left == right))
            default:
                .failure(.invalidOperation)
            }
        case let .lessThan(left, right):
            switch (left.evaluate(), right.evaluate()) {
            case let (.success(.int(left)), .success(.int(right))):
                .success(.bool(left < right))
            case let (.success(.float(left)), .success(.float(right))):
                .success(.bool(left < right))
            default:
                .failure(.invalidOperation)
            }
        case let .lessThanEqual(left, right):
            switch (left.evaluate(), right.evaluate()) {
            case let (.success(.int(left)), .success(.int(right))):
                .success(.bool(left <= right))
            case let (.success(.float(left)), .success(.float(right))):
                .success(.bool(left <= right))
            default:
                .failure(.invalidOperation)
            }
        case let .greaterThan(left, right):
            switch (left.evaluate(), right.evaluate()) {
            case let (.success(.int(left)), .success(.int(right))):
                .success(.bool(left > right))
            case let (.success(.float(left)), .success(.float(right))):
                .success(.bool(left > right))
            default:
                .failure(.invalidOperation)
            }
        case let .greaterThanEqual(left, right):
            switch (left.evaluate(), right.evaluate()) {
            case let (.success(.int(left)), .success(.int(right))):
                .success(.bool(left >= right))
            case let (.success(.float(left)), .success(.float(right))):
                .success(.bool(left >= right))
            default:
                .failure(.invalidOperation)
            }
        case let .or(left, right):
            switch (left.evaluate(), right.evaluate()) {
            case let (.success(.bool(left)), .success(.bool(right))):
                .success(.bool(left || right))
            default:
                .failure(.invalidOperation)
            }
        case let .and(left, right):
            switch (left.evaluate(), right.evaluate()) {
            case let (.success(.bool(left)), .success(.bool(right))):
                .success(.bool(left && right))
            default:
                .failure(.invalidOperation)
            }
        default:
            .failure(.notImplemented)
        }
    }
}

extension Expression.Call: Evaluable {
    func evaluate() -> Result<Evaluation, SemanticError> {
        switch self.command {
        case .field("print"):
            if let format = (self.arguments.first { $0.name == "format" }) {
                let argument = format.value.evaluate()
                if case let .success(.string(format)) = argument {
                    print(format)
                } else {
                    return .failure(.notImplemented)
                }
                return .success(.nothing)
            }
            return .failure(.notImplemented)
        default:
            return .failure(.notImplemented)
        }
    }
}
