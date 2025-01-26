import XCTest
import SwiftTreeSitter
import TreeSitterPeoPl

final class TreeSitterPeoPlTests: XCTestCase {
    func testCanLoadGrammar() throws {
        let parser = Parser()
        let language = Language(language: tree_sitter_peopl())
        XCTAssertNoThrow(try parser.setLanguage(language),
                         "Error loading PeoPl grammar")
    }
}
