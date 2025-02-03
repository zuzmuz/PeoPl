import XCTest
@testable import PeoplCore

final class MainEvaluationTests: XCTestCase {
    func testNothing() throws {
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
    func testHelloWorld() throws {
        let source = """
            func main() => String
                "Hello World"..
            """
        let module = try Module(source: source, path: "main")
        let scope = EvaluationScope(locals: [:])

        if case let .success(evaluation) = module.evaluate(with: .nothing, and: scope) {
            XCTAssertEqual(evaluation, .string("Hello World"))
        } else {
            XCTAssertTrue(false)
        }
    }
}
