import ArgumentParser
import Foundation
import Lsp
import Utils

extension Utils.LogLevel: ExpressibleByArgument {}
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

        private static func getFileLogger(
            filePath: String?,
            level: Utils.LogLevel
        ) throws -> some Utils.Logger {
            guard let filePath else {
                throw ValidationError(
                    // swiftlint:disable:next line_length
                    "File path for file logger is required when logger is set to file."
                )
            }
            return try Utils.FileLogger(
                filePath: URL(filePath: filePath),
                level: level)
        }

        static func inplaceHandler<L: Utils.Logger>(
            logger: L
        ) -> PpLsp.Handler<L, TreeSitterModulParser> {
            PpLsp.Handler(
                moduleParser: TreeSitterModulParser.self,
                logger: logger)
        }

        func run() async throws {

            switch (self.logger, self.transport, self.mode) {
            case (.stdout, .std, _):
                throw ValidationError(
                    // swiftlint:disable:next line_length
                    "logger stdout is not supported with std transport, logging needs to be on a separate transport"
                )
            case (.stderr, .std, .inplace):
                let logger = Utils.StdErrLogger(level: self.logLevel)
                let server = Lsp.Server(
                    handler: Self.inplaceHandler(logger: logger),
                    transport: Lsp.standardTransport,
                    logger: logger)
                try await server.run()
            case (.file, .std, .inplace):
                let logger = try Self.getFileLogger(
                    filePath: self.filePath,
                    level: self.logLevel)
                let server = Lsp.Server(
                    handler: Self.inplaceHandler(logger: logger),
                    transport: Lsp.standardTransport,
                    logger: logger)
                try await server.run()
            case (.stdout, .socket, .inplace):
                let logger = Utils.ConsoleLogger(level: self.logLevel)
                let tcpServer = try Socket.TcpServer(
                    port: self.transportPort,
                    logger: logger)
                let server = Lsp.Server(
                    handler: Self.inplaceHandler(logger: logger),
                    transport: tcpServer,
                    logger: logger)
                try await tcpServer.start()
                try await server.run()
            case (_, .socket, _):
                throw ValidationError(
                    "socket transport requires inplace server and stdout"
                )
            case (.stderr, .std, .proxy):
                let logger = Utils.StdErrLogger(level: self.logLevel)
                let proxyHandler = try Lsp.ProxyHandler(
                    client: try .init(
                        port: self.proxyPort,
                        host: self.proxyHost,
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
            case (.file, .std, .proxy):
                let logger = try Self.getFileLogger(
                    filePath: self.filePath,
                    level: self.logLevel)
                let proxyHandler = try Lsp.ProxyHandler(
                    client: try .init(
                        port: self.proxyPort,
                        host: self.proxyHost,
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
    }
}
