import XCTest
@testable import PeoplCore

final class MultipleDefinitionTests: XCTestCase {
    func testCalling() throws {
        let source = """
                func other() => String
                    "other"
                func main() => String
                    other()
            """
        let module = try Module(source: source, path: "main")

        XCTAssertEqual(module.statements.count, 2)
        let statement = module.statements[0]
    }
}
