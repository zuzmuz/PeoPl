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

        enum LoggerOption: String, ExpressibleByArgument {
            case stderr
            case stdout
            case file
        }

        enum ModeOption: String, ExpressibleByArgument {
            case inplace
            case proxy
        }

        enum TransportOption: String, ExpressibleByArgument {
            case std
            case socket
        }

        @Option(name: .shortAndLong, help: "server mode")
        var mode: ModeOption = .inplace

        @Option(name: .shortAndLong, help: "server transport layer")
        var transport: TransportOption = .std

        @Option(name: .shortAndLong, help: "server logger")
        var logger: LoggerOption = .stderr

        @Option(name: .long, help: "proxy target host")
        var proxyHost: String = "localhost"

        @Option(name: .long, help: "proxy target port")
        var proxyPort: UInt16 = 8765

        @Option(name: .long, help: "socket transport target host")
        var transportHost: String = "localhost"

        @Option(name: .long, help: "socket transport target port")
        var transportPort: UInt16 = 8765

        @Option(name: .long, help: "file path for file logger")
        var filePath: String?

        @Option(name: .long, help: "logging level")
        var logLevel: Utils.LogLevel = .info

        func run() async throws {

            let logger: WrappedLogger
            switch self.logger {
            case .stderr:
                logger = .init(
                    logger: Utils.StdErrLogger(level: self.logLevel))
            case .stdout:
                logger = .init(
                    logger: Utils.ConsoleLogger(level: self.logLevel))
            case .file:
                guard let filePath = self.filePath else {
                    throw ValidationError(
                        "file path is required for file logger")
                }
                logger = .init(
                    logger: try Utils.FileLogger(
                        filePath: URL(filePath: filePath),
                        level: self.logLevel))
            }

            let transport: WrappedTransport
            switch self.transport {
            case .std:
                transport = .init(transport: Lsp.standardTransport)
            case .socket:
                let tcpServer = try Socket.TcpServer(
                    port: self.transportPort, logger: logger)
                transport = .init(
                    transport: tcpServer)
                try await tcpServer.start()
            }

            let mode: WrapperHandler
            switch self.mode {
            case .inplace:
                mode = .init(
                    handler: PpLsp.Handler(
                        moduleParser: TreeSitterModulParser.self, logger: logger
                    ))
            case .proxy:
                let tcpClient = try Socket.TcpClient(
                    port: self.proxyPort, host: self.proxyHost, logger: logger)
                let proxy = try Lsp.ProxyHandler(
                    client: tcpClient, logger: logger)
                mode = .init(
                    handler: proxy)
                try await tcpClient.start()
            }

            let server = Lsp.Server(
                handler: mode,
                transport: transport,
                logger: logger)
            try await server.run()
        }
    }
}
