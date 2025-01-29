import Foundation

enum SemanticError: LocalizedError, Encodable {
    case sourceUnreadable
    case mainFunctionNotFound
    case notImplemented
    case invalidOperation
    case invalidInputForExpression
    case noCaptureGroups
    case invalidCaptureGroup
    // case multipleDefinitions(type: NominalType)

    var errorDescription: String? {
        switch self {
        case .sourceUnreadable:
            "Source unreadable"
        case .mainFunctionNotFound:
            "Main function not found"
        case .notImplemented:
            "Not implemented"
        case .invalidOperation:
            "Invalid operation"
        case .invalidInputForExpression:
            "Invalid input for expression"
        case .noCaptureGroups:
            "No capture groups"
        case .invalidCaptureGroup:
            "Invalid capture group"
        // case .multipleDefinitions:
        //     "Muliplte definition"
        }
    }
}
