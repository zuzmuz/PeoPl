import Foundation

extension Syntax.NodeLocation: CustomDebugStringConvertible {
    public var debugDescription: String {
        return
            "\(pointRange.lowerBound.line):\(pointRange.lowerBound.column)-\(pointRange.upperBound.line):\(pointRange.upperBound.column)"
    }
}

extension Syntax.Source {
    public init(path: String) throws(Syntax.Error) {
        let fileHandle = FileHandle(forReadingAtPath: path)
        guard let outputData = try? fileHandle?.read(upToCount: Int.max),
            let outputString = String(
                data: outputData, encoding: .utf8)
        else {
            throw .sourceUnreadable
        }
        self.content = outputString
        self.name = path
    }

    public init(url: URL) throws(Syntax.Error) {
        guard let data = try? Data.init(contentsOf: url),
            let source = String(data: data, encoding: .utf8)
        else {
            throw .sourceUnreadable
        }
        self.content = source
        self.name = url.path
    }
}
