import Foundation
import Lsp
import Utils

enum LspCommand: String {
    case proxy
    case socket
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

extension Semantic.Error {
    var diagnosticMessage: String {
        "what"
    }

    var lspRange: Lsp.Range {
        return .init(
            start: .init(line: 0, character: 0),
            end: .init(line: 0, character: 0))
    }
}

enum PpLsp {
    actor Handler<L: Utils.Logger, P: Syntax.ModuleParser>: Lsp.Handler {
        private let logger: L
        private let moduleParser: P
        private var modulesContent: [String: String] = [:]

        init(moduleParser: P, logger: L) {
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
                            file.pathExtension == "ppl"
                        else { return }
                        guard let data = try? Data.init(contentsOf: file),
                            let source = String(data: data, encoding: .utf8)
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
                    source: .init(content: element.value, name: element.key))
            }

            for (moduleUri, module) in modules {
                if moduleUri == uri {
                    diagnostics.append(
                        contentsOf: module.syntaxErrors.map { error in
                            .init(
                                range: error.lspRange,
                                severity: .error,
                                message: error.localizedDescription)
                        })
                }
            }
            //
            // let project = Syntax.Project.init(
            //     modules: modulesResult.compactMapValues { result in
            //         switch result {
            //         case let .success(module):
            //             return module
            //         case .failure:
            //             return nil
            //         }
            //     })

            // let context = project.semanticCheck()

            // switch context {
            // case let .failure(errorList):
            //     for error in errorList.errors {
            //         diagnostics.append(
            //             .init(
            //                 range: error.lspRange,
            //                 severity: .error,
            //                 message: error.localizedDescription))
            //     }
            // case .success:
            //     break
            // }

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
                    tag: "LspHandler",
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
                    params.textDocument.text
                self.logger.log(
                    level: .debug,
                    tag: "LspHandler",
                    message: "modules content: \(self.modulesContent)")
            case let .didChangeTextDocument(params):
                params.contentChanges.forEach { contentChange in
                    if case let .full(text) = contentChange {
                        self.modulesContent[params.textDocument.uri] = text
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
