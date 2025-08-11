import ArgumentParser
import Foundation
import Lsp
import Utils

extension Utils.LogLevel: ExpressibleByArgument {}

// NOTE: these wrappers are stupid and are only useful for development process
private actor WrapperHandler: Lsp.Handler {
    let handler: any Lsp.Handler

    init(handler: any Lsp.Handler) {
        self.handler = handler
    }

    func handle(request: Lsp.RequestMessage) async -> Lsp.ResponseMessage {
        return await self.handler.handle(request: request)
    }

    func handle(notification: Lsp.NotificationMessage) async {
        await self.handler.handle(notification: notification)
    }

}

private actor WrappedTransport: Lsp.Transport {

    let transport: any Lsp.Transport

    init(transport: any Lsp.Transport) {
        self.transport = transport
    }

    func read() async throws -> Data {
        return try await self.transport.read()
    }

    func write(_ data: Data) async throws {
        try await self.transport.write(data)
    }
}

private final class WrappedLogger: Utils.Logger {
    let logger: any Utils.Logger

    init(logger: any Utils.Logger) {
        self.logger = logger
    }

    func log(level: Utils.LogLevel, tag: String, message: String) {
        self.logger.log(level: level, tag: tag, message: message)
    }

    func log(level: Utils.LogLevel, tag: String, message: Data) {
        self.logger.log(level: level, tag: tag, message: message)
    }
}

extension Peopl {
    struct LspComand: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "lsp",
            abstract: "Run the PeoPl language server protocol server",
        )

        enum ModeOption: String, ExpressibleByArgument {
            case inplace
            case proxy
            case socket
        }

        @Argument(help: "server mode")
        var mode: ModeOption = .inplace

        @Argument(help: "port")
        var port: UInt16 = 8765

        // @Option(name: .long, help: "file path for file logger")
        // var filePath: String?

        @Option(name: .long, help: "logging level")
        var logLevel: Utils.LogLevel = .info

        func run() async throws {

            switch self.mode {
            case .inplace:
                let logger = try Utils.FileLogger(
                    filePath: FileManager
                        .default
                        .homeDirectoryForCurrentUser
                        .appending(path: ".peopl/log/")
                        .appending(path: "lsp.log"),
                    level: self.logLevel)
                let server = Lsp.Server(
                    handler: PpLsp.Handler(
                        moduleParser: TreeSitterModulParser.self,
                        logger: logger),
                    transport: Lsp.standardTransport,
                    logger: logger)
                try await server.run()
            case .socket:
                let logger = Utils.ConsoleLogger(level: self.logLevel)
                let tcpServer = try Socket.TcpServer(
                    port: self.port, logger: logger)
                let server = Lsp.Server(
                    handler: PpLsp.Handler(
                        moduleParser: TreeSitterModulParser.self,
                        logger: logger),
                    transport: tcpServer,
                    logger: logger)
                try await tcpServer.start()
                try await server.run()
            case .proxy:
                let logger = try Utils.FileLogger(
                    filePath: FileManager
                        .default
                        .homeDirectoryForCurrentUser
                        .appending(path: ".peopl/log/")
                        .appending(path: "lsp.log"),
                    level: self.logLevel)
                let tcpClient = try Socket.TcpClient(
                    port: self.port, host: "localhost", logger: logger)
                let server = Lsp.Server(
                    handler: try Lsp.ProxyHandler(
                        client: tcpClient, logger: logger),
                    transport: Lsp.standardTransport,
                    logger: logger)
                try await tcpClient.start()
                try await server.run()
            }
        }
    }
}
