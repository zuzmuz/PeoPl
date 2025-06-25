extension Lsp {

    // swiftlint:disable:next type_name
    enum Id: Codable {
        case int(Int)
        case string(String)

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let int = try? container.decode(Int.self) {
                self = .int(int)
            } else if let string = try? container.decode(String.self) {
                self = .string(string)
            } else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "ID must be either Int or String")
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case let .int(int):
                try container.encode(int)
            case let .string(string):
                try container.encode(string)
            }
        }
    }

    public struct RequestMessage: Codable {
        let jsonrpc: String
        let id: Id
        let method: Method

        enum Method: Codable {
            case initialize(InitializeParams)
            // case completion(CompletionParams)
            // case foldingRange(FoldingRangeParams)
            // case semanticTokensFull(SematanicTokensFullParams)
            case shutdown
            
            var label: String {
                switch self {
                case .initialize:
                    return "initialize"
                case .shutdown:
                    return "shutdown"
                // case .completion:
                //     return "textDocument/completion"
                // case .foldingRange:
                //     return "textDocument/foldingRange"
                // case .semanticTokensFull:
                //     return "textDocument/semanticTokens/full"
                }
            }

            enum ParamCodingKeys: CodingKey {
                case method
                case params
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.container(
                    keyedBy: ParamCodingKeys.self)

                let method = try container.decode(String.self, forKey: .method)

                switch method {
                case "initialize":
                    self = .initialize(
                        try InitializeParams(from: decoder))
                default:
                    throw DecodingError.dataCorruptedError(
                        forKey: .method, in: container,
                        debugDescription: "unknown method")
                }
            }

            func encode(to encoder: any Encoder) throws {
                var container = encoder.container(keyedBy: ParamCodingKeys.self)
                try container.encode(self.label, forKey: .method)
                switch self {
                case let .initialize(params):
                    try container.encode(params, forKey: .params)
                case .shutdown:
                    break
                }
            }
        }

        enum CodingKeys: CodingKey {
            case jsonrpc
            case id
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            self.jsonrpc = try container.decode(String.self, forKey: .jsonrpc)
            self.id = try container.decode(Id.self, forKey: .id)
            self.method = try Method(from: decoder)
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(jsonrpc, forKey: .jsonrpc)
            try container.encode(id, forKey: .id)
            try self.method.encode(to: encoder)
        }
    }

    public struct NotificationMessage: Codable {
        let jsonrpc: String
        let method: Method

        enum Method: String, Codable {
            case initialized
            case exit
            // case didOpenTextDocument = "textDocument/didOpen"
            // case didChangeTextDocument = "textDocument/didChange"
            // case didSaveTextDocument = "textDocument/didSave"
        }

        // enum Params: Codable {
        //     case initialized
        //     case exit
        // case didOpentTextDocument(TextDocumentParams.DidOpen)
        // case didChangeTextDocument(TextDocumentParams.DidChange)
        // case didSaveTextDocument(TextDocumentParams.DidSave)
        // }
    }

    public struct ResponseMessage: Codable {
        let jsonrpc: String
        let id: Id?
        // let result: Result<ResponseResult, ResponseError>
    }

    struct UnknownMessage: Codable {
        let method: String
    }

    enum ResponseResult: Codable {
        case sdf
    }

    enum ResponseError: Codable, Error {
        case dfg
    }
}
