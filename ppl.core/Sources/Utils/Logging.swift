import Foundation

public enum Utils {

    // ANSI color codes
    enum TerminalColor: String {
        case black = "\u{001B}[30m"
        case red = "\u{001B}[31m"
        case green = "\u{001B}[32m"
        case yellow = "\u{001B}[33m"
        case blue = "\u{001B}[34m"
        case magenta = "\u{001B}[35m"
        case cyan = "\u{001B}[36m"
        case white = "\u{001B}[37m"

        // Bright colors
        case brightBlack = "\u{001B}[90m"
        case brightRed = "\u{001B}[91m"
        case brightGreen = "\u{001B}[92m"
        case brightYellow = "\u{001B}[93m"
        case brightBlue = "\u{001B}[94m"
        case brightMagenta = "\u{001B}[95m"
        case brightCyan = "\u{001B}[96m"
        case brightWhite = "\u{001B}[97m"

        // Reset
        case reset = "\u{001B}[0m"

        // Background colors
        case bgRed = "\u{001B}[41m"
        case bgGreen = "\u{001B}[42m"
        case bgYellow = "\u{001B}[43m"
        case bgBlue = "\u{001B}[44m"

        // Text styles
        case bold = "\u{001B}[1m"
        case dim = "\u{001B}[2m"
        case italic = "\u{001B}[3m"
        case underline = "\u{001B}[4m"
    }

    /// Log message severity levels.
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
                "[VERBOSE] "
            case .debug:
                "[DEBUG]   "
            case .info:
                "[INFO]    "
            case .notice:
                "[NOTICE]  "
            case .warning:
                "[WARNING] "
            case .error:
                "[ERROR]   "
            case .critical:
                "[CRITICAL]"
            }
        }

        var color: TerminalColor {
            switch self {
            case .verbose: return .brightBlack
            case .debug: return .cyan
            case .info: return .green
            case .notice: return .blue
            case .warning: return .yellow
            case .error: return .red
            case .critical: return .brightRed
            }
        }
    }

    /// A protocol for logging messages with different severity levels
    public protocol Logger: Sendable {
        func log(
            level: LogLevel,
            tag: String,
            message: String
        )
        func log(
            level: LogLevel,
            tag: String,
            message: Data
        )
    }

    /// A logger that does nothing
    public final class NillLogger: Logger {
        public func log(
            level: Utils.LogLevel,
            tag: String,
            message: Data
        ) {}
        public func log(
            level: Utils.LogLevel,
            tag: String,
            message: String
        ) {}
    }

    /// Implements a simple console logger that prints log messages to stdout.
    public final class ConsoleLogger: Logger {
        private let level: LogLevel
        private let dateFormatter: DateFormatter

        /// Creates a console logger that prints log messages to stdout with severity above defined level
        public init(level: LogLevel = .info) {
            self.level = level
            self.dateFormatter = DateFormatter()
            self.dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        }

        private func colored(_ text: String, with colorCode: String) -> String {
            return "\(colorCode)\(text)\(TerminalColor.reset.rawValue)"
        }

        public func log(
            level: LogLevel,
            tag: String,
            message: Data
        ) {
            if level.rawValue >= self.level.rawValue {
                print(
                    colored(
                        "\(self.dateFormatter.string(for: Date())!) \(level.label) \t\(tag): \t\(String(data: message, encoding: .utf8) ?? "")",
                        with: level.color.rawValue))
            }
        }

        public func log(
            level: LogLevel,
            tag: String,
            message: String
        ) {
            log(level: level, tag: tag, message: message.data(using: .utf8)!)
        }
    }

    public final class StdErrLogger: Logger {
        private let level: LogLevel
        private let dateFormatter: DateFormatter

        public init(level: LogLevel = .info) {
            self.level = level
            self.dateFormatter = DateFormatter()
            self.dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        }

        public func log(
            level: LogLevel,
            tag: String,
            message: Data
        ) {
            if level.rawValue >= self.level.rawValue {
                fputs(
                    "\(self.dateFormatter.string(for: Date())!) \(level.label) \t\(tag): \t\(String(data: message, encoding: .utf8) ?? "")\n",
                    stderr)
            }
        }

        public func log(
            level: LogLevel,
            tag: String,
            message: String
        ) {
            log(level: level, tag: tag, message: message.data(using: .utf8)!)
        }
    }

    /// Logger that logs into a file
    public final class FileLogger: Logger {
        private let handle: FileHandle
        private let dateFormatter: DateFormatter
        private let level: LogLevel
        private let queue = DispatchQueue(label: "file-logger", qos: .utility)

        public init(filePath: URL, level: LogLevel) throws {
            let folderPath = filePath.deletingLastPathComponent()
            if !FileManager.default.fileExists(
                atPath: folderPath.absoluteString)
            {
                try FileManager.default.createDirectory(
                    at: folderPath, withIntermediateDirectories: true)
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
            self.level = level
        }

        deinit {
            handle.closeFile()
        }

        public func log(
            level: LogLevel,
            tag: String,
            message: Data
        ) {
            queue.async {
                if level.rawValue >= self.level.rawValue {
                    self.handle.seekToEndOfFile()
                    self.handle.write(
                        Data(
                            "\(self.dateFormatter.string(for: Date())!) \t"
                                .utf8
                        ))
                    self.handle.write(Data("\(level.label) \t".utf8))
                    self.handle.write(Data("\(tag) \t".utf8))
                    self.handle.write(message)
                    self.handle.write(Data("\n".utf8))
                }
            }
        }

        public func log(
            level: LogLevel,
            tag: String,
            message: String
        ) {
            log(level: level, tag: tag, message: message.data(using: .utf8)!)
        }
    }
}
