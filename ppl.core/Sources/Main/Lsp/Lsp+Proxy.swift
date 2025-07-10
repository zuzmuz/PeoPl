import Foundation
import Lsp
import Utils

extension PpLsp {
    static func runLspProxy(port: UInt16) async throws {
        let logger = try Utils.FileLogger(
            path: FileManager
                .default
                .homeDirectoryForCurrentUser
                .appending(path: ".peopl/log/"),
            fileName: "proxy.log",
            level: .verbose)

        let client = try Socket.TcpClient(
            port: port,
            host: "localhost",
            logger: logger)

        try await client.start()

        while true {
            let data = FileHandle.standardInput.availableData
            logger.log(
                level: .debug,
                tag: "LspProxy",
                message: "Message received from stdin")

            logger.log(
                level: .debug,
                tag: "LspProxy",
                message: data)

            try await client.write(data)
        }
    }
}
