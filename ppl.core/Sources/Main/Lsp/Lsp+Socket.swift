import Foundation
import Lsp
import Utils

extension PpLsp {

    static func runLspSocket(port: UInt16) async throws {
        let logger = Utils.ConsoleLogger(level: .verbose)

        let server = Lsp.Server(
            handler: Handler(logger: logger),
            transport: try Socket.TcpServer(port: port, logger: logger),
            logger: logger)

        try await server.run()
    }
}
