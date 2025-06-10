import XCTest

@testable import PeoplCore

final class ParserTests: XCTestCase {
    func testFiles() throws {

        let bundle = Bundle.module
        // .url(forResource: "producttypes", withExtension: "ppl"))
        print(bundle.url(forResource: "producttypes", withExtension: "ppl"))
        guard
            let ppls = bundle.urls(
                forResourcesWithExtension: "ppl",
                subdirectory: "ParserTests")
        else {
            XCTFail("Could not find .ppl files in ParserTests directory")
            return
        }

        XCTAssertEqual(ppls.count, 2)

        for sourceUrl in ppls {
            let jsonUrl = sourceUrl.deletingPathExtension()
                .appendingPathExtension("json")
            let jsonData = try Data(contentsOf: jsonUrl)
            let reference = try JSONDecoder().decode(
                Syntax.Module.self, from: jsonData)

            let source = try Syntax.Module(url: sourceUrl)

            XCTAssertEqual(reference, source)
        }
    }
}
