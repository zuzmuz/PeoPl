import Foundation
import Network

extension Socket {

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
