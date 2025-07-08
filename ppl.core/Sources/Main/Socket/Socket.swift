import Foundation
import Network

enum Socket {

    static let serverTag = "TcpServer"
    static let clientTag = "TcpClient"

    enum Error: LocalizedError {
        case invalidPort(UInt16)
        case listenerNotSet
        case connectionNotSet
        case readError(String)
        case connectionAlreadySet
        case connectionCancelled
        case connectionFailed
        case other(String)

        var errorDescription: String? {
            switch self {
            case .invalidPort(let port):
                return "invalid port: \(port)"
            case .listenerNotSet:
                return "listener not set"
            case .connectionNotSet:
                return "connection not set"
            case .readError(let message):
                return "read error: \(message)"
            case .connectionAlreadySet:
                return "connection already set"
            case .connectionCancelled:
                return "connection reset"
            case .connectionFailed:
                return "connection failed"
            case .other(let message):
                return "other error: \(message)"
            }
        }
    }

    actor TcpServer<L: Utils.Logger>: Lsp.Transport {
        private let port: NWEndpoint.Port
        private var listener: NWListener?
        private var connection: NWConnection?
        private let queue: DispatchQueue
        private let logger: L
        private var connected: Bool = false

        public init(port: UInt16, logger: L) throws(Socket.Error) {
            self.logger = logger

            guard let port = NWEndpoint.Port(rawValue: port) else {
                throw .invalidPort(port)
            }
            self.port = port

            self.queue = DispatchQueue(label: "TCPServerQueue", qos: .utility)
        }

        private func cancelConnection() {
            if let connection = self.connection {
                connection.cancel()
                self.connection = nil
                self.logger.log(
                    level: .info,
                    tag: Socket.serverTag,
                    message: "cancelling connection")
            }
        }

        private func setConnection(
            _ connection: NWConnection,
            completion: @Sendable @escaping (Result<(), Socket.Error>) -> Void
        ) {
            if self.connection != nil {
                logger.log(
                    level: .warning,
                    tag: Socket.serverTag,
                    message: "connection already existing")
                return
            }

            self.connection = connection
            self.connection?.stateUpdateHandler = { [weak self] state in
                switch state {
                case .ready:
                    self?.logger.log(
                        level: .info,
                        tag: Socket.serverTag,
                        message: "connection ready")
                    completion(.success(()))
                case let .failed(error):
                    self?.logger.log(
                        level: .error,
                        tag: Socket.serverTag,
                        message: "connection failed with error: \(error)")
                    completion(.failure(.connectionFailed))
                case let .waiting(error):
                    self?.logger.log(
                        level: .error,
                        tag: Socket.serverTag,
                        message: "connection waiting with error: \(error)")
                case .cancelled:
                    self?.logger.log(
                        level: .warning,
                        tag: Socket.serverTag,
                        message: "connection cancelled")
                    completion(.failure(.connectionCancelled))
                case .setup:
                    self?.logger.log(
                        level: .info,
                        tag: Socket.serverTag,
                        message: "connection is setting up")
                case .preparing:
                    self?.logger.log(
                        level: .info,
                        tag: Socket.serverTag,
                        message: "connection preparing")
                default:
                    self?.logger.log(
                        level: .warning,
                        tag: Socket.serverTag,
                        message: "connection unknown state \(state)")
                }
            }
            self.connection?.start(queue: self.queue)
        }

        private func setupServer(
            completion: @Sendable @escaping (Result<(), Error>) -> Void
        ) {

            if self.listener != nil {
                completion(.success(()))
                return
            }

            do {
                self.listener = try NWListener(
                    using: .tcp,
                    on: port)
            } catch {
                completion(.failure(.listenerNotSet))
                return
            }

            self.listener?.newConnectionHandler =
                { [weak self] connection in
                    Task {
                        await self?.setConnection(
                            connection,
                            completion: completion)
                    }
                }

            self.listener?.stateUpdateHandler = { [weak self] state in
                guard let self = self else {
                    return
                }
                switch state {
                case .ready:
                    self.logger.log(
                        level: .info,
                        tag: Socket.serverTag,
                        message: "server is ready on port \(self.port)"
                    )
                case let .failed(error):
                    self.logger.log(
                        level: .error,
                        tag: Socket.serverTag,
                        message: "server failed with error: \(error)")
                    completion(.failure(.listenerNotSet))
                case let .waiting(error):
                    self.logger.log(
                        level: .error,
                        tag: Socket.serverTag,
                        message: "server waiting with error: \(error)")
                case .cancelled:
                    self.logger.log(
                        level: .warning,
                        tag: Socket.serverTag,
                        message: "server cancelled")
                    completion(.failure(.listenerNotSet))
                case .setup:
                    self.logger.log(
                        level: .info,
                        tag: Socket.serverTag,
                        message: "server is setting up")
                default:
                    self.logger.log(
                        level: .warning,
                        tag: Socket.serverTag,
                        message: "server unknown state \(state)")
                }
            }

            self.listener?.start(queue: self.queue)
        }

        private func connectionStarted() {
            self.connected = true
            self.logger.log(
                level: .info,
                tag: Socket.serverTag,
                message: "server and connection started on port \(self.port)")
        }

        public func start() async throws(Socket.Error) {
            do {
                try await withCheckedThrowingContinuation { continuation in

                    self.setupServer { result in
                        switch result {
                        case .success:
                            Task {
                                await self.connectionStarted()
                                continuation.resume()
                            }
                        case let .failure(error):
                            Task {
                                await self.cancelConnection()
                                if await !self.connected {
                                    continuation.resume(throwing: error)
                                }
                            }
                        }
                    }
                }
            } catch let error as Socket.Error {
                throw error
            } catch {
                throw .other(error.localizedDescription)
            }
        }

        public func read() async throws(Socket.Error) -> Data {
            guard let connection = self.connection else {
                throw Socket.Error.connectionNotSet
            }
            do {
                return try await withCheckedThrowingContinuation {
                    continuation in

                    self.logger.log(
                        level: .debug,
                        tag: Socket.serverTag,
                        message: "TCP read data request received")

                    connection.receive(
                        minimumIncompleteLength: 1,
                        maximumLength: 1024
                    ) { data, _, isComplete, error in

                        self.logger.log(
                            level: .debug,
                            tag: Socket.serverTag,
                            message: "TCP read data received")

                        if let error = error {
                            self.logger.log(
                                level: .error,
                                tag: Socket.serverTag,
                                message: "TCP read error: \(error)")
                            continuation.resume(
                                throwing: Socket.Error.readError(
                                    error.localizedDescription))
                            return
                        }

                        guard !isComplete, let data else {
                            self.logger.log(
                                level: .notice,
                                tag: Socket.serverTag,
                                message: "TCP read data complete")
                            Task {
                                await self.cancelConnection()
                                continuation.resume(
                                    throwing: Socket.Error.readError(
                                        "Data Complete"))
                            }
                            return
                        }
                        continuation.resume(returning: data)
                    }

                }
            } catch let error as Socket.Error {
                throw error
            } catch {
                throw .other(error.localizedDescription)
            }
        }

        public func write(_ data: Data) async throws {

        }
    }

