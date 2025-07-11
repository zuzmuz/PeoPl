import Foundation
import Network
import Utils

extension Socket {

    /// An implementation of the ``Lsp.Transport`` which uses a tcp connection as the interface.
    /// The TcpServer sets up a listener on a defined port and waits for a connection from a tcp client.
    /// The server only supports one tcp connection and will cancel all subsequent connetion attempts
    public actor TcpServer<L: Utils.Logger>: Lsp.Transport {
        private let port: NWEndpoint.Port
        private var listener: NWListener?
        private var connection: NWConnection?
        private let queue: DispatchQueue
        private let logger: L
        private var connected: Bool = false

        /// Creates a TcpServer
        /// # Params
        /// - port: the port to listen on
        /// - logger: ``Utils.Logger`` a logger for debugging info
        /// # Throws
        /// A ``Socket.Error`` if selected port is not valid
        public init(port: UInt16, logger: L) throws(Socket.Error) {
            self.logger = logger

            guard let port = NWEndpoint.Port(rawValue: port) else {
                throw .invalidPort(port)
            }
            self.port = port

            self.queue = DispatchQueue(label: "TCPServerQueue", qos: .utility)
        }

        /// Sets the flag for the connection state, this flag is used to prevent multiple continuation calls in the ``setupServer()`` call
        private func setConnection(_ value: Bool) {
            self.connected = value
        }

        /// Cancels the connection and sets it into nil
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
                connection.cancel()
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
                        level: .verbose,
                        tag: Socket.serverTag,
                        message: "connection is setting up")
                case .preparing:
                    self?.logger.log(
                        level: .verbose,
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
                self.listener?.newConnectionHandler =
                    { [weak self] connection in
                        Task {
                            await self?.setConnection(
                                connection,
                                completion: completion)
                        }
                    }
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
                        level: .warning,
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
                        level: .verbose,
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

        /// Starts the tcp server.
        /// # Returns
        /// When the listener is set and after a connection with a tcp client is established
        /// # Throws
        /// A ``Socket.Error``
        /// - if the tcp port is in use and the listener could not be created
        /// - if the connection fails or could not be created
        public func start() async throws(Socket.Error) {
            do {
                try await withCheckedThrowingContinuation { continuation in

                    self.setupServer { result in
                        switch result {
                        case .success:
                            Task {
                                if await !self.connected {
                                    await self.setConnection(true)
                                    continuation.resume()
                                }
                            }
                        case let .failure(error):
                            Task {
                                let wasConnected = await self.connected
                                await self.setConnection(false)
                                await self.cancelConnection()
                                if !wasConnected {
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

                    connection.receive(
                        minimumIncompleteLength: 1,
                        maximumLength: 1024
                    ) { data, _, isComplete, error in

                        self.logger.log(
                            level: .verbose,
                            tag: Socket.serverTag,
                            message: "data received")

                        if let error = error {
                            self.logger.log(
                                level: .error,
                                tag: Socket.serverTag,
                                message: "data received error: \(error)")
                            continuation.resume(
                                throwing: Socket.Error.readError(
                                    error.localizedDescription))
                            return
                        }

                        guard !isComplete, let data else {
                            self.logger.log(
                                level: .notice,
                                tag: Socket.serverTag,
                                message: "stream complete")
                            Task {
                                await self.cancelConnection()
                                continuation.resume(
                                    throwing: Socket.Error.readError(
                                        "stream Complete"))
                            }
                            return
                        }

                        self.logger.log(
                            level: .verbose,
                            tag: Socket.serverTag,
                            message: "data received size: \(data.count)")
                        self.logger.log(
                            level: .verbose,
                            tag: Socket.serverTag,
                            message: data)

                        continuation.resume(returning: data)
                    }

                }
            } catch let error as Socket.Error {
                throw error
            } catch {
                throw .other(error.localizedDescription)
            }
        }

        public func write(_ data: Data) async throws(Socket.Error) {
            self.logger.log(
                level: .verbose,
                tag: serverTag,
                message: "sending data")
            self.logger.log(
                level: .verbose,
                tag: serverTag,
                message: data)

            guard let connection = self.connection else {
                self.logger.log(
                    level: .error,
                    tag: serverTag,
                    message: "why is the connection not set")
                throw .connectionNotSet
            }
            do {
                return try await withCheckedThrowingContinuation {
                    continuation in

                    connection.send(
                        content: data,
                        completion: .contentProcessed { error in
                            if let error {
                                self.logger.log(
                                    level: .verbose,
                                    tag: serverTag,
                                    message: "data sent")
                                continuation.resume(
                                    throwing: Socket.Error.readError(
                                        error.localizedDescription))
                                return
                            }
                            continuation.resume()
                        })
                }
            } catch let error as Socket.Error {
                throw error
            } catch {
                throw .other(error.localizedDescription)
            }
        }
    }
}
