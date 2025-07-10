extension Lsp {
    public enum TextDocumentParams {
        public struct DidOpen: Codable, Sendable {
            public let textDocument: TextDocumentItem
        }

        public struct DidChange: Codable, Sendable {
            public let textDocument: VersionedTextDocumentIdentifier
            public let contentChanges: [TextDocumentContentChangeEvent]
        }

        public struct DidSave: Codable, Sendable {
            public let textDocument: TextDocumentIdentifier
            public let text: String?
        }
    }
    public struct TextDocumentIdentifier: Codable, Sendable {
        public let uri: String
    }

    public struct TextDocumentItem: Codable, Sendable {
        public let uri: String
        public let languageId: String
        public let version: Int
        public let text: String
    }

    public struct VersionedTextDocumentIdentifier: Codable, Sendable {
        public let uri: String
        public let version: Int
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
        public let start: Position
        public let end: Position

        public init(start: Position, end: Position) {
            self.start = start
            self.end = end
        }
    }

    public struct Position: Codable, Sendable {
        public let line: Int
        public let character: Int

        public init(line: Int, character: Int) {
            self.line = line
            self.character = character
        }
    }
}
