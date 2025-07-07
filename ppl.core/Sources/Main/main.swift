import Foundation

func compileExample() {
    do {
        let module = try Syntax.Module(
            source: """
                factorial: [a: Int] -> Int {
                    |1| 1
                }
                main: [] -> Int {
                    facotrial(a: 5)
                }
                """,
            path: "main")

        let result = module.semanticCheck()

        switch result {
        case let .success(context):
            print(context.display())

            var llvm = LLVM.Builder(name: "name")

            try context.llvmBuildStatement(llvm: &llvm)

            print("llvm")
            print(llvm.generate())

        case let .failure(error):
            print("Semantic check failed with errors: \(error.errors)")
        }
    } catch {
        print("we catching \(error)")
    }
}

class Handler: Lsp.Handler {
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

            let modules: [String: Syntax.Module] =
                urls.reduce(into: [:]) { acc, file in
                    guard let file = file as? URL,
                        file.isFileURL,
                        file.pathExtension == "ppl"
                    else { return }
                    if let module = try? Syntax.Module(url: file) {
                        acc[file.absoluteString] = module
                    }
                }
            self.project = Syntax.Project(modules: modules)
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

if CommandLine.arguments.count == 2 {
    let argument = CommandLine.arguments[1]
    switch argument {
    case "lsp":
        try await runLSP()
    default:
        compileExample()
    }
} else {
    compileExample()
}
