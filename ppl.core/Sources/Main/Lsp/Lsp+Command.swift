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

        @Option(name: .long, help: "logging level")
        var logLevel: LogLevel = .info

        func run() async throws {

            switch self.mode {
            case .inplace:
                let logger = try Utils.FileLogger(
                    filePath: FileManager
                        .default
                        .homeDirectoryForCurrentUser
                        .appending(path: ".peopl/log/")
                        .appending(path: "lsp.log"),
                    level: self.logLevel.level)
                let server = Lsp.Server(
                    handler: PpLsp.Handler(
                        moduleParser: TreeSitterModulParser.self,
                        logger: logger),
                    transport: Lsp.standardTransport,
                    logger: logger)
                try await server.run()
            case .socket:
                let logger = Utils.ConsoleLogger(level: self.logLevel.level)
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
                    level: self.logLevel.level)
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
