import XCTest
import SwiftTreeSitter
import TreeSitterSimpl

final class TreeSitterSimplTests: XCTestCase {
    func testCanLoadGrammar() throws {
        let parser = Parser()
        let language = Language(language: tree_sitter_simpl())
        XCTAssertNoThrow(try parser.setLanguage(language),
                         "Error loading Simpl grammar")
    }
}
