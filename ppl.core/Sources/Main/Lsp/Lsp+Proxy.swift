import Foundation
import Utils
import Lsp

extension PpLsp {
    static func runLspProxy(port: UInt16) async throws {
        let logger = try Utils.FileLogger(
            path: FileManager
                .default
                .homeDirectoryForCurrentUser
                .appending(path: ".peopl/log/"),
            fileName: "proxy.log",
            level: .verbose)

        let server = Lsp.Server(
            handler: try Lsp.ProxyHandler(
                client: try .init(
                    port: port,
                    host: "localhost",
                    logger: logger),
                logger: logger),
            transport: Lsp.standardTransport,
            logger: logger)

        try await server.run()
    }
}
