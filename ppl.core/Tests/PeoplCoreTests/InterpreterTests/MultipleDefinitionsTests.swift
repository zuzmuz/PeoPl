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
        let project = Project(modules: ["main": module])

        XCTAssertEqual(module.statements.count, 2)
        let scope = EvaluationScope()
        XCTAssertEqual(project.evaluate(with: .nothing, and: scope), .success(.string("other")))
    }
}
