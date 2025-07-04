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

    init(logger: (any Lsp.Logger)? = nil) {
        self.logger = logger
    }

    func handle(request: Lsp.RequestMessage) -> Lsp.ResponseMessage {
        switch request.method {
        case let .initialize(params):
            self.logger?.log(
                level: .info,
                message: "Initialize request with params: \(params)")
            return .init(
                id: request.id,
                result: .success(
                    .initialize(
                        .init(
                            capabilities: .init(
                                positionEncoding: .utf16,
                                textDocumentSync: .full),
                            serverInfo: .init(
                                name: "peopls",
                                version: "0.0.1.0")))))
        case .shutdown:
            return .init(id: request.id)
        }
    }

    func handle(notification: Lsp.NotificationMessage) {
        switch notification.method {
        default:
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
