import Foundation

extension Syntax.Source {
	public init(path: String) throws(Syntax.Error) {
		let fileHandle = FileHandle(forReadingAtPath: path)
		guard let outputData = try? fileHandle?.read(upToCount: Int.max),
			let outputString = String(
				data: outputData, encoding: .utf8
			)
		else {
			throw .sourceUnreadable
		}
		content = outputString
		name = path
	}

	public init(url: URL) throws(Syntax.Error) {
		guard let data = try? Data(contentsOf: url),
			let source = String(data: data, encoding: .utf8)
		else {
			throw .sourceUnreadable
		}
		content = source
		name = url.path
	}
}
