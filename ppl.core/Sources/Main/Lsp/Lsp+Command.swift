import ArgumentParser
import Foundation
import Lsp
import Utils

extension Peopl {
    struct LspComand: AsyncParsableCommand {
        enum LogLevel: String, ExpressibleByArgument {
            case verbose
            case debug
            case info
            case warning
            case error
            case critical

            var level: Utils.LogLevel {
                switch self {
                case .verbose: return .verbose
                case .debug: return .debug
                case .info: return .info
                case .warning: return .warning
                case .error: return .error
                case .critical: return .critical
                }
            }
        }

        #if RELEASE
            static let configuration = CommandConfiguration(
                commandName: "lsp",
                abstract: "Run the PeoPl language server protocol server",
                subcommands: [InplaceCommand.self],
                defaultSubcommand: InplaceCommand.self
            )
        #else
            static let configuration = CommandConfiguration(
                commandName: "lsp",
                abstract: "Run the PeoPl language server protocol server",
                subcommands: [
                    InplaceCommand.self,
                    SocketCommand.self,
                    ProxyCommand.self,
                ],
                defaultSubcommand: InplaceCommand.self
            )
        #endif

        struct InplaceCommand: AsyncParsableCommand {
            static let configuration = CommandConfiguration(
                commandName: "inplace",
                abstract:
                    "Run the PeoPl language server protocol server in place"
            )

            enum Logger: String, ExpressibleByArgument {
                case stderr
                case file
            }

            @Option(name: .long, help: "logging level")
            var logLevel: LogLevel = .error

            @Option(name: .long, help: "logger")
            var logger: Logger = .stderr

            @Option(name: .long, help: "log file path")
            var filePath: String?

            func run() async throws {
                switch self.logger {
                case .stderr:
                    let logger = Utils.StdErrLogger(
                        level: self.logLevel.level)
                    let server = Lsp.Server(
                        handler: PpLsp.Handler(
                            moduleParser: TreeSitterModulParser.self,
                            logger: logger),
                        transport: Lsp.standardTransport,
                        logger: logger)
                    try await server.run()
                case .file:
                    guard let filePath = self.filePath else {
                        throw ValidationError(
                            "File path is required when using file logger")
                    }
                    let logger = try Utils.FileLogger(
                        filePath: URL(filePath: filePath),
                        level: self.logLevel.level)
                    let server = Lsp.Server(
                        handler: PpLsp.Handler(
                            moduleParser: TreeSitterModulParser.self,
                            logger: logger),
                        transport: Lsp.standardTransport,
                        logger: logger)
                    try await server.run()
                }
            }
        }
        #if !RELEASE
            struct SocketCommand: AsyncParsableCommand {
                static let configuration = CommandConfiguration(
                    commandName: "socket",
                    abstract:
                        // swiftlint:disable:next line_length
                        "Run the PeoPl language server protocol server over a socket"
                )

                enum Logger: String, ExpressibleByArgument {
                    case stdout
                    case file
                }

                @Option(name: .long, help: "port")
                var port: UInt16 = 8765

                @Option(name: .long, help: "logging level")
                var logLevel: LogLevel = .info

                @Option(name: .long, help: "logger")
                var logger: Logger = .stdout

                @Option(name: .long, help: "log file path")
                var filePath: String?

                func run() async throws {
                    switch self.logger {
                    case .stdout:
                        let logger = Utils.ConsoleLogger(
                            level: self.logLevel.level)
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
                    case .file:
                        guard let filePath = self.filePath else {
                            throw ValidationError(
                                "File path is required when using file logger")
                        }
                        let logger = try Utils.FileLogger(
                            filePath: URL(filePath: filePath),
                            level: self.logLevel.level)
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
                    }
                }
            }

            struct ProxyCommand: AsyncParsableCommand {
                static let configuration = CommandConfiguration(
                    commandName: "proxy",
                    abstract:
                        "Run the PeoPl language server protocol server as a proxy"
                )

                enum Logger: String, ExpressibleByArgument {
                    case stderr
                    case file
                }

                @Option(name: .long, help: "port")
                var port: UInt16 = 8765

                @Option(name: .long, help: "host")
                var host: String = "localhost"

                @Option(name: .long, help: "logging level")
                var logLevel: LogLevel = .error

                @Option(name: .long, help: "logger")
                var logger: Logger = .stderr

                @Option(name: .long, help: "log file path")
                var filePath: String?

                func run() async throws {
                    switch self.logger {
                    case .stderr:
                        let logger = Utils.StdErrLogger(
                            level: self.logLevel.level)
                        let handler = try Lsp.ProxyHandler(
                            client: try .init(
                                port: self.port,
                                host: self.host,
                                logger: logger),
                            logger: logger)
                        let server = Lsp.Server(
                            handler: handler,
                            transport: Lsp.standardTransport,
                            logger: logger)
                        try await handler.run()
                        try await server.run()

                    case .file:
                        guard let filePath = self.filePath else {
                            throw ValidationError(
                                "File path is required when using file logger")
                        }
                        let logger = try Utils.FileLogger(
                            filePath: URL(filePath: filePath),
                            level: self.logLevel.level)
                        let handler = try Lsp.ProxyHandler(
                            client: try .init(
                                port: self.port,
                                host: self.host,
                                logger: logger),
                            logger: logger)
                        let server = Lsp.Server(
                            handler: handler,
                            transport: Lsp.standardTransport,
                            logger: logger)
                        try await handler.run()
                        try await server.run()
                    }
                }
            }
        #endif
    }
}
