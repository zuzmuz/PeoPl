import XCTest

@testable import PeoplCore

final class ParserTests: XCTestCase {
    let fileNames = [
        "producttypes",
        "error",
    ]

    func testFiles() throws {
        let bundle = Bundle.module

        for name in fileNames {
            let sourceUrl = bundle.url(forResource: name, withExtension: "ppl")!
            let jsonUrl = bundle.url(forResource: name, withExtension: "json")!
            let jsonData = try Data(contentsOf: jsonUrl)

            let reference = try JSONDecoder().decode(
                Syntax.Module.self, from: jsonData)

            let source = try Syntax.Module(url: sourceUrl)

            XCTAssertEqual(source, reference)
        }
    }
}
