import Foundation

extension Syntax {
    public enum Error: LocalizedError {
        case sourceUnreadable
        case notImplemented(
            element: String,
            location: Syntax.NodeLocation
        )
        case rangeNotInContent
        case errorParsing(
            element: String,
            location: Syntax.NodeLocation
        )

        public var errorDescription: String? {
            switch self {
            case .sourceUnreadable:
                return "Source is unreadable"
            case let .notImplemented(element, location):
                return "Feature not implemented for \(element) at \(location)"
            case .rangeNotInContent:
                return "Range is not in content"
            case let .errorParsing(element, location):
                return "Error parsing \(element) at \(location)"
            }
        }
    }
}
