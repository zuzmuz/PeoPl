import Foundation
import Lsp
import Utils

enum LspCommand {
    case standard
    case proxy(port: UInt16)
    case socket(port: UInt16)

    init(args: [String]) throws(CommandLineError) {
        switch args.count {
        case 2:
            self = .standard
        case 4:
            switch (args[2], UInt16(args[3])) {
            case ("socket", let .some(port)):
                self = .socket(port: port)
            case ("proxy", let .some(port)):
                self = .proxy(port: port)
            case ("socket", .none), ("proxy", .none):
                throw CommandLineError.invalidArguments(
                    "port <\(args[3])> is not a valid UInt16")
            default:
                throw CommandLineError.invalidArguments(
                    "subcommand <\(args[2])> is not valid, choices [proxy, socket]"
                )
            }
        default:
            throw CommandLineError.invalidArguments(
                "wrong number of arguments for lsp command")
        }
    }

    func run() async throws {
        switch self {
        case .standard:
            try await PpLsp.runLsp()
        case let .socket(port):
            try await PpLsp.runLspSocket(port: port)
        case let .proxy(port):
            try await PpLsp.runLspProxy(port: port)
        }
    }
}

extension Syntax.NodeLocation {
    var lspRange: Lsp.Range {
        return .init(
            start: .init(
                line: self.pointRange.lowerBound.line,
                character: self.pointRange.lowerBound.column / 2),
            end: .init(
                line: self.pointRange.upperBound.line,
                character: self.pointRange.upperBound.column / 2))
    }
}

extension Syntax.Error {
    var diagnosticMessage: String {
        switch self {
        case let .errorParsing(element, _):
            element
        case let .notImplemented(element, _):
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
                end: .init(line: 0, character: 0))
        case .notImplemented(_, let location),
            .errorParsing(_, let location):
            return location.lspRange
        }
    }
}

extension Semantic.Error {
    var diagnosticMessage: String {
        switch errorChoice {
        case let .notImplemented(value):
            "\(value): this feature is not implemented yet"
        case let .cyclicType(stack):
            "This identifier defines a cyclical type, the cycle is defined \(stack.map { $0.identifier.display() }.joined(separator: "->"))"
        case let .typeRedeclaration(identifier, _):
            "This is an invalid type redeclaration of the identifier '\(identifier.display())'"
        case let .typeNotInScope(identifier):
            "The identifier \(identifier.display()) is not defined anywhere"
        case .homogeneousTypeProductInSum:
            "Homegenous array type is not allowed inside a choice type"
        case .duplicateFieldName:
            "The type field list has duplicated field names"
        case let .functionRedeclaration(signature, _):
            "This is an invalid function redeclaration of the signature '\(signature.display())'"
        case let .functionRedeclaringType(identifier, _):
            "A type exisist with this identifier: \(identifier)"
        case .taggedTypeSpecifierRequired:
            "This tag requires a type specifier in this context"
        case let .inputMismatch(expected, received):
            "The expression has mismathed input, expected: \(expected.display()), received: \(received.display())"
        case let .invalidOperation(leftType, op, rightType):
            "Invalid operation, can not apply \(op) on \(leftType.display()) and \(rightType.display())"
        case let .undefinedCall(signature):
            "Can not find \(signature.display()) in scope"
        case .duplicatedExpressionFieldName:
            "The expression field list has duplicated field names"
        case .consecutiveUnary:
            "Consecutive unary operations are not allowed"
        case let .functionBodyOutputTypeMismatch(expected, received):
            "The function body output type mismatch, expected: \(expected.display()), received: \(received.display())"
        default:
            "no message for this error yet"
        }
    }

    var lspRange: Lsp.Range {
        return location.lspRange
    }
}

