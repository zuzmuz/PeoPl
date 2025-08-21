import Foundation

public enum Socket {
	static let serverTag = "TcpServer"
	static let clientTag = "TcpClient"

	/// Tcp socket errors
	public enum Error: LocalizedError {
		case invalidPort(UInt16)
		case listenerNotSet
		case connectionNotSet
		case readError(String)
		case connectionAlreadySet
		case connectionCancelled
		case connectionFailed
		case other(String)

		public var errorDescription: String? {
			switch self {
			case let .invalidPort(port):
				return "invalid port: \(port)"
			case .listenerNotSet:
				return "listener not set"
			case .connectionNotSet:
				return "connection not set"
			case let .readError(message):
				return "read error: \(message)"
			case .connectionAlreadySet:
				return "connection already set"
			case .connectionCancelled:
				return "connection reset"
			case .connectionFailed:
				return "connection failed"
			case let .other(message):
				return "other error: \(message)"
			}
		}
	}
}
