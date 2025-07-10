import Foundation
import Lsp
import Utils

extension PpLsp {

    static func runLspSocket(port: UInt16) async throws {
        let logger = Utils.ConsoleLogger(level: .verbose)
        let server = try Socket.TcpServer(
            port: port,
            logger: logger)

        while true {

            logger.log(
                level: .notice,
                tag: "LspTcpServer",
                message: "Waiting for connection...")

            try await server.start()

            var data = Data()

            do {
                while true {

                    data += try await server.read()

                    data = Data()
                }
            } catch {
                logger.log(
                    level: .warning,
                    tag: "LspTcpServer",
                    message: "connection closed")
            }
        }
    }
}
