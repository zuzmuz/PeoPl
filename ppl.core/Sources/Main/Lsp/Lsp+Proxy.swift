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
            level: .warning)

        let proxyHandler = try Lsp.ProxyHandler(
            client: try .init(
                port: port,
                host: "localhost",
                logger: logger),
            logger: logger)

        let server = Lsp.Server(
            handler: proxyHandler,
            transport: Lsp.standardTransport,
            logger: logger)

        // run the proxy handler before running the server
        // to start the tcp client
        try await proxyHandler.run()
        try await server.run()
    }
}
