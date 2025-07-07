extension Lsp {
    public enum TextDocumentParams {
        public struct DidOpen: Codable, Sendable {
            let textDocument: TextDocumentItem
        }

        public struct DidChange: Codable, Sendable {
            let textDocument: VersionedTextDocumentIdentifier
            let contentChanges: [TextDocumentContentChangeEvent]
        }

        public struct DidSave: Codable, Sendable {
            let textDocument: TextDocumentIdentifier
            let text: String?
        }
    }
    public struct TextDocumentIdentifier: Codable, Sendable {
        let uri: String
    }

    public struct TextDocumentItem: Codable, Sendable {
        let uri: String
        let languageId: String
        let version: Int
        let text: String
    }

    public struct VersionedTextDocumentIdentifier: Codable, Sendable {
        let uri: String
        let version: Int
    }

    public enum TextDocumentContentChangeEvent: Codable, Sendable {
        case full(text: String)
        case range(range: Range, text: String)

        enum CodingKeys: String, CodingKey {
            case range
            case text
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            if let range = try? container.decode(Range.self, forKey: .range) {
                let text = try container.decode(String.self, forKey: .text)
                self = .range(range: range, text: text)
            } else {
                let text = try container.decode(String.self, forKey: .text)
                self = .full(text: text)
            }
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            switch self {
            case let .full(text):
                try container.encode(text, forKey: .text)
            case let .range(range, text):
                try container.encode(range, forKey: .range)
                try container.encode(text, forKey: .text)
            }
        }
    }

    public struct Range: Codable, Sendable {
        let start: Position
        let end: Position

        public init(start: Position, end: Position) {
            self.start = start
            self.end = end
        }
    }

    public struct Position: Codable, Sendable {
        let line: Int
        let character: Int

        public init(line: Int, character: Int) {
            self.line = line
            self.character = character
        }
    }
}
