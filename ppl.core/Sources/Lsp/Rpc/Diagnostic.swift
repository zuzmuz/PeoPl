extension Lsp {
	public struct DocumentDiagnosticParams: RpcMessageItem, Sendable {
		public let textDocument: TextDocumentIdentifier
		public let identifier: String?
		public let previousResultId: String?
	}

	public enum DocumentDiagnosticReport: Codable, Sendable {
		case full(
			resultId: String?,
			items: [Diagnostic],
			relatedDocuments: [String: DocumentDiagnosticReport]?
		)
		case unchanged(
			resultId: String,
			relatedDocuments: [String: DocumentDiagnosticReport]?
		)

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
					String.self, forKey: .resultId
				)
				let items = try container.decode(
					[Diagnostic].self, forKey: .items
				)
				let relatedDocuments = try container.decodeIfPresent(
					[String: DocumentDiagnosticReport].self,
					forKey: .relatedDocuments
				)
				self = .full(
					resultId: resultId,
					items: items,
					relatedDocuments: relatedDocuments
				)
			case .unchanged:
				let resultId = try container.decode(
					String.self,
					forKey: .resultId
				)
				let relatedDocuments = try container.decodeIfPresent(
					[String: DocumentDiagnosticReport].self,
					forKey: .relatedDocuments
				)
				self = .unchanged(
					resultId: resultId,
					relatedDocuments: relatedDocuments
				)
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
					relatedDocuments, forKey: .relatedDocuments
				)
			case let .unchanged(resultId, relatedDocuments):
				try container.encode(Kind.unchanged, forKey: .kind)
				try container.encode(resultId, forKey: .resultId)
				try container.encodeIfPresent(
					relatedDocuments,
					forKey: .relatedDocuments
				)
			}
		}
	}

	public struct Diagnostic: Codable, Sendable {
		public let range: Range
		public let severity: DiagnosticSeverity?
		public let code: DiagnosticCode?
		public let codeDescription: DiagnosticCodeDescription?
		public let source: String?
		public let message: String
		public let tags: [DiagnosticTag]?
		public let relatedInformation: [DiagnosticRelatedInformation]?

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
		public let location: Location
		public let message: String
	}

	public struct Location: Codable, Sendable {
		public let uri: String
		public let range: Range
	}
}
