import Foundation

public enum Lsp {

    public protocol Handler {
        func handle(request: RequestMessage) -> ResponseMessage
        func handle(notification: NotificationMessage)
    }

    public protocol Transport: Actor {
        func read() -> Data
        func write(_ data: Data)
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
                data += await transport.read()

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
                        message: "Notification \(notification.method)"
                    )
                    handler.handle(notification: notification)
                    if case .exit = notification.method {
                        logger?.log(level: .notice, message: "Exiting")
                        return
                    }
                case let .request(request):
                    logger?.log(
                        level: .info,
                        message: "Request id(\(request.id)) \(request.method)")
                    let response = handler.handle(request: request)
                    logger?.log(
                        level: .info,
                        message: "Response id(\(String(describing: response.id))) \(String(describing: response.result))")
                    if let encodedResponse = self.coder.encode(
                        response: response)
                    {
                        logger?.log(level: .verbose, message: encodedResponse)
                        await self.transport.write(encodedResponse)
                    } else {
                        logger?.log(
                            level: .error, message: "Failed to encode response")
                    }
                case let .error(message):
                    if message == "Unkown method exit" {
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
