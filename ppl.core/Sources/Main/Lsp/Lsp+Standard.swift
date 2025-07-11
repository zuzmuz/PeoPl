import Foundation
import Lsp
import Utils

extension PpLsp {

    /// Runs local Lsp server with standard transport and logging.
    static func runLsp() async throws {
        let logger = try Utils.FileLogger(
            path: FileManager
                .default
                .homeDirectoryForCurrentUser
                .appending(path: ".peopl/log/"),
            fileName: "lsp.log",
            level: .debug)

        let server = Lsp.Server(
            handler: Handler(logger: logger),
            transport: Lsp.standardTransport,
            logger: logger)

        try await server.run()
    }
}
