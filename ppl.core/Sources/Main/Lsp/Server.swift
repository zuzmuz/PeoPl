import Foundation

public enum Lsp {

    public protocol Handler: Actor {
        func handle(request: RequestMessage) async -> ResponseMessage
        func handle(notification: NotificationMessage) async
    }

    public protocol Transport: Actor {
        func read() async -> Data
        func write(_ data: Data) async
    }

    actor StandardTransport: Lsp.Transport {
        func read() -> Data {
            return FileHandle.standardInput.availableData
        }

        func write(_ data: Data) {
            FileHandle.standardOutput.write(data)
        }
    }

    public actor Server<H: Handler, T: Transport> {

        private let coder: RPCCoder
        private var iteration: Int = 0

        private let handler: H
        private let transport: T
        private let logger: (any Logger)?

        public init(handler: H, transport: T, logger: (any Logger)? = nil) {
            self.handler = handler
            self.transport = transport
            self.logger = logger
            self.coder = RPCCoder()
        }

        public func run() async {
            var data = Data()
            while true {
                data += await self.transport.read()

                logger?.log(
                    level: .verbose,
                    message: "Message received number: \(self.iteration)")
                self.iteration += 1

                logger?.log(level: .verbose, message: "Input")
                logger?.log(level: .verbose, message: data)

                let decodedMessage = self.coder.decode(data: data)

                switch decodedMessage.result {
                case let .notification(notification):
                    logger?.log(
                        level: .info,
                        message: "Notification \(notification.method.name)"
                    )
                    // Task {
                        await handler.handle(notification: notification)
                    // }
                    if case .exit = notification.method {
                        logger?.log(level: .notice, message: "Exiting")
                        return
                    }
                case let .request(request):
                    logger?.log(
                        level: .info,
                        message: "Request id(\(request.id)) \(request.method.name)")

                    // Task {
                        let response = await handler.handle(request: request)

                        logger?.log(
                            level: .info,
                            message: "Response id(\(String(describing: response.id))")
                        if let encodedResponse = self.coder.encode(
                            response: response)
                        {

                            logger?.log(level: .verbose, message: "Output")
                            logger?.log(
                                level: .verbose, message: encodedResponse)
                            await self.transport.write(encodedResponse)
                        } else {
                            logger?.log(
                                level: .error,
                                message: "Failed to encode response")
                        }
                    // }
                case let .error(message):
                    if message == "Unknown method exit" {
                        logger?.log(
                            level: .error, message: "Exiting cause error")
                        return
                    }
                    logger?.log(level: .error, message: message)
                case .incomplete:
                    logger?.log(level: .debug, message: "Incomplete message")
                }

                data = decodedMessage.rest ?? Data()
            }
        }
    }
}
