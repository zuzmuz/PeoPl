#if !canImport(Network) || !canImport(Foundation)
import Utils
import Foundation

extension Socket {

	public actor TcpServer<L: Utils.Logger>: Lsp.Transport {

		public init(port: UInt16, logger: L) throws(Socket.Error) {
		}

		public func start() async throws(Socket.Error) {
			fatalError("TcpServer is not supported on this platform")
		}

		public func read() async throws(Socket.Error) -> Data {
			fatalError("TcpServer is not supported on this platform")
		}

		public func write(_ data: Data) async throws(Socket.Error) {
			fatalError("TcpServer is not supported on this platform")
		}
	}
}
#endif
