import Foundation
import Lsp
import Utils

extension PpLsp {

    static func runLspSocket(port: UInt16) async throws {
        let logger = Utils.ConsoleLogger(level: .verbose)
        let tcpServer = try Socket.TcpServer(port: port, logger: logger)

        let server = Lsp.Server(
            handler: Handler(
                moduleParser: TreeSitterModulParser.self,
                logger: logger),
            transport: tcpServer,
            logger: logger)

        try await tcpServer.start()
        try await server.run()
    }
}
