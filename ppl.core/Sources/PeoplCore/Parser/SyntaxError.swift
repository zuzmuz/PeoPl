import Foundation

enum SyntaxError: LocalizedError, Equatable {
    case sourceUnreadable
    case rangeNotInContent
    case errorParsing(
        element: String,
        location: Syntax.NodeLocation
    )
    case mixingNamedAndUnnamed(location: Syntax.NodeLocation)
}
