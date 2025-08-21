import Foundation

public extension Lsp {
	protocol RpcMessageItem: Codable, CustomDebugStringConvertible {}

	internal enum DecodingResult {
		case request(RequestMessage)
		case notification(NotificationMessage)
		case response(ResponseMessage)
		case error(String)
		case incomplete
	}

	internal struct RpcCoder {
		func decode(data: Data) -> (result: DecodingResult, rest: Data?) {
			guard
				let separatorRange = data.firstRange(
					of: Data("\r\n\r\n".utf8)
				)
			else {
				return (.error("no separator found"), nil)
			}

			let header = data.prefix(upTo: separatorRange.lowerBound)

			guard
				let bodySizeString = String(
					data: header.suffix(from: header.startIndex + 16),
					encoding: .utf8
				),
				let bodySize = Int(bodySizeString)
			else {
				return (.error("failed to parse content length"), nil)
			}

			let bodyRange =
				separatorRange.upperBound ..< separatorRange.upperBound + bodySize
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
				RequestMessage.self, from: body
			) {
				return (.request(request), rest)
			} else if let notification = try? decoder.decode(
				NotificationMessage.self, from: body
			) {
				return (.notification(notification), rest)
			} else if let response = try? decoder.decode(
				ResponseMessage.self, from: body
			) {
				return (.response(response), rest)
			} else if let unknown = try? decoder.decode(
				UnknownMessage.self, from: body
			) {
				return (.error("unkown method \(unknown.method)"), rest)
			} else {
				return (.error("failed to decode message"), rest)
			}
		}

		func encode(message: any Encodable) -> Data? {
			let encoder = JSONEncoder()
			if let body = try? encoder.encode(message) {
				let header = Data("Content-Length: \(body.count)\r\n\r\n".utf8)
				return header + body
			}
			return nil
		}
	}

	// swiftlint:disable:next type_name
	enum Id: Codable, Sendable, Hashable {
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
					debugDescription: "ID must be either Int or String"
				)
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

	struct RequestMessage: Codable, Sendable {
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
					keyedBy: ParamCodingKeys.self
				)

				let method = try container.decode(
					MethodName.self, forKey: .method
				)

				switch method {
				case .initialize:
					self = try .initialize(
						container.decode(
							InitializeParams.self,
							forKey: .params
						)
					)
				case .diagnostic:
					self = try .diagnostic(
						container.decode(
							DocumentDiagnosticParams.self,
							forKey: .params
						)
					)
				case .shutdown:
					self = .shutdown
				}
			}

			public func encode(to encoder: any Encoder) throws {
				var container = encoder.container(keyedBy: ParamCodingKeys.self)
				try container.encode(name, forKey: .method)
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

			jsonrpc = try container.decode(String.self, forKey: .jsonrpc)
			id = try container.decode(Id.self, forKey: .id)
			method = try Method(from: decoder)
		}

		public func encode(to encoder: any Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(jsonrpc, forKey: .jsonrpc)
			try container.encode(id, forKey: .id)
			try method.encode(to: encoder)
		}
	}

	struct NotificationMessage: Codable, Sendable {
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
					keyedBy: ParamCodingKeys.self
				)

				let method = try container.decode(
					MethodName.self,
					forKey: .method
				)

				switch method {
				case .initialized:
					self = .initialized
				case .exit:
					self = .exit
				case .didOpenTextDocument:
					self = try .didOpenTextDocument(
						container.decode(
							TextDocumentParams.DidOpen.self,
							forKey: .params
						)
					)
				case .didChangeTextDocument:
					self = try .didChangeTextDocument(
						container.decode(
							TextDocumentParams.DidChange.self,
							forKey: .params
						)
					)
				case .didSaveTextDocument:
					self = try .didSaveTextDocument(
						container.decode(
							TextDocumentParams.DidSave.self,
							forKey: .params
						)
					)
				}
			}

			public func encode(to encoder: any Encoder) throws {
				var container = encoder.container(keyedBy: ParamCodingKeys.self)
				try container.encode(name, forKey: .method)
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

			jsonrpc = try container.decode(String.self, forKey: .jsonrpc)
			method = try Method(from: decoder)
		}

		public func encode(to encoder: any Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(jsonrpc, forKey: .jsonrpc)
			try method.encode(to: encoder)
		}
	}

	struct ResponseMessage: Codable, Sendable {
		let jsonrpc: String
		public let id: Id?
		public let result: Result<ResponseSuccess, ResponseError>?

		public init(
			id: Id? = nil,
			result: Result<ResponseSuccess, ResponseError>? = nil
		) {
			jsonrpc = "2.0"
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

			jsonrpc = try container.decode(String.self, forKey: .jsonrpc)
			id = try container.decodeIfPresent(Id.self, forKey: .id)

			if let success = try container.decodeIfPresent(
				ResponseSuccess.self,
				forKey: .result
			) {
				result = .success(success)
			} else if let failure = try container.decodeIfPresent(
				ResponseError.self,
				forKey: .error
			) {
				result = .failure(failure)
			} else {
				result = nil
			}
		}

		public func encode(to encoder: any Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)

			try container.encode(jsonrpc, forKey: .jsonrpc)
			try container.encode(id, forKey: .id)

			switch result {
			case let .failure(failure):
				try container.encode(failure, forKey: .error)
			case let .success(success):
				try container.encode(success, forKey: .result)
			case .none:
				break
			}
		}
	}

	struct UnknownMessage: Codable {
		let method: String
	}

	enum ResponseSuccess: Codable, Sendable {
		case initialize(InitializeResult)
		case diagnostic(DocumentDiagnosticReport)

		public init(from decoder: any Decoder) throws {
			let container = try decoder.singleValueContainer()

			if let result = try? container.decode(InitializeResult.self) {
				self = .initialize(result)
			} else if let result = try? container.decode(
				DocumentDiagnosticReport.self
			) {
				self = .diagnostic(result)
			} else {
				throw DecodingError.dataCorruptedError(
					in: container,
					debugDescription: "Unknown response success type"
				)
			}
		}

		public func encode(to encoder: any Encoder) throws {
			switch self {
			case let .initialize(result):
				try result.encode(to: encoder)
			case let .diagnostic(result):
				try result.encode(to: encoder)
			}
		}
	}

	enum ResponseError: Codable, Error {
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
					debugDescription: "Unknown code"
				)
			}
		}

		public func encode(to encoder: any Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(object.code, forKey: .code)
			try container.encode(object.message, forKey: .message)
		}
	}
}

public extension Lsp.RpcMessageItem {
	var debugDescription: String {
		let jsonEncoder = JSONEncoder()
		jsonEncoder.outputFormatting = .prettyPrinted

		guard let encoded = try? jsonEncoder.encode(self) else {
			return "\(Self.self) not encodable"
		}
		return String(data: encoded, encoding: .utf8)
			?? "\(Self.self) not stringable"
	}
}
