import Foundation

extension Lsp {

    public enum LogLevel: Int, Sendable {
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

    public final class FileLogger: Logger, Sendable {
        private let handle: FileHandle
        private let dateFormatter: DateFormatter
        private let level: LogLevel = .info
        private let queue = DispatchQueue(label: "file-logger", qos: .utility)

        public init(path: URL, fileName: String, level: LogLevel) throws {
            let filePath = path.appending(path: fileName)
            if !FileManager.default.fileExists(atPath: path.relativeString) {
                try FileManager.default.createDirectory(
                    at: path, withIntermediateDirectories: true)
                if !FileManager.default.createFile(
                    atPath: filePath.relativePath, contents: Data())
                {
                    throw NSError(
                        domain: "zida.lsp", code: 1,
                        userInfo: ["message": "Failed to create log file"])
                }
            }
            self.handle = try FileHandle(forWritingTo: filePath)
            self.dateFormatter = DateFormatter()
            self.dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        }

        deinit {
            handle.closeFile()
        }

        public func log(level: LogLevel, message: Data) {
            queue.async {
                if level.rawValue >= self.level.rawValue {
                    self.handle.seekToEndOfFile()
                    self.handle.write(
                        Data(
                            "\(self.dateFormatter.string(for: Date())!) \t".utf8
                        ))
                    self.handle.write(Data("\(level.label) \t".utf8))
                    self.handle.write(message)
                    self.handle.write(Data("\n".utf8))
                }
            }
        }

        public func log(level: LogLevel, message: String) {
            log(level: level, message: message.data(using: .utf8)!)
        }
    }
}
