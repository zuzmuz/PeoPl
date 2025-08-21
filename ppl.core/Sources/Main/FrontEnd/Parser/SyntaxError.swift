import Foundation

public extension Syntax {
	enum Error: LocalizedError, Codable {
		case languageNotSupported
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
			case .languageNotSupported:
				return "Error loading language parser"
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