    actor TcpClient<L: Utils.Logger> {
        private let host: NWEndpoint.Host
        private let port: NWEndpoint.Port
        private var connection: NWConnection?
        private let logger: L
        private var connected: Bool = false

        public init(
            port: UInt16,
            host: String,
            logger: L
        ) throws(Socket.Error) {

            self.host = NWEndpoint.Host(host)
            guard let port = NWEndpoint.Port(rawValue: port) else {
                throw Socket.Error.invalidPort(port)
            }
            self.port = port
            self.logger = logger
        }

        private func clientConnected() {
            self.connected = true
            logger.log(
                level: .info,
                tag: Socket.clientTag,
                message: "client connected to \(self.host):\(self.port)")
        }

        private func cancelConnection() {
            self.connection?.cancel()
            self.connection = nil
            self.logger.log(
                level: .info,
                tag: Socket.clientTag,
                message: "cancelling client connection")
        }

        public func start() async throws(Socket.Error) {
            do {
                try await withCheckedThrowingContinuation { continuation in
                    self.connection = NWConnection(
                        host: self.host,
                        port: self.port,
                        using: .tcp)

                    self.connection?.stateUpdateHandler = { [weak self] state in
                        switch state {
                        case .ready:
                            self?.logger.log(
                                level: .info,
                                tag: Socket.clientTag,
                                message: "client connection ready")
                            Task {
                                await self?.clientConnected()
                                continuation.resume()
                            }
                        case .cancelled:
                            self?.logger.log(
                                level: .warning,
                                tag: Socket.clientTag,
                                message: "client connection cancelled")

                            Task {
                                await self?.cancelConnection()
                                if await self?.connected == false {
                                    continuation.resume(
                                        throwing: Socket.Error
                                            .connectionCancelled)
                                }
                            }
                        case let .failed(error):
                            self?.logger.log(
                                level: .error,
                                tag: Socket.clientTag,
                                message:
                                    "client connection failed with error: \(error)"
                            )
                            Task {
                                await self?.cancelConnection()
                                if await self?.connected == false {
                                    continuation.resume(
                                        throwing: Socket.Error.other(
                                            error.localizedDescription))
                                }
                            }
                        case .preparing:
                            self?.logger.log(
                                level: .info,
                                tag: Socket.clientTag,
                                message: "client connection preparing")
                        case .setup:
                            self?.logger.log(
                                level: .info,
                                tag: Socket.clientTag,
                                message: "client connection setting up")
                        case let .waiting(error):
                            self?.logger.log(
                                level: .error,
                                tag: Socket.clientTag,
                                message:
                                    "client connection waiting with error: \(error)"
                            )
                        default:
                            self?.logger.log(
                                level: .warning,
                                tag: Socket.clientTag,
                                message:
                                    "client connection unknown state \(state)")
                        }
                    }

                    self.connection?.start(
                        queue: DispatchQueue(
                            label: "TCPClientQueue",
                            qos: .userInteractive))
                }
            } catch let error as Socket.Error {
                throw error
            } catch {
                throw Socket.Error.other(error.localizedDescription)
            }
        }

        public func send(data: Data) {
            self.connection?.send(
                content: data,
                completion: .contentProcessed { error in
                    self.logger.log(
                        level: .debug,
                        tag: "TCPClient",
                        message:
                            "Data sent to server with error \(String(describing: error))"
                    )
                })
        }
    }
}
