import Foundation

enum SemanticError: LocalizedError, Encodable, Equatable {
    case sourceUnreadable
    case mainFunctionNotFound
    case notImplemented
    case invalidOperation(location: NodeLocation, operation: String, left: String, right: String)
    case invalidInputForExpression(location: NodeLocation, expected: String, received: String)
    case typeMismatch(location: NodeLocation, left: String, right: String)
    case reachedNever(location: NodeLocation)
    case noCaptureGroups
    case invalidCaptureGroup
    case fieldNotInScope(String)
    case tooManyFieldsInCaptureGroup
    // case combination([SemanticError])
    // case multipleDefinitions(type: NominalType)

    var errorDescription: String? {
        switch self {
        case .sourceUnreadable:
            "Source unreadable"
        case .mainFunctionNotFound:
            "Main function not found"
        case .notImplemented:
            "Not implemented"
        case let .invalidOperation(location, operation, left, right):
            "Invalid operation at \(location) \(operation) on \(left) and \(right)"
        case let .invalidInputForExpression(location, expected, received):
            "Invalid input for expression at \(location.pointRange), expected \(expected), received \(received)"
        case let .typeMismatch(location, left, right):
            "Type mismatch at \(location.pointRange), left \(left), right: \(right)"
        case let .reachedNever(location):
            "Reached never \(location)"
        case .noCaptureGroups:
            "No capture groups"
        case .invalidCaptureGroup:
            "Invalid capture group"
        case let .fieldNotInScope(field):
            "Field \"\(field)\" not in scope"
        case .tooManyFieldsInCaptureGroup:
            "Too many fields in capture group"
        // case .multipleDefinitions:
        //     "Muliplte definition"
        // case let .combination(errors):
        //     errors.compactMap { $0.errorDescription }.joined(separator: "\n")
        }
    }
}
