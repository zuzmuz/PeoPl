import Foundation

public enum Lsp {

    enum DecodingResult {
        case request(RequestMessage)
        case notification(NotificationMessage)
        case error(String)
        case incomplete
    }

    struct RPCCoder {
        func decode(data: Data) -> (result: DecodingResult, rest: Data?) {
            guard
                let separatorRange = data.firstRange(
                    of: Data("\r\n\r\n".utf8))
            else {
                return (.error("No separator found"), nil)
            }

            let header = data.prefix(upTo: separatorRange.lowerBound)

            guard
                let bodySizeString = String(
                    data: header.suffix(from: header.startIndex + 16),
                    encoding: .utf8),
                let bodySize = Int(bodySizeString)
            else {
                return (.error("Failed to parse content length"), nil)
            }

            let bodyRange =
                separatorRange.upperBound..<separatorRange.upperBound + bodySize
            if bodyRange.upperBound > data.endIndex {
                return (.incomplete, data)
            }
            let body = data.subdata(in: bodyRange)
            let rest: Data? =
                if bodyRange.upperBound >= data.count - 1 {
                    nil
                } else {
                    data.suffix(from: bodyRange.upperBound)
                }

            let decoder = JSONDecoder()
            if let request = try? decoder.decode(
                RequestMessage.self, from: body)
            {
                return (.request(request), rest)
            } else if let notification = try? decoder.decode(
                NotificationMessage.self, from: body)
            {
                return (.notification(notification), rest)
            } else if let unknown = try? decoder.decode(
                UnknownMessage.self, from: body)
            {
                return (.error("Unkown method \(unknown.method)"), rest)
            } else {
                return (.error("Failed to decode message"), rest)
            }
        }

        func encode(response: ResponseMessage) -> Data? {
            let encoder = JSONEncoder()
            if let body = try? encoder.encode(response) {
                let header = Data("Content-Length: \(body.count)\r\n\r\n".utf8)
                return header + body
            }
            return nil
        }
    }

    public enum LogLevel: Int {
        /// Verbose log level (-1)
        case verbose = -1
        /// Debug log level (0)
        case debug = 0
        /// Info log level (1)
        case info = 1
        /// Notice log level (2)
        case notice = 2
        /// Warning log level (3)
        case warning = 3
        /// Error log level (4)
        case error = 4
        /// Critical log level (5)
        case critical = 5

        var label: String {
            return switch self {
            case .verbose:
                "VERBOSE"
            case .debug:
                "DEBUG"
            case .info:
                "INFO"
            case .notice:
                "NOTICE"
            case .warning:
                "WARNING"
            case .error:
                "ERROR"
            case .critical:
                "CRITICAL"
            }
        }
    }

    public protocol Logger {
        func log(level: LogLevel, message: String)
        func log(level: LogLevel, message: Data)
    }

    actor FileLogger {

    }

    public protocol Handler {
        func handle(request: RequestMessage) -> ResponseMessage
        func handle(notification: NotificationMessage)
    }

    public protocol Transport {
        func read() -> Data
        func write(_ data: Data)
    }

    public actor Server<H: Handler, T: Transport, L: Logger> {

        private let coder: RPCCoder
        private var iteration: Int = 0

        private let handler: H
        private let transport: T
        private let logger: L?

        init(handler: H, transport: T, logger: L? = nil) {
            self.handler = handler
            self.transport = transport
            self.logger = logger
            self.coder = RPCCoder()
        }

        private func handle(data: Data) {
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
                    level: .info, message: "Notification \(notification.method)"
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
                if let encodedResponse = self.coder.encode(response: response) {
                    self.transport.write(encodedResponse)
                } else {
                    logger?.log(
                        level: .error, message: "Failed to encode response")
                }
            case let .error(message):
                logger?.log(level: .error, message: message)
            case .incomplete:
                logger?.log(level: .debug, message: "Incomplete message")
            }

            if let rest = decodedMessage.rest {
                if case .incomplete = decodedMessage.result {
                    self.handle(data: transport.read() + rest)
                } else {
                    self.handle(data: rest)
                }
            } else {
                self.handle(data: transport.read())
            }
        }

        func run() {
            handle(data: transport.read())
        }
    }
}
