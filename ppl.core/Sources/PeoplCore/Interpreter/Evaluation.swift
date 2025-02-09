
enum Evaluation: Encodable, Equatable, Sequence {

    struct NamedEvaluation: Encodable, Equatable {
        let name: String
        let value: Evaluation
    }

    struct Iterator: IteratorProtocol {
        private var content: [Evaluation]
        private var index: Int = 0

        init(_ evaluation: Evaluation) {
            switch evaluation {
            case .nothing, .int, .float, .string, .bool:
                content = [evaluation]
            case let .unnamedTuple(evaluations):
                content = evaluations
            case let .namedTuple(evaluations):
                content = evaluations.map { $0.value }
            }
        }

        mutating func next() -> Evaluation? {
            if index >= content.count {
                return nil
            }
            defer { index += 1 }
            return content[index]
        }
    }

    case nothing
    case int(Int)
    case float(Float)
    case string(String)
    case bool(Bool)
    case unnamedTuple([Evaluation])
    case namedTuple([NamedEvaluation])
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
        case let .unnamedTuple(evaluations):
            "[\(evaluations.map { $0.describe(formating: formating) }.joined(separator: ", "))]"
        case let .namedTuple(evaluations):
            "[\(evaluations.map { "\($0.name): \($0.value.describe(formating: formating))" }.joined(separator: ", "))]"
        }
    }

    var typeIdentifier: TypeIdentifier {
        return switch self {
        case .nothing:
                .nothing(location: .nowhere)
        case .int:
            .nominal(
                NominalType(
                    chain: [
                        FlatNominalType(
                            typeName: "I32",
                            typeArguments: [],
                            location: .nowhere)
                        ],
                    location: .nowhere))
        case .float:
            .nominal(
                NominalType(
                    chain: [
                        FlatNominalType(
                            typeName: "F64",
                            typeArguments: [],
                            location: .nowhere)
                        ],
                    location: .nowhere))
        case .string:
            .nominal(
                NominalType(
                    chain: [
                        FlatNominalType(
                            typeName: "String",
                            typeArguments: [],
                            location: .nowhere)
                        ],
                    location: .nowhere))
        case .bool:
            .nominal(
                NominalType(
                    chain: [
                        FlatNominalType(
                            typeName: "Bool",
                            typeArguments: [],
                            location: .nowhere)
                        ],
                    location: .nowhere))
        case .unnamedTuple(let evaluations):
            .unnamedTuple(.init(
                types: evaluations.map { $0.typeIdentifier },
                location: .nowhere))
        case .namedTuple(let evaluations):
            .namedTuple(.init(
                types: evaluations.map { 
                    ParamDefinition(
                        name: $0.name,
                        type: $0.value.typeIdentifier,
                        location: .nowhere)
                },
                location: .nowhere))
        }
    }

    var typeName: String {
        return switch self {
        case .nothing:
            "Nothing"
        case .int:
            "Int"
        case .float:
            "Float"
        case .string:
            "String"
        case .bool:
            "Bool"
        case let .unnamedTuple(types):
            "[\(types.map { $0.typeName }.joined(separator: ", "))]"
        case let .namedTuple(types):
            "[\(types.map { "\($0.name): \($0.value.typeName)" }.joined(separator: ", "))]"
        }
    }

    var count: Int {
        return switch self {
        case .nothing, .int, .float, .string, .bool:
            1
        case let .unnamedTuple(evaluations):
            evaluations.count
        case let .namedTuple(evaluations):
            evaluations.count
        }
    }

    func makeIterator() -> Iterator {
        return Iterator(self)
    }
}

struct EvaluationScope {
    var locals: [String: Evaluation]
    let functions: [FunctionDefinition: Expression]

    init() {
        self.init(locals: [:], functions: [:])
    }

    init(locals: [String: Evaluation]) {
        self.init(locals: locals, functions: [:])
    }

    init(locals: [String: Evaluation], functions: [FunctionDefinition: Expression]) {
        self.locals = locals
        self.functions = functions
    }
}


protocol Evaluable {
    func evaluate(
        with input: Evaluation, and scope: EvaluationScope
    ) -> Result<Evaluation, RuntimeError>
}

