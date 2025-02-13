import Foundation

enum RuntimeError: LocalizedError, Encodable, Equatable {
    case mainFunctionNotFound
    case duplicateDefinitions(locations: [NodeLocation])
    case reachedNever(location: NodeLocation)
    case notImplemented(location: NodeLocation, description: String)
    case invalidOperation(location: NodeLocation, operation: String, left: String, right: String)
    case invalidInputForExpression(location: NodeLocation, expected: String, received: String)
    case typeMismatch(location: NodeLocation, left: String, right: String)
    case fieldNotInScope(location: NodeLocation, fieldName: String)
    case captureGroupCountMismatch(location: NodeLocation, inputCount: Int, captureCount: Int)
    case invalidCaptureGroup(location: NodeLocation)
    case tooManyFieldsInCaptureGroup(location: NodeLocation, fields: [String])
    case combination([RuntimeError])
    // case multipleDefinitions(type: NominalType)

    static func combine(errors: [RuntimeError]) -> RuntimeError {
        return .combination(errors.flatMap { error in
            if case let .combination(errors) = error {
                return errors
            }
            return [error]
        })
    }

    var errorDescription: String? {
        switch self {
        case .mainFunctionNotFound:
            "Main function not found"
        case let .duplicateDefinitions(locations):
            "Duplicate definitions \(locations.map { $0.pointRange })"
        case let .reachedNever(location):
            "Reached never \(location.pointRange)"
        case let .notImplemented(location, description):
            "Operation not implemented yet at \(location.pointRange), \(description)"
        case let .invalidOperation(location, operation, left, right):
            "Invalid operation at \(location) \(operation) on \(left) and \(right)"
        case let .invalidInputForExpression(location, expected, received):
            "Invalid input for expression at \(location.pointRange), expected \(expected), received \(received)"
        case let .typeMismatch(location, left, right):
            "Type mismatch at \(location.pointRange), left \(left), right: \(right)"
        case let .fieldNotInScope(location, field):
            "Field \"\(field)\" not in scope at \(location)"
        case let .captureGroupCountMismatch(location, inputCount, captureCount):
            "Capture group count mismatch at \(location.pointRange), inputs count = \(inputCount), while capture group counts \(captureCount)"
        case let .invalidCaptureGroup(location):
            "Invalid capture group at \(location.pointRange)"
        case let .tooManyFieldsInCaptureGroup(location, fields):
            "Too many fields in capture group at \(location.pointRange), with fields \(fields.joined(separator: ", "))"
        // case .multipleDefinitions:
        //     "Muliplte definition"
        case let .combination(errors):
            errors.compactMap { $0.errorDescription }.joined(separator: "\n")
        }
    }
}
