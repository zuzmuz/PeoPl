import Foundation

enum SyntaxError: LocalizedError {
    case sourceUnreadable
    case rangeNotInContent
    case errorParsing(
        element: String,
        location: Syntax.NodeLocation
    )

    var errorDescription: String? {
        switch self {
        case .sourceUnreadable:
            return "Source is unreadable"
        case .rangeNotInContent:
            return "Range is not in content"
        case let .errorParsing(element, location):
            return "Error parsing \(element) at \(location)"
        }
    }
}
