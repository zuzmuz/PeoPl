import Foundation

actor Handler: Lsp.Handler {
    var logger: (any Lsp.Logger)?
    var state: [String: String]
    var project: Syntax.Project?

    init(logger: (any Lsp.Logger)? = nil) {
        self.logger = logger
        self.state = [:]
    }

    private func scanWorkspaceFolders(folders: [Lsp.WorkspaceFolder]) {
        for folder in folders {
            self.logger?.log(
                level: .debug,
                message: "Scanning workspace folder: \(folder.uri)")
            guard let folderURL = URL(string: folder.uri) else {
                self.logger?.log(
                    level: .error,
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
                self.logger?.log(
                    level: .error,
                    message:
                        "Failed to enumerate workspace folder: \(folder.uri)")
                return
            }

            let modules: [String: Result<Syntax.Module, Syntax.Error>] =
                urls.reduce(into: [:]) { acc, file in
                    guard let file = file as? URL,
                        file.isFileURL,
                        file.pathExtension == "ppl"
                    else { return }
                    do throws(Syntax.Error) {
                        acc[file.absoluteString] = .success(
                            try Syntax.Module(url: file))
                    } catch {
                        acc[file.absoluteString] = .failure(error)
                    }
                }

            self.project = Syntax.Project(
                modules: modules.compactMapValues { result in
                    switch result {
                    case let .success(module):
                        return module
                    case .failure:
                        return nil
                    }
                }
            )

            let result = self.project?.semanticCheck()

        }
    }

    func handle(request: Lsp.RequestMessage) -> Lsp.ResponseMessage {
        switch request.method {
        case let .initialize(params):
            self.logger?.log(
                level: .info,
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
            return .init(id: request.id)
        case .shutdown:
            return .init(id: request.id)
        }
    }

    func handle(notification: Lsp.NotificationMessage) {
        switch notification.method {
        case .initialized:
            break
        case let .didOpenTextDocument(params):
            break
        case .didChangeTextDocument(_):
            break
        case .didOpenTextDocument(_):
            break
        case .didSaveTextDocument(_):
            break
        case .exit:
            break
        }
    }
}

func runLSP() async throws {
    let logger = try Lsp.FileLogger(
        path: FileManager
            .default
            .homeDirectoryForCurrentUser
            .appending(path: ".peopl/log/"),
        fileName: "lsp.log",
        level: .verbose)
    let server = Lsp.Server(
        handler: Handler(logger: logger),
        transport: Lsp.StandardTransport(),
        logger: logger)

    await server.run()
}
