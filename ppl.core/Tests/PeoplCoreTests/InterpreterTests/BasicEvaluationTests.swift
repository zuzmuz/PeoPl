import XCTest
@testable import PeoplCore

final class BasicEvaluationTests: XCTestCase {

    func testNothing() throws {
        let source = """
            func main() => Nothing
                Nothing..
            """
        let module = try Module(source: source, path: "main")
        let scope = EvaluationScope(locals: [:])

        XCTAssertEqual(module.evaluate(with: .nothing, and: scope), .success(.nothing))
    }

    func testHelloWorld() throws {
        let source = """
            func main() => String
                "Hello World"..
            """
        let module = try Module(source: source, path: "main")
        let scope = EvaluationScope(locals: [:])

        XCTAssertEqual(module.evaluate(with: .nothing, and: scope), .success(.string("Hello World")))
    }

    func testArithmetics() throws {
        let source = """
            func main() => Int
                1+2+3+4+5+6+7+8+9..
            """
        let module = try Module(source: source, path: "main")
        let scope = EvaluationScope(locals: [:])

        XCTAssertEqual(module.evaluate(with: .nothing, and: scope), .success(.int(45)))
    }

    func testAdvancedArithmetics() throws {
        let source = """
            func main() => Int
                3*5-2*6+12/3..
            """
        let module = try Module(source: source, path: "main")
        let scope = EvaluationScope(locals: [:])

        XCTAssertEqual(module.evaluate(with: .nothing, and: scope), .success(.int(7)))
    }

    func testParenthisized() throws {
        let source = """
            func main() => Int
                (20 % (3 + 4) + 4*(3-1)) / 2..
            """
        let module = try Module(source: source, path: "main")
        let scope = EvaluationScope(locals: [:])

        XCTAssertEqual(module.evaluate(with: .nothing, and: scope), .success(.int(7)))
    }
}
