#if !canImport(Network) || !canImport(Foundation)
import Utils
import Foundation

extension Socket {
	public actor TcpClient<L: Utils.Logger>: Lsp.Transport {

		public init(
			port: UInt16,
			host: String,
			logger: L
		) throws(Socket.Error) {
		}

		public func start() async throws(Socket.Error) {
			fatalError("TcpClient is not supported on this platform")
		}

		public func write(_ data: Data) async throws(Socket.Error) {
			fatalError("TcpClient is not supported on this platform")
		}

		public func read() async throws(Socket.Error) -> Data {
			fatalError("TcpClient is not supported on this platform")
		}
	}
}
#endif
