import Foundation

extension Lsp {

    enum DecodingResult {
        case request(RequestMessage)
        case notification(NotificationMessage)
        case error(String)
        case incomplete
    }

    struct RPCCoder {
        func decode(data: Data) -> (result: DecodingResult, rest: Data?) {
            guard
                let separatorRange = data.firstRange(
                    of: Data("\r\n\r\n".utf8))
            else {
                return (.error("No separator found"), nil)
            }

            let header = data.prefix(upTo: separatorRange.lowerBound)

            guard
                let bodySizeString = String(
                    data: header.suffix(from: header.startIndex + 16),
                    encoding: .utf8),
                let bodySize = Int(bodySizeString)
            else {
                return (.error("Failed to parse content length"), nil)
            }

            let bodyRange =
                separatorRange.upperBound..<separatorRange.upperBound + bodySize
            if bodyRange.upperBound > data.endIndex {
                return (.incomplete, data)
            }
            let body = data.subdata(in: bodyRange)
            let rest: Data? =
                if bodyRange.upperBound >= data.count - 1 {
                    nil
                } else {
                    data.suffix(from: bodyRange.upperBound)
                }

            let decoder = JSONDecoder()
            if let request = try? decoder.decode(
                RequestMessage.self, from: body)
            {
                return (.request(request), rest)
            } else if let notification = try? decoder.decode(
                NotificationMessage.self, from: body)
            {
                return (.notification(notification), rest)
            } else if let unknown = try? decoder.decode(
                UnknownMessage.self, from: body)
            {
                return (.error("Unkown method \(unknown.method)"), rest)
            } else {
                return (.error("Failed to decode message"), rest)
            }
        }

        func encode(response: ResponseMessage) -> Data? {
            let encoder = JSONEncoder()
            if let body = try? encoder.encode(response) {
                let header = Data("Content-Length: \(body.count)\r\n\r\n".utf8)
                return header + body
            }
            return nil
        }
    }

    // swiftlint:disable:next type_name
    public enum Id: Codable, Sendable {
        case int(Int)
        case string(String)

