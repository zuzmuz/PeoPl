import Lsp

enum LspCommand: String {
    case proxy
    case socket
}

enum PpLsp {
}

extension Syntax.Error {
    var lspRange: Lsp.Range {
        switch self {
        case .rangeNotInContent, .languageNotSupported, .sourceUnreadable:
            return .init(
                start: .init(line: 0, character: 0),
                end: .init(line: 0, character: 0))
        case .notImplemented(_, let location),
            .errorParsing(_, let location):
            return .init(
                start: .init(
                    line: location.pointRange.lowerBound.line,
                    character: location.pointRange.lowerBound.column / 2),
                end: .init(
                    line: location.pointRange.upperBound.line,
                    character: location.pointRange.upperBound.column / 2))
        }
    }
}
