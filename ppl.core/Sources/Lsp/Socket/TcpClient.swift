import Foundation
import Network
import Utils

extension Socket {

    public actor TcpClient<L: Utils.Logger>: Lsp.Transport {
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

        private func setConnected(_ value: Bool) {
            logger.log(
                level: .verbose,
                tag: Socket.clientTag,
                message: "setting connected to \(value)")
            self.connected = value
        }

        private func cancelConnection() {
            if let connection = self.connection {
                connection.cancel()
                self.connection = nil
                logger.log(
                    level: .info,
                    tag: Socket.clientTag,
                    message: "cancelling client connection")
            }
        }

        public func start() async throws(Socket.Error) {
            do {
                self.connection = NWConnection(
                    host: self.host,
                    port: self.port,
                    using: .tcp)

                try await withCheckedThrowingContinuation { continuation in
                    self.connection?.stateUpdateHandler = { [weak self] state in
                        guard let self else {
                            return
                        }
                        switch state {
                        case .ready:
                            self.logger.log(
                                level: .info,
                                tag: Socket.clientTag,
                                message: "connection ready")
                            Task {
                                if await !self.connected {
                                    await self.setConnected(true)
                                    continuation.resume()
                                }
                            }
                        case .cancelled:
                            self.logger.log(
                                level: .warning,
                                tag: Socket.clientTag,
                                message: "connection cancelled")

                            Task {
                                let wasConnected = await self.connected
                                await self.setConnected(false)
                                await self.cancelConnection()
                                if !wasConnected {
                                    continuation.resume(
                                        throwing: Socket.Error
                                            .connectionCancelled)
                                }
                            }
                        case let .failed(error):
                            self.logger.log(
                                level: .error,
                                tag: Socket.clientTag,
                                message:
                                    "connection failed with error: \(error)"
                            )
                            Task {
                                let wasConnected = await self.connected
                                await self.setConnected(false)
                                await self.cancelConnection()
                                if !wasConnected {
                                    continuation.resume(
                                        throwing: Socket.Error
                                            .connectionCancelled)
                                }
                            }
                        case .preparing:
                            self.logger.log(
                                level: .verbose,
                                tag: Socket.clientTag,
                                message: "connection preparing")
                        case .setup:
                            self.logger.log(
                                level: .verbose,
                                tag: Socket.clientTag,
                                message: "connection setting up")
                        case let .waiting(error):
                            self.logger.log(
                                level: .warning,
                                tag: Socket.clientTag,
                                message:
                                    "client connection waiting with error: \(error)"
                            )
                        default:
                            self.logger.log(
                                level: .warning,
                                tag: Socket.clientTag,
                                message:
                                    "client connection unknown state \(state)")
                        }
                    }

                    self.connection?.start(
                        queue: DispatchQueue(
                            label: "TcpClientQueue",
                            qos: .userInteractive))
                }
            } catch let error as Socket.Error {
                throw error
            } catch {
                throw Socket.Error.other(error.localizedDescription)
            }
        }

        public func write(_ data: Data) async throws(Socket.Error) {
            self.logger.log(
                level: .verbose,
                tag: clientTag,
                message: "sending data")
            self.logger.log(
                level: .verbose,
                tag: clientTag,
                message: data)

            self.logger.log(
                level: .verbose,
                tag: clientTag,
                message: "connection state: \(String(describing: self.connection?.state))")

            guard let connection = self.connection else {
                self.logger.log(
                    level: .error,
                    tag: clientTag,
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
                                    tag: clientTag,
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

        public func read() async throws(Socket.Error) -> Data {
            guard let connection = self.connection else {
                throw Socket.Error.connectionNotSet
            }

            do {
                return try await withCheckedThrowingContinuation {
                    continuation in

                    logger.log(
                        level: .warning,
                        tag: Socket.clientTag,
                        message: "waiting for data from server")

                    connection.receive(
                        minimumIncompleteLength: 1,
                        maximumLength: 1024
                    ) { data, _, isComplete, error in

                        self.logger.log(
                            level: .verbose,
                            tag: Socket.clientTag,
                            message: "data received")

                        if let error = error {
                            self.logger.log(
                                level: .error,
                                tag: Socket.clientTag,
                                message: "data received error: \(error)")
                            continuation.resume(
                                throwing: Socket.Error.readError(
                                    error.localizedDescription))
                            return
                        }

                        guard !isComplete, let data else {
                            self.logger.log(
                                level: .notice,
                                tag: Socket.clientTag,
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
                            tag: Socket.clientTag,
                            message: "data received size: \(data.count)")
                        self.logger.log(
                            level: .verbose,
                            tag: Socket.clientTag,
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
    }
}
