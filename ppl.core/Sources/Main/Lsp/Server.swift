import Foundation

public enum Lsp {

    public protocol Handler: Actor {
        func handle(request: RequestMessage) async -> ResponseMessage
        func handle(notification: NotificationMessage) async
    }

    public protocol Transport: Actor {
        func read() async throws -> Data
        func write(_ data: Data) async throws
    }

    actor StandardTransport: Transport {
        func read() throws -> Data {
            return FileHandle.standardInput.availableData
        }

        func write(_ data: Data) {
            FileHandle.standardOutput.write(data)
        }
    }

    public actor Server<H: Handler, T: Transport, L: Utils.Logger> {

        private let coder: RPCCoder
        private var iteration: Int = 0

        private let handler: H
        private let transport: T
        private let logger: L

        public init(handler: H, transport: T, logger: L) {
            self.handler = handler
            self.transport = transport
            self.logger = logger
            self.coder = RPCCoder()
        }

        public func run() async throws {
            var data = Data()
            while true {
                data += try await self.transport.read()

                logger.log(
                    level: .verbose,
                    tag: "LspServer",
                    message: "Message received number: \(self.iteration)")
                self.iteration += 1

                logger.log(
                    level: .verbose,
                    tag: "LspServer",
                    message: "Input")
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
                    // Task {
                    await handler.handle(notification: notification)
                    // }
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

                    // Task {
                    let response = await handler.handle(request: request)

                    logger.log(
                        level: .info,
                        tag: "LspServer",
                        message:
                            "Response id(\(String(describing: response.id))")
                    if let encodedResponse = self.coder.encode(
                        response: response)
                    {

                        logger.log(
                            level: .verbose,
                            tag: "LspServer",
                            message: "Output")
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
                // }
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
