import SwiftTreeSitter
import TreeSitterPeoPl
import Foundation

enum SemanticError: Error {
    case sourceUnreadable
}

extension Node {
    func compactMapChildren<T>(block: (Node) -> T?) -> [T] {
        (0..<childCount).compactMap { i in
            guard let child = child(at: i) else { return nil }
            return block(child)
        }
    }

    func compactMapChildrenEnumerated<T>(block: (Int, Node) -> T?) -> [T] {
        (0..<childCount).compactMap { i in
            guard let child = child(at: i) else { return nil }
            return block(i, child)
        }
    }
}

struct SyntaxTree {
    let statements: [Statement]
    init(path: String) throws {
        let language = Language(tree_sitter_peopl())
        let parser = Parser()
        try parser.setLanguage(language)

        let fileHandle = FileHandle(forReadingAtPath: path)

        guard let outputData = try fileHandle?.read(upToCount: Int.max),
            let outputString = String(data: outputData, encoding: .utf8)
        else {
            throw SemanticError.sourceUnreadable
        }

        let tree = parser.parse(outputString)
        guard let rootNode = tree?.rootNode else {
            throw SemanticError.sourceUnreadable
        }

        self.statements = rootNode.compactMapChildren { node in
            Statement(from: node, source: outputString)
        }
    }
}
