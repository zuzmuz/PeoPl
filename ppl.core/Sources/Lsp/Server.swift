import Foundation
import Utils

/// The Lsp namespace
public enum Lsp {

    /// Represents a Remote Procedure Call (RPC) error in the LSP context.
    public enum RpcError: LocalizedError {
        case encodingFailed(String)
        case decodingFailed(String)
        case unknownMethod(String)

        public var errorDescription: String? {
            switch self {
            case .encodingFailed(let message):
                return "Encoding failed: \(message)"
            case .decodingFailed(let message):
                return "Decoding failed: \(message)"
            case .unknownMethod(let method):
                return "Unknown method: \(method)"
            }
        }
    }

    /// # Handler
    /// Handler protocol defines the interface for handling LSP messages
    /// that are sent from the client to the server.
    public protocol Handler: Actor {
        /// Handles a request message and returns a response message.
        /// # Params
        /// - request: ``RequestMessage`` an lsp request message sent by the client to the server
        /// # Returns:
        /// ``ResponseMessage`` an lsp response message sent by the server to the client
        func handle(request: RequestMessage) async -> ResponseMessage
        /// Handles a notification without returning a response message.
        /// # Params
        /// - notification: ``NotificationMessage`` an lsp notification sent by the client to the server
        func handle(notification: NotificationMessage) async
    }

    /// A Proxy handler that does not process lsp messages. It rather redirect the messages through a tcp connection
    public actor ProxyHandler<
        L1: Utils.Logger,
        L2: Utils.Logger
    >: Handler {
        private let logger: L1
        private let client: Socket.TcpClient<L2>
        private let coder = RpcCoder()

        /// a dictionary that holds pending requests, in order to map responses back to the requests and return from the async ``handle()`` calls
        private var pendingRequests:
            [Id: CheckedContinuation<ResponseMessage, Never>] = [:]

        /// Creates a ``ProxyHanlder``
        /// # Usage
        /// In order to properly use the proxy handler, it needs to be started before the lsp server that uses it.
        /// To start the server call the function ``run()``
        /// # Params
        /// - client: ``Socket.TcpClient`` the tcp client to forward messages to and from
        /// - logger: ``Utils.Logger`` a generic logger
        public init(
            client: Socket.TcpClient<L2>,
            logger: L1
        ) throws(Socket.Error) {
            self.logger = logger
            self.client = client
        }

        /// Starts the tcp client and connects to a tcp server.
        /// Launches a concurrent task to receive tcp messages from this server.
        public func run() async throws {
            try await self.client.start()
            Task {
                var data = Data()
                while true {

                    data += try await client.read()

                    logger.log(
                        level: .verbose,
                        tag: "LspProxyHandler",
                        message: "message received")
                    logger.log(
                        level: .verbose,
                        tag: "LspProxyHandler",
                        message: data)

                    let decodedMessage = self.coder.decode(data: data)

                    switch decodedMessage.result {
                    case let .notification(notification):
                        logger.log(
                            level: .info,
                            tag: "LspProxyHandler",
                            message: "notification \(notification.method.name)"
                        )
                    // TODO: the proxy needs to send the notification to the client
                    case let .request(request):
                        logger.log(
                            level: .info,
                            tag: "LspProxyHandler",
                            message:
                                "request id(\(request.id)) \(request.method.name)"
                        )
                    // TODO: the proxy needs to send the request to the client
                    case let .response(response):
                        logger.log(
                            level: .info,
                            tag: "LspProxyHandler",
                            message:
                                "response id(\(String(describing: response.id))"
                        )
                        if let id = response.id,
                            let continuation = self.pendingRequests.removeValue(
                                forKey: id)
                        {
                            continuation.resume(returning: response)
                        } else {
                            logger.log(
                                level: .warning,
                                tag: "LspProxyHandler",
                                message:
                                    "no pending request for response id \(String(describing: response.id))"
                            )
                        }
                    case let .error(error):
                        logger.log(
                            level: .error,
                            tag: "LspProxyHandler",
                            message: error
                        )
                    case .incomplete:
                        logger.log(
                            level: .debug,
                            tag: "LspProxyHandler",
                            message: "Incomplete message"
                        )
                    }

                    data = decodedMessage.rest ?? Data()
                }
            }
        }

        public func handle(request: RequestMessage) async -> ResponseMessage {

            return await withCheckedContinuation { continuation in

                pendingRequests[request.id] = continuation

                Task {
                    do {
                        guard let data = self.coder.encode(message: request)
                        else {
                            throw Lsp.RpcError.encodingFailed(
                                "Failed to encode request \(request.method.name)"
                            )
                        }
                        try await client.write(data)
                    } catch {
                        logger.log(
                            level: .error,
                            tag: "LspProxyHandler",
                            message:
                                "Failed to write request to tcp server: \(error.localizedDescription)"
                        )
                    }
                }
            }
        }

        public func handle(notification: Lsp.NotificationMessage) async {
            return await withCheckedContinuation { continuation in
                Task {
                    do {
                        guard
                            let data = self.coder.encode(message: notification)
                        else {
                            throw Lsp.RpcError.encodingFailed(
                                "Failed to encode notification \(notification.method.name)"
                            )
                        }
                        try await client.write(data)
                    } catch {
                        logger.log(
                            level: .error,
                            tag: "LspProxyHandler",
                            message:
                                "Failed to write notification to client: \(error.localizedDescription)"
                        )
                    }
                    continuation.resume()
                }
            }
        }
    }

