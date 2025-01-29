import Foundation

enum SemanticError: LocalizedError, Encodable {
    case sourceUnreadable
    case mainFunctionNotFound
    case notImplemented
    case invalidOperation
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
        // case .multipleDefinitions:
        //     "Muliplte definition"
        }
    }
}
