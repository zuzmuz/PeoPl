extension Lsp {
    public struct DocumentDiagnosticParams: Codable, Sendable {
        let textDocument: TextDocumentIdentifier
        let identifier: String?
        let previousResultId: String?
    }

    public enum DocumentDiagnosticReport: Codable, Sendable {
        case full(
            resultId: String?,
            items: [Diagnostic],
            relatedDocuments: [String: DocumentDiagnosticReport]?)
        case unchanged(
            resultId: String,
            relatedDocuments: [String: DocumentDiagnosticReport]?)

        enum CodingKeys: String, CodingKey {
            case kind
            case resultId
            case items
            case relatedDocuments
        }

        enum Kind: String, Codable {
            case full
            case unchanged
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let kind = try container.decode(Kind.self, forKey: .kind)
            switch kind {
            case .full:
                let resultId = try container.decodeIfPresent(
                    String.self, forKey: .resultId)
                let items = try container.decode(
                    [Diagnostic].self, forKey: .items)
                let relatedDocuments = try container.decodeIfPresent(
                    [String: DocumentDiagnosticReport].self,
                    forKey: .relatedDocuments)
                self = .full(
                    resultId: resultId,
                    items: items,
                    relatedDocuments: relatedDocuments)
            case .unchanged:
                let resultId = try container.decode(
                    String.self,
                    forKey: .resultId)
                let relatedDocuments = try container.decodeIfPresent(
                    [String: DocumentDiagnosticReport].self,
                    forKey: .relatedDocuments)
                self = .unchanged(
                    resultId: resultId,
                    relatedDocuments: relatedDocuments)
            }
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case let .full(resultId, items, relatedDocuments):
                try container.encode(Kind.full, forKey: .kind)
                try container.encodeIfPresent(resultId, forKey: .resultId)
                try container.encode(items, forKey: .items)
                try container.encodeIfPresent(
                    relatedDocuments, forKey: .relatedDocuments)
            case let .unchanged(resultId, relatedDocuments):
                try container.encode(Kind.unchanged, forKey: .kind)
                try container.encode(resultId, forKey: .resultId)
                try container.encodeIfPresent(
                    relatedDocuments,
                    forKey: .relatedDocuments)
            }
        }
    }

    public struct Diagnostic: Codable, Sendable {
        let range: Range
        let severity: DiagnosticSeverity?
        let code: DiagnosticCode?
        let codeDescription: DiagnosticCodeDescription?
        let source: String?
        let message: String
        let tags: [DiagnosticTag]?
        let relatedInformation: [DiagnosticRelatedInformation]?

        public init(
            range: Range,
            severity: DiagnosticSeverity,
            code: DiagnosticCode? = nil,
            codeDescription: DiagnosticCodeDescription? = nil,
            source: String? = nil,
            message: String,
            tags: [DiagnosticTag]? = nil,
            relatedInformation: [DiagnosticRelatedInformation]? = nil
        ) {
            self.range = range
            self.severity = severity
            self.code = code
            self.codeDescription = codeDescription
            self.source = source
            self.message = message
            self.tags = tags
            self.relatedInformation = relatedInformation
        }
    }

    public enum DiagnosticSeverity: Int, Codable, Sendable {
        case error = 1
        case warning = 2
        case information = 3
        case hint = 4
    }

    public enum DiagnosticCode: Codable, Sendable {
        case integer(Int)
        case string(String)

        public func encode(to encoder: any Encoder) throws {
            switch self {
            case let .integer(value):
                try value.encode(to: encoder)
            case let .string(value):
                try value.encode(to: encoder)
            }
        }
    }

    public struct DiagnosticCodeDescription: Codable, Sendable {
        let href: String
    }

    public enum DiagnosticTag: Int, Codable, Sendable {
        case unnecessary = 1
        case deprecated = 2
    }

    public struct DiagnosticRelatedInformation: Codable, Sendable {
        let location: Location
        let message: String
    }

    public struct Location: Codable, Sendable {
        let uri: String
        let range: Range
    }
}

extension Syntax.Error {
    var lspRange: Lsp.Range {
        switch self {
        case .rangeNotInContent, .languageNotSupported, .sourceUnreadable:
            return .init(
                start: .init(line: 0, character: 0),
                end: .init(line: 0, character: 0))
        case .notImplemented(_, let location), .errorParsing(_, let location):
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