    /// Transport protocol defines the interface for reading and writing data between an lsp server and lsp client
    public protocol Transport: Actor {
        /// Asynchronously reads data from the transport.
        func read() async throws -> Data
        /// Asynchronously writes data to the transport.
        func write(_ data: Data) async throws
    }

    /// StandardTransport is a concrete implementation of the Transport protocol
    /// It reads from stdin and writes to stdout
    public actor StandardTransport: Transport {
        public func read() throws -> Data {
            return FileHandle.standardInput.availableData
        }

        public func write(_ data: Data) {
            FileHandle.standardOutput.write(data)
        }
    }

    /// Global ``StandardTransport`` object
    public static let standardTransport = StandardTransport()

    /// Server actor implements the LSP server logic
    /// # Requires
    /// - A ``Handler`` responsible for the logic of the server
    /// - A ``Transport`` responsible for reading and writing messages
    /// - A ``Utils.Logger`` for logging debug info
    /// # Usage
    /// After creating the server, call the ``run()`` method.
    /// The run method is blocking and will be using the transport to read incoming messages from the transport input
    /// and write messages into the transport output
    public actor Server<H: Handler, T: Transport, L: Utils.Logger> {

        /// Rpc encoder and decoder, responsible for serializing rpc messages from and into data structures
        private let coder = RpcCoder()
        private let handler: H
        private let transport: T
        private let logger: L

        /// Creates a lsp server instance
        /// # Params
        /// - handler: ``Handler`` responsible for the logic of the server
        /// - transport: ``Transport`` responsible for reading and writing messages
        /// - logger: ``Utils.Logger`` for logging debug info
        public init(handler: H, transport: T, logger: L) {
            self.handler = handler
            self.transport = transport
            self.logger = logger
        }

        /// Runs the server.
        /// The call blocks and only ends when the lsp client ends the session or an error occurs
        /// # Throws
        /// A unhandled error that occurs at the transport or handler layer
        public func run() async throws {
            var data = Data()
            while true {

                data += try await self.transport.read()

                logger.log(
                    level: .verbose,
                    tag: "LspServer",
                    message: "data received from transport")
                logger.log(
                    level: .verbose,
                    tag: "LspServer",
                    message: data)

                let decodedMessage = self.coder.decode(data: data)

                switch decodedMessage.result {
                case let .notification(notification):
                    logger.log(
                        level: .info,
                        tag: "LspServer",
                        message: "Notification \(notification.method.name)"
                    )
                    await handler.handle(notification: notification)
                    if case .exit = notification.method {
                        logger.log(
                            level: .notice,
                            tag: "LspServer",
                            message: "Exiting")
                        return
                    }
                case let .request(request):
                    logger.log(
                        level: .info,
                        tag: "LspServer",
                        message:
                            "Request id(\(request.id)) \(request.method.name)")

                    let response = await handler.handle(request: request)

                    logger.log(
                        level: .info,
                        tag: "LspServer",
                        message:
                            "Response id(\(String(describing: response.id))")
                    if let encodedResponse = self.coder.encode(
                        message: response)
                    {

                        logger.log(
                            level: .verbose,
                            tag: "LspServer",
                            message: "data sent to transport")
                        logger.log(
                            level: .verbose,
                            tag: "LspServer",
                            message: encodedResponse)
                        try await self.transport.write(encodedResponse)
                    } else {
                        logger.log(
                            level: .error,
                            tag: "LspServer",
                            message: "Failed to encode response")
                    }
                case let .response(response):
                    logger.log(
                        level: .info,
                        tag: "LspServer",
                        message:
                            "Response id(\(String(describing: response.id))"
                    )
                // TODO: handle responses from client based on server requests
                case let .error(message):
                    if message == "Unknown method exit" {
                        logger.log(
                            level: .error,
                            tag: "LspServer",
                            message: "Exiting cause error")
                        return
                    }
                    logger.log(
                        level: .error,
                        tag: "LspServer",
                        message: message)
                case .incomplete:
                    logger.log(
                        level: .debug,
                        tag: "LspServer",
                        message: "Incomplete message")
                }

                data = decodedMessage.rest ?? Data()
            }
        }
    }
}
