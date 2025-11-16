// #if LSP

import Foundation
import Lsp
import Utils

extension Syntax.NodeLocation {
	var lspRange: Lsp.Range {
		return .init(
			start: .init(
				line: pointRange.lowerBound.line,
				character: pointRange.lowerBound.column / 2
			),
			end: .init(
				line: pointRange.upperBound.line,
				character: pointRange.upperBound.column / 2
			)
		)
	}
}

extension Syntax.Error {
	var diagnosticMessage: String {
		switch self {
		case .errorParsing(let element, _):
			element
		case .notImplemented(let element, _):
			"\(element) not implemented"
		case .languageNotSupported:
			"well something is terribly wrong here"
		case .rangeNotInContent:
			"oops range went out of bounds here, don't know how that happened"
		case .sourceUnreadable:
			"well something's wrong with you"
		}
	}

	var lspRange: Lsp.Range {
		switch self {
		case .rangeNotInContent, .languageNotSupported, .sourceUnreadable:
			return .init(
				start: .init(line: 0, character: 0),
				end: .init(line: 0, character: 0)
			)
		case .notImplemented(_, let location),
			.errorParsing(_, let location):
			return location.lspRange
		}
	}
}

#if ANALYZER
extension Semantic.Error {
	var diagnosticMessage: String {
		switch errorChoice {
		// TODO: I need to figure out the debug display vs the lsp display
		// case let .notImplemented(value):
		// 	"\(value): this feature is not implemented yet"
		// case let .cyclicType(stack):
		// 	"This identifier defines a cyclical type, the cycle is defined \(stack.map { $0.identifier.display() }.joined(separator: "->"))"
		// case let .typeRedeclaration(identifier, _):
		// 	"This is an invalid type redeclaration of the identifier '\(identifier.display())'"
		// case let .typeNotInScope(identifier):
		// 	"The identifier \(identifier.display()) is not defined anywhere"
		// case .homogeneousTypeProductInSum:
		// 	"Homegenous array type is not allowed inside a choice type"
		// case .duplicateFieldName:
		// 	"The type field list has duplicated field names"
		// case let .functionRedeclaration(signature, _):
		// 	"This is an invalid function redeclaration of the signature '\(signature.display())'"
		// case let .functionRedeclaringType(identifier, _):
		// 	"A type exisist with this identifier: \(identifier)"
		// case .taggedTypeSpecifierRequired:
		// 	"This tag requires a type specifier in this context"
		// case let .inputMismatch(expected, received):
		// 	"The expression has mismathed input, expected: \(expected.display()), received: \(received.display())"
		// case let .invalidOperation(leftType, op, rightType):
		// 	"Invalid operation, can not apply \(op) on \(leftType.display()) and \(rightType.display())"
		// case let .undefinedCall(signature):
		// 	"Can not find \(signature.display()) in scope"
		// case .duplicatedExpressionFieldName:
		// 	"The expression field list has duplicated field names"
		// case .consecutiveUnary:
		// 	"Consecutive unary operations are not allowed"
		// case let .functionBodyOutputTypeMismatch(expected, received):
		// 	"The function body output type mismatch, expected: \(expected.display()), received: \(received.display())"
		default:
			"no message for this error yet"
		}
	}

	var lspRange: Lsp.Range {
		return location.lspRange
	}
}
#endif

