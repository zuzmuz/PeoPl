
fileprivate extension String {
    func peoplFormat(_ arguments: [Evaluation]) -> String {
        var result = self
        
        for argument in arguments {
            result = result.replacingOccurrences(of: "{}", with: argument.describe(formating: ""))
        }
        
        return result
    }
}

enum Evaluation: Encodable, Equatable {
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

struct EvaluationScope {
    let locals: [String: Evaluation]
    // let globals: 
}

protocol Evaluable {
    func evaluate(
        with input: Evaluation, and scope: EvaluationScope 
    ) -> Result<Evaluation, SemanticError>
}


extension Module: Evaluable {
    func evaluate(
        with input: Evaluation, and scope: EvaluationScope
    ) -> Result<Evaluation, SemanticError> {
        let main = self.statements.filter { statement in
            if case let .functionDefinition(functionDefinition) = statement {
                return functionDefinition.name == "main"
            }
            return false
        }
        guard main.count == 1, let main = main.first, case let .functionDefinition(main) = main else {
            return .failure(.mainFunctionNotFound)
        }
        return main.body.evaluate(with: input, and: scope)
    }
}

extension Expression: Evaluable {
    func evaluate(
        with input: Evaluation, and scope: EvaluationScope
    ) -> Result<Evaluation, SemanticError> {
        return .success(.nothing)
    }
}
//
// extension Expression: Evaluable {
//     func evaluate(
//         with input: Evaluation, and scope: [String: Evaluation]
//     ) -> Result<Evaluation, SemanticError> {
//         switch self {
//         case let .simple(simple):
//             simple.evaluate(with: input, and: scope)
//         case let .call(call):
//             call.evaluate(with: input, and: scope)
//         case let .branched(branched):
//             branched.evaluate(with: input, and: scope)
//         case let .piped(piped):
//             piped.evaluate(with: input, and: scope)
//         }
//     }
// }
//
// extension Expression.Simple: Evaluable {
//     func evaluate(
//         with input: Evaluation, and scope: [String: Evaluation]
//     ) -> Result<Evaluation, SemanticError> {
//         // print("evaluating simple \(self) \(input) with scope \(scope)")
//         return if case .nothing = input {
//             switch self {
//             case .nothing:
//                 .success(.nothing)
//             case let .intLiteral(int):
//                 .success(.int(int))
//             case let .floatLiteral(float):
//                 .success(.float(float))
//             case let .stringLiteral(string):
//                 .success(.string(string))
//             case let .boolLiteral(bool):
//                 .success(.bool(bool))
//             case let .positive(simple):
//                 simple.evaluate(with: input, and: scope)
//             case let .negative(simple):
//                 switch simple.evaluate(with: input, and:scope) {
//                 case let .success(.int(int)):
//                     .success(.int(-int))
//                 case let .success(.float(float)):
//                     .success(.float(-float))
//                 default:
//                     .failure(.invalidOperation)
//                 }
//             case let .not(simple):
//                 switch simple.evaluate(with: input, and: scope) {
//                 case let .success(.bool(bool)):
//                     .success(.bool(!bool))
//                 default:
//                     .failure(.invalidOperation)
//                 }
//             case let .plus(left, right):
//                 switch (left.evaluate(with: input, and: scope), right.evaluate(with: input, and: scope)) {
//                 case let (.success(.int(left)), .success(.int(right))):
//                     .success(.int(left + right))
//                 case let (.success(.float(left)), .success(.float(right))):
//                     .success(.float(left + right))
//                 default:
//                     .failure(.invalidOperation)
//                 }
//             case let .minus(left, right):
//                 switch (left.evaluate(with: input, and: scope), right.evaluate(with: input, and: scope)) {
//                 case let (.success(.int(left)), .success(.int(right))):
//                     .success(.int(left - right))
//                 case let (.success(.float(left)), .success(.float(right))):
//                     .success(.float(left - right))
//                 default:
//                     .failure(.invalidOperation)
//                 }
//             case let .times(left, right):
//                 switch (left.evaluate(with: input, and: scope), right.evaluate(with: input, and: scope)) {
//                 case let (.success(.int(left)), .success(.int(right))):
//                     .success(.int(left * right))
//                 case let (.success(.float(left)), .success(.float(right))):
//                     .success(.float(left * right))
//                 default:
//                     .failure(.invalidOperation)
//                 }
//             case let .by(left, right):
//                 switch (left.evaluate(with: input, and: scope), right.evaluate(with: input, and: scope)) {
//                 case let (.success(.int(left)), .success(.int(right))):
//                     .success(.int(left / right))
//                 case let (.success(.float(left)), .success(.float(right))):
//                     .success(.float(left / right))
//                 default:
//                     .failure(.invalidOperation)
//                 }
//             case let .mod(left, right):
//                 switch (left.evaluate(with: input, and: scope), right.evaluate(with: input, and: scope)) {
//                 case let (.success(.int(left)), .success(.int(right))):
//                     .success(.int(left % right))
//                 default:
//                     .failure(.invalidOperation)
//                 }
//             case let .equal(left, right):
//                 switch (left.evaluate(with: input, and: scope), right.evaluate(with: input, and: scope)) {
//                 case let (.success(.int(left)), .success(.int(right))):
//                     .success(.bool(left == right))
//                 case let (.success(.float(left)), .success(.float(right))):
//                     .success(.bool(left == right))
//                 case let (.success(.string(left)), .success(.string(right))):
//                     .success(.bool(left == right))
//                 default:
//                     .failure(.invalidOperation)
//                 }
//             case let .lessThan(left, right):
//                 switch (left.evaluate(with: input, and: scope), right.evaluate(with: input, and: scope)) {
//                 case let (.success(.int(left)), .success(.int(right))):
//                     .success(.bool(left < right))
//                 case let (.success(.float(left)), .success(.float(right))):
//                     .success(.bool(left < right))
//                 default:
//                     .failure(.invalidOperation)
//                 }
//             case let .lessThanEqual(left, right):
//                 switch (left.evaluate(with: input, and: scope), right.evaluate(with: input, and: scope)) {
//                 case let (.success(.int(left)), .success(.int(right))):
//                     .success(.bool(left <= right))
//                 case let (.success(.float(left)), .success(.float(right))):
//                     .success(.bool(left <= right))
//                 default:
//                     .failure(.invalidOperation)
//                 }
//             case let .greaterThan(left, right):
//                 switch (left.evaluate(with: input, and: scope), right.evaluate(with: input, and: scope)) {
//                 case let (.success(.int(left)), .success(.int(right))):
//                     .success(.bool(left > right))
//                 case let (.success(.float(left)), .success(.float(right))):
//                     .success(.bool(left > right))
//                 default:
//                     .failure(.invalidOperation)
//                 }
//             case let .greaterThanEqual(left, right):
//                 switch (left.evaluate(with: input, and: scope), right.evaluate(with: input, and: scope)) {
//                 case let (.success(.int(left)), .success(.int(right))):
//                     .success(.bool(left >= right))
//                 case let (.success(.float(left)), .success(.float(right))):
//                     .success(.bool(left >= right))
//                 default:
//                     .failure(.invalidOperation)
//                 }
//             case let .or(left, right):
//                 switch (left.evaluate(with: input, and: scope), right.evaluate(with: input, and: scope)) {
//                 case let (.success(.bool(left)), .success(.bool(right))):
//                     .success(.bool(left || right))
//                 default:
//                     .failure(.invalidOperation)
//                 }
//             case let .and(left, right):
//                 switch (left.evaluate(with: input, and: scope), right.evaluate(with: input, and: scope)) {
//                 case let (.success(.bool(left)), .success(.bool(right))):
//                     .success(.bool(left && right))
//                 default:
//                     .failure(.invalidOperation)
//                 }
//             case let .field(field):
//                 if let fieldValue = scope[field] {
//                     .success(fieldValue)
//                 } else {
//                     .failure(.fieldNotInScope(field))
//                 }
//             case let .parenthesized(expression):
//                 expression.evaluate(with: input, and: scope)
//             default:
//                 .failure(.notImplemented)
//             }
//         } else {
//             .failure(.invalidInputForExpression)
//         }
//     }
//
//     func getFields() -> Set<String> {
//         switch self {
//             case let .field(field):
//                 return Set([field])
//             case let .positive(simple), let .negative(simple), let .not(simple):
//                 return simple.getFields()
//             case let .plus(left, right), let .minus(left, right),
//                  let .times(left, right), let .by(left, right), let .mod(left, right),
//                  let .equal(left, right), let .different(left, right),
//                  let .lessThan(left, right), let .lessThanEqual(left, right),
//                  let .greaterThan(left, right), let .greaterThanEqual(left, right),
//                  let .or(left, right), let .and(left, right):
//                 return left.getFields().union(right.getFields())
//             // TODO: adding compoud
//             default:
//                 return Set()
//         }
//     }
// }
//
// extension Expression.Call: Evaluable {
//     func evaluate(
//         with input: Evaluation, and scope: [String: Evaluation]
//     ) -> Result<Evaluation, SemanticError> {
//         switch self.command {
//         case .field("print"):
//             if let format = (self.arguments.first { $0.name == "format" }) {
//                 let argument = format.value.evaluate(with: .nothing, and: scope)
//                 if case let .success(.string(format)) = argument {
//                     print(format.peoplFormat([input]))
//                 } else {
//                     return .failure(.notImplemented)
//                 }
//                 return .success(input)
//             } else {
//                 print(input.describe(formating: ""))
//                 return .success(input)
//             }
//         default:
//             return .failure(.notImplemented)
//         }
//     }
// }
//
// extension Expression.Branched: Evaluable {
//     func evaluate(
//         with input: Evaluation, and scope: [String: Evaluation]
//     ) -> Result<Evaluation, SemanticError> {
//
//         // TODO: handle tupe input differently
//         // print("evaluating branched")
//         do {
//             var scope = scope
//             let branch = try self.branches.filter { branch in
//                 guard let captureGroupExpression = branch.captureGroup.first else {
//                     throw SemanticError.noCaptureGroups
//                 }
//                 switch captureGroupExpression {
//                 case let .simple(simple):
//                     let fields = simple.getFields()
//                     let scopeFields = Set(scope.keys)
//                     let capturedInputSet = fields.union(scopeFields).symmetricDifference(scopeFields)
//                     // print("capturing, expression fields \(fields) scopw fields \(scopeFields) captured \(capturedInputSet)")
//
//                     if capturedInputSet.count > 1 {
//                         throw SemanticError.tooManyFieldsInCaptureGroup
//                     }
//                     if capturedInputSet.count == 1, let capturedInput = capturedInputSet.first {
//                         scope[capturedInput] = input
//                         if case .field = simple {
//                             return true
//                         } else {
//                             switch simple.evaluate(with: .nothing, and: scope) {
//                             case let .success(evaluation):
//                                 return evaluation == .bool(true)
//                             case let .failure(error):
//                                 throw error
//                             }
//                         }
//                     } else {
//                         switch simple.evaluate(with: .nothing, and: scope) {
//                         case let .success(evaluation):
//                             return evaluation == input
//                         case let .failure(error):
//                             throw error
//                         }
//                     }
//                 case let .call(call):
//                     // switch call {
//                     // case let .field(field):
//                     //     
//                     // }
//                     // nested pattern matching
//                     return true //assign to scope
//                 default:
//                     throw SemanticError.invalidCaptureGroup
//                 }
//             }.first
//
//             switch branch?.body {
//             case let .simple(simple):
//                 return simple.evaluate(with: .nothing, and: scope)
//             default:
//                 throw SemanticError.notImplemented
//             }
//         } catch let error as SemanticError {
//             return .failure(error)
//         } catch {
//             return .failure(.invalidOperation)
//         }
//     }
// }
//
// extension Expression.Piped: Evaluable {
//     func evaluate(
//         with input: Evaluation, and scope: [String: Evaluation]
//     ) -> Result<Evaluation, SemanticError> {
//         // print("piping  input \(input) scope \(scope)")
//         return switch self {
//         case let .normal(left, right):
//             switch left.evaluate(with: input, and: scope) {
//             case let .success(leftEvaluation):
//                 right.evaluate(with: leftEvaluation, and: scope)
//             case let .failure(error):
//                 .failure(error)
//             }
//         case let .unwrapping(left, right):
//             .failure(.notImplemented)
//         }
//     }
// }
//
