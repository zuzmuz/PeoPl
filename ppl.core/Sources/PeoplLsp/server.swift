import Foundation

extension LSP {

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
    }

    enum LogLevel: String {
        case verbose
        case debug
        case info
        case warning
        case error
    }

    protocol Logger {
        func log(level: LogLevel, message: String)
        func log(level: LogLevel, message: Data)
    }

    actor FileLogger {

    }

    protocol Handler {
    }

    protocol Transport {
        func read() -> Data
        func write(_ data: Data)
    }

    actor Server<H: Handler, T: Transport, L: Logger> {

        private let decoder: RPCCoder
        private var iteration: Int = 0

        let handler: H
        let transport: T
        let logger: L?

        init(handler: H, transport: T, logger: L? = nil) {
            self.handler = handler
            self.transport = transport
            self.logger = logger
            self.decoder = RPCCoder()
        }

        private func handle(data: Data) {
            logger?.log(
                level: .verbose,
                message: "Message received number: \(self.iteration)")
            self.iteration += 1

            logger?.log(level: .verbose, message: "Input")
            logger?.log(level: .verbose, message: data)

            let decodedMessage = self.decoder.decode(data: data)
        }

        func run() {
            handle(data: transport.read())
        }
    }
}
