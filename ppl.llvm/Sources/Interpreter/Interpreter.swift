
fileprivate extension String {
    func peoplFormat(_ arguments: [Evaluation]) -> String {
        var result = self
        
        for argument in arguments {
            result = result.replacingOccurrences(of: "{}", with: argument.describe(formating: ""))
        }
        
        return result
    }
}

enum Evaluation: Encodable {
    case nothing
    case int(Int)
    case float(Float)
    case string(String)
    case bool(Bool)
    // case nominalType ...

    func describe(formating: String) -> String {
        switch self {
        case .nothing:
            "nothing"
        case let .int(int):
            "\(int)"
        case let .float(float):
            String(format: formating, float)
        case let .string(string):
            string
        case let .bool(bool):
            "\(bool)"
        }
    }
}

protocol Evaluable {
    func evaluate(with input: Evaluation) -> Result<Evaluation, SemanticError>
}


extension Project: Evaluable {
    func evaluate(with input: Evaluation) -> Result<Evaluation, SemanticError> {
        self.main.body.evaluate(with: input)
    }
}

extension Expression: Evaluable {
    func evaluate(with input: Evaluation) -> Result<Evaluation, SemanticError> {
        switch self {
        case .branched(_):
            .failure(.notImplemented)
        case let .call(call):
            call.evaluate(with: input)
        case let .piped(piped):
            piped.evaluate(with: input)
        case let .simple(simple):
            simple.evaluate(with: .nothing)
        }
    }
}

extension Expression.Simple: Evaluable {
    func evaluate(with input: Evaluation) -> Result<Evaluation, SemanticError> {
        if case .nothing = input {
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
                simple.evaluate(with: input)
            case let .negative(simple):
                switch simple.evaluate(with: input) {
                case let .success(.int(int)):
                    .success(.int(-int))
                case let .success(.float(float)):
                    .success(.float(-float))
                default:
                    .failure(.invalidOperation)
                }
            case let .not(simple):
                switch simple.evaluate(with: input) {
                case let .success(.bool(bool)):
                    .success(.bool(!bool))
                default:
                    .failure(.invalidOperation)
                }
            case let .plus(left, right):
                switch (left.evaluate(with: input), right.evaluate(with: input)) {
                case let (.success(.int(left)), .success(.int(right))):
                    .success(.int(left + right))
                case let (.success(.float(left)), .success(.float(right))):
                    .success(.float(left + right))
                default:
                    .failure(.invalidOperation)
                }
            case let .minus(left, right):
                switch (left.evaluate(with: input), right.evaluate(with: input)) {
                case let (.success(.int(left)), .success(.int(right))):
                    .success(.int(left - right))
                case let (.success(.float(left)), .success(.float(right))):
                    .success(.float(left - right))
                default:
                    .failure(.invalidOperation)
                }
            case let .times(left, right):
                switch (left.evaluate(with: input), right.evaluate(with: input)) {
                case let (.success(.int(left)), .success(.int(right))):
                    .success(.int(left * right))
                case let (.success(.float(left)), .success(.float(right))):
                    .success(.float(left * right))
                default:
                    .failure(.invalidOperation)
                }
            case let .by(left, right):
                switch (left.evaluate(with: input), right.evaluate(with: input)) {
                case let (.success(.int(left)), .success(.int(right))):
                    .success(.int(left / right))
                case let (.success(.float(left)), .success(.float(right))):
                    .success(.float(left / right))
                default:
                    .failure(.invalidOperation)
                }
            case let .mod(left, right):
                switch (left.evaluate(with: input), right.evaluate(with: input)) {
                case let (.success(.int(left)), .success(.int(right))):
                    .success(.int(left % right))
                default:
                    .failure(.invalidOperation)
                }
            case let .equal(left, right):
                switch (left.evaluate(with: input), right.evaluate(with: input)) {
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
                switch (left.evaluate(with: input), right.evaluate(with: input)) {
                case let (.success(.int(left)), .success(.int(right))):
                    .success(.bool(left < right))
                case let (.success(.float(left)), .success(.float(right))):
                    .success(.bool(left < right))
                default:
                    .failure(.invalidOperation)
                }
            case let .lessThanEqual(left, right):
                switch (left.evaluate(with: input), right.evaluate(with: input)) {
                case let (.success(.int(left)), .success(.int(right))):
                    .success(.bool(left <= right))
                case let (.success(.float(left)), .success(.float(right))):
                    .success(.bool(left <= right))
                default:
                    .failure(.invalidOperation)
                }
            case let .greaterThan(left, right):
                switch (left.evaluate(with: input), right.evaluate(with: input)) {
                case let (.success(.int(left)), .success(.int(right))):
                    .success(.bool(left > right))
                case let (.success(.float(left)), .success(.float(right))):
                    .success(.bool(left > right))
                default:
                    .failure(.invalidOperation)
                }
            case let .greaterThanEqual(left, right):
                switch (left.evaluate(with: input), right.evaluate(with: input)) {
                case let (.success(.int(left)), .success(.int(right))):
                    .success(.bool(left >= right))
                case let (.success(.float(left)), .success(.float(right))):
                    .success(.bool(left >= right))
                default:
                    .failure(.invalidOperation)
                }
            case let .or(left, right):
                switch (left.evaluate(with: input), right.evaluate(with: input)) {
                case let (.success(.bool(left)), .success(.bool(right))):
                    .success(.bool(left || right))
                default:
                    .failure(.invalidOperation)
                }
            case let .and(left, right):
                switch (left.evaluate(with: input), right.evaluate(with: input)) {
                case let (.success(.bool(left)), .success(.bool(right))):
                    .success(.bool(left && right))
                default:
                    .failure(.invalidOperation)
                }
            default:
                .failure(.notImplemented)
            }
        } else {
            .failure(.invalidInputForExpression)
        }
    }
}

extension Expression.Call: Evaluable {
    func evaluate(with input: Evaluation) -> Result<Evaluation, SemanticError> {
        switch self.command {
        case .field("print"):
            if let format = (self.arguments.first { $0.name == "format" }) {
                let argument = format.value.evaluate(with: .nothing)
                if case let .success(.string(format)) = argument {
                    print(format.peoplFormat([input]))
                } else {
                    return .failure(.notImplemented)
                }
                return .success(input)
            } else {
                print(input.describe(formating: ""))
                return .success(input)
            }
        default:
            return .failure(.notImplemented)
        }
    }
}

extension Expression.Piped: Evaluable {
    func evaluate(with input: Evaluation) -> Result<Evaluation, SemanticError> {
        switch self {
        case let .normal(left, right):
            switch left.evaluate(with: input) {
            case let .success(leftEvaluation):
                right.evaluate(with: leftEvaluation)
            case let .failure(error):
                .failure(error)
            }
        case let .unwrapping(left, right):
            .failure(.notImplemented)
        }
    }
}