enum PeopLsp {
	actor Handler<L: Utils.Logger, P: Syntax.ModuleParser>: Lsp.Handler {
		private let logger: L
		private let moduleParser: P.Type
		private var modulesContent: [String: Syntax.Source] = [:]

		init(moduleParser: P.Type, logger: L) {
			self.moduleParser = moduleParser
			self.logger = logger
		}

		private func scanWorkspaceFolders(folders: [Lsp.WorkspaceFolder]) {
			for folder in folders {
				logger.debug(
					tag: "LspHandler",
					message: "Scanning workspace folder: \(folder.uri)"
				)
				guard let folderURL = URL(string: folder.uri) else {
					logger.error(
						tag: "LspHandler",
						message: "Invalid workspace folder URI: \(folder.uri)"
					)
					return
				}
				guard
					let urls = FileManager.default.enumerator(
						at: folderURL,
						includingPropertiesForKeys: [
							.isRegularFileKey, .isDirectoryKey,
						]
					)
				else {
					logger.error(
						tag: "LspHandler",
						message:
							"Failed to enumerate workspace folder: \(folder.uri)"
					)
					return
				}

				modulesContent =
					urls.reduce(into: [:]) { acc, file in
						guard let file = file as? URL,
							file.isFileURL,
							file.pathExtension == "ppl",
							let source = try? Syntax.Source(url: file)
						else { return }
						acc[file.absoluteString] = source
					}

				logger.debug(
					tag: "LspHandler",
					message: "modules content: \(modulesContent)"
				)
			}
		}

		private func generateDiagnostics(
			for uri: String,
		) -> [Lsp.Diagnostic] {
			// let project = Syntax.Project.init(
			var diagnostics: [Lsp.Diagnostic] = []

			let modules = modulesContent.reduce(
				into: [:]
			) { acc, element in
				acc[element.key] = moduleParser.parseModule(
					source: element.value
				)
			}

			for (moduleUri, module) in modules {
				if moduleUri == uri {
					diagnostics.append(
						contentsOf: module.syntaxErrors.map { error in
							.init(
								range: error.lspRange,
								severity: .error,
								message: error.diagnosticMessage
							)
						}
					)

					guard module.syntaxErrors.count == 0 else {
						break
					}

					#if ANALYZER
					let semanticContext = module.semanticCheck()

					switch semanticContext {
					case .failure(let errorList):
						diagnostics.append(
							contentsOf: errorList.errors.map { error in
								.init(
									range: error.lspRange,
									severity: .error,
									message: error.diagnosticMessage
								)
							}
						)
					case .success:
						break
					}
					#endif
				}
			}
			return diagnostics
		}

		func handle(request: Lsp.RequestMessage) -> Lsp.ResponseMessage {
			switch request.method {
			case .initialize(let params):
				logger.info(
					tag: "LspHandler",
					message: "Initialize request with params: \(params)"
				)

				if let workspaceFolders = params.workspaceFolders {
					scanWorkspaceFolders(folders: workspaceFolders)
				}

				return .init(
					id: request.id,
					result: .success(
						.initialize(
							.init(
								capabilities: .init(
									positionEncoding: .utf16,
									textDocumentSync: .full,
									diagnosticProvider: .init(
										interFileDependencies: true,
										workspaceDiagnostics: true
									)
								),
								serverInfo: .init(
									name: "peopls",
									version: "0.0.1.0"
								)
							)
						)
					)
				)
			case .diagnostic(let params):
				logger.info(
					tag: "LspHanler",
					message: "Diagnostic request with params: \(params)"
				)

				let resultId = params.previousResultId

				return .init(
					id: request.id,
					result: .success(
						.diagnostic(
							.full(
								resultId: resultId,
								items: generateDiagnostics(
									for: params.textDocument.uri
								),
								relatedDocuments: nil
							)
						)
					)
				)
			case .shutdown:
				return .init(id: request.id)
			}
		}

		func handle(notification: Lsp.NotificationMessage) {
			switch notification.method {
			case .initialized:
				break
			case .didOpenTextDocument(let params):
				modulesContent[params.textDocument.uri] =
					.init(
						content: params.textDocument.text,
						name: params.textDocument.uri
					)
				logger.debug(
					tag: "LspHandler",
					message: "modules content: \(modulesContent)"
				)
			case .didChangeTextDocument(let params):
				for contentChange in params.contentChanges {
					if case .full(let text) = contentChange {
						modulesContent[params.textDocument.uri] =
							.init(
								content: text,
								name: params.textDocument.uri
							)
					}
				}
				logger.debug(
					tag: "LspHandler",
					message: "modules content: \(modulesContent)"
				)
			case .didSaveTextDocument(let params):
				break
			case .exit:
				break
			}
		}
	}
}
// #endif