enum PpLsp {
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
                self.logger.log(
                    level: .debug,
                    tag: "LspHandler",
                    message: "Scanning workspace folder: \(folder.uri)")
                guard let folderURL = URL(string: folder.uri) else {
                    self.logger.log(
                        level: .error,
                        tag: "LspHandler",
                        message: "Invalid workspace folder URI: \(folder.uri)")
                    return
                }
                guard
                    let urls = FileManager.default.enumerator(
                        at: folderURL,
                        includingPropertiesForKeys: [
                            .isRegularFileKey, .isDirectoryKey,
                        ])
                else {
                    self.logger.log(
                        level: .error,
                        tag: "LspHandler",
                        message:
                            "Failed to enumerate workspace folder: \(folder.uri)"
                    )
                    return
                }

                self.modulesContent =
                    urls.reduce(into: [:]) { acc, file in
                        guard let file = file as? URL,
                            file.isFileURL,
                            file.pathExtension == "ppl",
                            let source = try? Syntax.Source(url: file)
                        else { return }
                        acc[file.absoluteString] = source
                    }

                self.logger.log(
                    level: .debug,
                    tag: "LspHandler",
                    message: "modules content: \(self.modulesContent)")
            }
        }

        private func generateDiagnostics(
            for uri: String,
        ) -> [Lsp.Diagnostic] {
            // let project = Syntax.Project.init(
            var diagnostics: [Lsp.Diagnostic] = []

            let modules = self.modulesContent.reduce(
                into: [:]
            ) { acc, element in
                acc[element.key] = moduleParser.parseModule(
                    source: element.value)
            }

            for (moduleUri, module) in modules {
                if moduleUri == uri {
                    diagnostics.append(
                        contentsOf: module.syntaxErrors.map { error in
                            .init(
                                range: error.lspRange,
                                severity: .error,
                                message: error.diagnosticMessage)
                        })

                    guard module.syntaxErrors.count == 0 else {
                        break
                    }

                    let semanticContext = module.semanticCheck()

                    switch semanticContext {
                    case let .failure(errorList):
                        diagnostics.append(
                            contentsOf: errorList.errors.map { error in
                                .init(
                                    range: error.lspRange,
                                    severity: .error,
                                    message: error.diagnosticMessage)
                            })
                    case .success:
                        break
                    }
                }

            }
            return diagnostics
        }

        func handle(request: Lsp.RequestMessage) -> Lsp.ResponseMessage {
            switch request.method {
            case let .initialize(params):
                self.logger.log(
                    level: .info,
                    tag: "LspHandler",
                    message: "Initialize request with params: \(params)")

                if let workspaceFolders = params.workspaceFolders {
                    self.scanWorkspaceFolders(folders: workspaceFolders)
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
                                        workspaceDiagnostics: true)),
                                serverInfo: .init(
                                    name: "peopls",
                                    version: "0.0.1.0")))))
            case let .diagnostic(params):

                self.logger.log(
                    level: .info,
                    tag: "LspHanler",
                    message: "Diagnostic request with params: \(params)")

                let resultId = params.previousResultId

                return .init(
                    id: request.id,
                    result: .success(
                        .diagnostic(
                            .full(
                                resultId: resultId,
                                items: self.generateDiagnostics(
                                    for: params.textDocument.uri),
                                relatedDocuments: nil))))
            case .shutdown:
                return .init(id: request.id)
            }
        }

        func handle(notification: Lsp.NotificationMessage) {
            switch notification.method {
            case .initialized:
                break
            case let .didOpenTextDocument(params):
                self.modulesContent[params.textDocument.uri] =
                    .init(
                        content: params.textDocument.text,
                        name: params.textDocument.uri)
                self.logger.log(
                    level: .debug,
                    tag: "LspHandler",
                    message: "modules content: \(self.modulesContent)")
            case let .didChangeTextDocument(params):
                params.contentChanges.forEach { contentChange in
                    if case let .full(text) = contentChange {
                        self.modulesContent[params.textDocument.uri] =
                            .init(
                                content: text,
                                name: params.textDocument.uri)
                    }
                }
                self.logger.log(
                    level: .debug,
                    tag: "LspHandler",
                    message: "modules content: \(self.modulesContent)")
            case let .didSaveTextDocument(params):
                break
            case .exit:
                break
            }
        }
    }

}
