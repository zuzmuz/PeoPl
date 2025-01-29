import Foundation

enum SemanticError: LocalizedError {
    case sourceUnreadable
    case mainFunctionNotFound
    // case multipleDefinitions(type: NominalType)

    var errorDescription: String? {
        switch self {
        case .sourceUnreadable:
            "Source unreadable"
        case .mainFunctionNotFound:
            "Main function not found"
        // case .multipleDefinitions:
        //     "Muliplte definition"
        }
    }
}
