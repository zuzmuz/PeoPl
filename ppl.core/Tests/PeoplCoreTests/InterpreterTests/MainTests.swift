import XCTest
@testable import PeoplCore

final class MainTests: XCTestCase {
    func testHelloWorld() throws {
        let source = """
            func main() => Nothing
                Nothing..
            """
        let module = try Module(source: source, path: "main")
        let scope = EvaluationScope(locals: [:])

        if case let .success(evaluation) = module.evaluate(with: .nothing, and: scope) {
            XCTAssertEqual(evaluation, .nothing)
        } else {
            XCTAssertTrue(false)
        }
    }
}
