import SwiftTreeSitter
import TreeSitterSimpl
import Foundation


class AST {

    let language: Language
    let parser: Parser
    init(path: String) throws {
        language = Language(tree_sitter_simpl())
        parser = Parser()
        try parser.setLanguage(language)

        let fileHandle = FileHandle(forReadingAtPath: path)

        fileHandle.read()
    }
}

let parser = try AST(path: "../basic.ppl")
