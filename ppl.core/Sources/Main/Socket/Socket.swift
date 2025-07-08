import Foundation
import Network

enum Socket {

    enum Error: LocalizedError {
        case invalidPort(UInt16)
        case listenerNotSet
        case connectionNotSet
        case readError(String)
        case connectionAlreadySet
        case connectionReset
        case other(String)
    }

    actor TcpServer<L: Utils.Logger>: Lsp.Transport {
        private let port: NWEndpoint.Port
        private let listener: NWListener?
        private var connection: NWConnection?
        private let queue: DispatchQueue
        private let logger: L

        public init(port: UInt16, logger: L) throws(Socket.Error) {
            self.logger = logger

            guard let port = NWEndpoint.Port(rawValue: port) else {
                throw .invalidPort(port)
            }
            self.port = port

            do {
                self.listener = try NWListener(
                    using: .tcp,
                    on: port)
            } catch {
                throw .listenerNotSet
            }

            self.queue = DispatchQueue(label: "TCPServerQueue", qos: .utility)
        }

        private func resetConnection(
            completion: @Sendable (Result<(), Socket.Error>) -> Void
        ) {
            self.connection?.cancel()
            self.connection = nil
            self.logger.log(
                level: .info,
                tag: "TCPServer",
                message: "TCP connection reset")
            completion(.failure(.connectionReset))
        }

        private func setConnection(
            _ connection: NWConnection,
            completion: @Sendable @escaping (Result<(), Socket.Error>) -> Void
        ) {
            if self.connection != nil {
                logger.log(
                    level: .warning,
                    tag: "TCPServer",
                    message: "TCP connection already set")
                completion(.failure(.connectionAlreadySet))
                return
            }

            self.connection = connection
            self.connection?.stateUpdateHandler = { [weak self] state in
                switch state {
                case .ready:
                    self?.logger.log(
                        level: .info,
                        tag: "TCPServer",
                        message: "TCP connection ready")
                    completion(.success(()))
                case let .failed(error):
                    self?.logger.log(
                        level: .error,
                        tag: "TCPServer",
                        message: "TCP connection failed with error: \(error)")
                    Task {
                        await self?.resetConnection(completion: completion)
                    }
                case let .waiting(error):
                    self?.logger.log(
                        level: .error,
                        tag: "TCPServer",
                        message: "TCP connection waiting with error: \(error)")
                case .cancelled:
                    self?.logger.log(
                        level: .warning,
                        tag: "TCPServer",
                        message: "TCP connection cancelled")
                    Task {
                        await self?.resetConnection(completion: completion)
                    }
                case .setup:
                    self?.logger.log(
                        level: .info,
                        tag: "TCPServer",
                        message: "TCP connection is setting up")
                default:
                    self?.logger.log(
                        level: .warning,
                        tag: "TCPServer",
                        message: "TCP connection unkhown state")
                }
            }
            self.connection?.start(queue: self.queue)
        }

        private func setupServer(
            completion: @Sendable @escaping (Result<(), Error>) -> Void
        ) {
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
                        tag: "TCPServer",
                        message: "TCP Server is ready on port \(self.port)"
                    )
                case let .failed(error):
                    self.logger.log(
                        level: .error,
                        tag: "TCPServer",
                        message: "TCP Server failed with error: \(error)")
                    completion(.failure(.listenerNotSet))
                case let .waiting(error):
                    self.logger.log(
                        level: .error,
                        tag: "TCPServer",
                        message: "TCP Server waiting with error: \(error)")
                case .cancelled:
                    self.logger.log(
                        level: .warning,
                        tag: "TCPServer",
                        message: "TCP server cancelled")
                    completion(.failure(.listenerNotSet))
                case .setup:
                    self.logger.log(
                        level: .info,
                        tag: "TCPServer",
                        message: "TCP Server is setting up")
                default:
                    self.logger.log(
                        level: .warning,
                        tag: "TCPServer",
                        message: "TCP Server unkhown state")
                }
            }

            self.listener?.start(queue: self.queue)
        }

        public func start() async throws(Socket.Error) {
            do {
                try await withCheckedThrowingContinuation { continuation in

                    self.setupServer { result in
                        switch result {
                        case .success:
                            continuation.resume()
                        case let .failure(error):
                            continuation.resume(throwing: error)
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
                return try await
                    withCheckedThrowingContinuation { continuation in

                    connection.receiveMessage { data, _, isComplete, error in

                        if let error = error {
                            self.logger.log(
                                level: .error,
                                tag: "TCPServer",
                                message: "TCP read error: \(error)")
                            continuation.resume(
                                throwing: Socket.Error.readError(
                                    error.localizedDescription))
                            return
                        }

                        guard isComplete, let data else {
                            self.logger.log(
                                level: .error,
                                tag: "TCPServer",
                                message: "TCP read error data incomplete")
                            continuation.resume(
                                throwing: Socket.Error.readError(
                                    "Data incomplete"))
                            return
                        }

                        continuation.resume(with: .success(data))
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

    actor TCPClient<L: Utils.Logger> {
    }
}