        public init(from decoder: Decoder) throws {
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

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case let .int(int):
                try container.encode(int)
            case let .string(string):
                try container.encode(string)
            }
        }
    }

    public struct RequestMessage: Codable, Sendable {
        public let jsonrpc: String
        public let id: Id
        public let method: Method

        public enum Method: Codable, Sendable {
            case initialize(InitializeParams)
            case diagnostic(DocumentDiagnosticParams)
            // case completion(CompletionParams)
            // case foldingRange(FoldingRangeParams)
            // case semanticTokensFull(SematanicTokensFullParams)
            case shutdown

            var name: MethodName {
                switch self {
                case .initialize:
                    return .initialize
                case .shutdown:
                    return .shutdown
                case .diagnostic:
                    return .diagnostic
                // case .completion:
                //     return .completion
                // case .foldingRange:
                //     return .foldingRange
                // case .semanticTokensFull:
                //     return .semanticTokensFull
                }
            }

            enum MethodName: String, Codable {
                case initialize
                case shutdown
                case diagnostic = "textDocument/diagnostic"
                // case completion = "textDocument/completion"
                // case foldingRange = "textDocument/foldingRange"
                // case semanticTokensFull = "textDocument/semanticTokens/full"
            }

            enum ParamCodingKeys: CodingKey {
                case method
                case params
            }

            public init(from decoder: Decoder) throws {
                let container = try decoder.container(
                    keyedBy: ParamCodingKeys.self)

                let method = try container.decode(
                    MethodName.self, forKey: .method)

                switch method {
                case .initialize:
                    self = .initialize(
                        try container.decode(
                            InitializeParams.self,
                            forKey: .params))
                case .diagnostic:
                    self = .diagnostic(
                        try container.decode(
                            DocumentDiagnosticParams.self,
                            forKey: .params))
                case .shutdown:
                    self = .shutdown
                }
            }

            public func encode(to encoder: any Encoder) throws {
                var container = encoder.container(keyedBy: ParamCodingKeys.self)
                try container.encode(self.name, forKey: .method)
                switch self {
                case let .initialize(params):
                    try container.encode(params, forKey: .params)
                case let .diagnostic(params):
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

    public struct NotificationMessage: Codable, Sendable {
        let jsonrpc: String
        public let method: Method

        public enum Method: Codable, Sendable {
            case initialized
            case exit
            case didOpenTextDocument(TextDocumentParams.DidOpen)
            case didChangeTextDocument(TextDocumentParams.DidChange)
            case didSaveTextDocument(TextDocumentParams.DidSave)

            var name: MethodName {
                switch self {
                case .initialized:
                    return .initialized
                case .exit:
                    return .exit
                case .didOpenTextDocument:
                    return .didOpenTextDocument
                case .didChangeTextDocument:
                    return .didChangeTextDocument
                case .didSaveTextDocument:
                    return .didSaveTextDocument
                }
            }

            enum MethodName: String, Codable {
                case initialized
                case exit
                case didOpenTextDocument = "textDocument/didOpen"
                case didChangeTextDocument = "textDocument/didChange"
                case didSaveTextDocument = "textDocument/didSave"
            }

            enum ParamCodingKeys: CodingKey {
                case method
                case params
            }

            public init(from decoder: Decoder) throws {
                let container = try decoder.container(
                    keyedBy: ParamCodingKeys.self)

                let method = try container.decode(
                    MethodName.self,
                    forKey: .method)

                switch method {
                case .initialized:
                    self = .initialized
                case .exit:
                    self = .exit
                case .didOpenTextDocument:
                    self = .didOpenTextDocument(
                        try container.decode(
                            TextDocumentParams.DidOpen.self,
                            forKey: .params))
                case .didChangeTextDocument:
                    self = .didChangeTextDocument(
                        try container.decode(
                            TextDocumentParams.DidChange.self,
                            forKey: .params))
                case .didSaveTextDocument:
                    self = .didSaveTextDocument(
                        try container.decode(
                            TextDocumentParams.DidSave.self,
                            forKey: .params))
                }
            }

            public func encode(to encoder: any Encoder) throws {
                var container = encoder.container(keyedBy: ParamCodingKeys.self)
                try container.encode(self.name, forKey: .method)
                switch self {
                case .initialized:
                    break
                case .exit:
                    break
                case let .didOpenTextDocument(params):
                    try container.encode(params, forKey: .params)
                case let .didChangeTextDocument(params):
                    try container.encode(params, forKey: .params)
                case let .didSaveTextDocument(params):
                    try container.encode(params, forKey: .params)
                }
            }
        }

        enum CodingKeys: CodingKey {
            case jsonrpc
            case method
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            self.jsonrpc = try container.decode(String.self, forKey: .jsonrpc)
            self.method = try Method(from: decoder)
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(jsonrpc, forKey: .jsonrpc)
            try self.method.encode(to: encoder)
        }
    }

    public struct ResponseMessage: Codable, Sendable {
        let jsonrpc: String
        public let id: Id?
        public let result: Result<ResponseSuccess, ResponseError>?

        public init(
            id: Id? = nil,
            result: Result<ResponseSuccess, ResponseError>? = nil
        ) {
            self.jsonrpc = "2.0"
            self.id = id
            self.result = result
        }

        enum CodingKeys: String, CodingKey {
            case jsonrpc
            case id
            case result
            case error
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            self.jsonrpc = try container.decode(String.self, forKey: .jsonrpc)
            self.id = try container.decodeIfPresent(Id.self, forKey: .id)

            // if let result = try? container.decode(
            //     ResponseResult.self, forKey: .result)
            // {
            //     self.result = result
            // } else {
            self.result = nil
            // }
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            try container.encode(jsonrpc, forKey: .jsonrpc)
            try container.encode(id, forKey: .id)

            switch self.result {
            case let .failure(failure):
                try container.encode(failure, forKey: .error)
            case let .success(success):
                try container.encode(success, forKey: .result)
            case .none:
                break
            }
        }
    }

    public struct UnknownMessage: Codable {
        let method: String
    }

    public enum ResponseSuccess: Codable, Sendable {
        case initialize(InitializeResult)
        case diagnostic(DocumentDiagnosticReport)

        public func encode(to encoder: any Encoder) throws {
            switch self {
            case let .initialize(result):
                try result.encode(to: encoder)
            case let .diagnostic(result):
                try result.encode(to: encoder)
            }
        }
    }

    public enum ResponseError: Codable, Error {
        case uriNotFound

        enum CodingKeys: String, CodingKey {
            case code
            case message
        }

        var object: (code: Int, message: String) {
            switch self {
            case .uriNotFound: (1, "URI not found")
            }
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let code = try container.decode(Int.self, forKey: .code)
            let message = try container.decode(String.self, forKey: .message)

            switch (code, message) {
            case (420, "URI not found"):
                self = .uriNotFound
            default:
                throw DecodingError.dataCorruptedError(
                    forKey: .code,
                    in: container,
                    debugDescription: "Unknown code")
            }
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(object.code, forKey: .code)
            try container.encode(object.message, forKey: .message)
        }
    }
}
