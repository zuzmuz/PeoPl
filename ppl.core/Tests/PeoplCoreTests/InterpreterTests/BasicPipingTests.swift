import XCTest
@testable import PeoplCore

final class BasicPipingTests: XCTestCase {

    // WARN: actually unary expression might not be that good of an idea
    func testArithmetics() throws {
        let source = """
            func (I32) main() => I32
                -10 |>
                + 3 |>
                * ( 10 / 2) |>
                % 3
            """
        let module = try Module(source: source, path: "main")
        let scope = EvaluationScope(locals: [:])

        XCTAssertEqual(module.evaluate(with: .int(12), and: scope), .success(.int(1)))
    }

    func testBranching() throws {
        let source = """
            func (I32) main() => String
                |i % 2 = 0| "is even",
                |_| "is odd"
            """
        let module = try Module(source: source, path: "main")
        let scope = EvaluationScope(locals: [:])

        XCTAssertEqual(module.evaluate(with: .int(12), and: scope), .success(.string("is even")))
        XCTAssertEqual(module.evaluate(with: .int(11), and: scope), .success(.string("is odd")))
        XCTAssertEqual(module.evaluate(with: .int(10), and: scope), .success(.string("is even")))
        XCTAssertEqual(module.evaluate(with: .int(9), and: scope), .success(.string("is odd")))
        XCTAssertEqual(module.evaluate(with: .int(8), and: scope), .success(.string("is even")))
        XCTAssertEqual(module.evaluate(with: .int(7), and: scope), .success(.string("is odd")))
        XCTAssertEqual(module.evaluate(with: .int(6), and: scope), .success(.string("is even")))
        XCTAssertEqual(module.evaluate(with: .int(5), and: scope), .success(.string("is odd")))
        XCTAssertEqual(module.evaluate(with: .int(4), and: scope), .success(.string("is even")))
        XCTAssertEqual(module.evaluate(with: .int(3), and: scope), .success(.string("is odd")))
        XCTAssertEqual(module.evaluate(with: .int(2), and: scope), .success(.string("is even")))
        XCTAssertEqual(module.evaluate(with: .int(1), and: scope), .success(.string("is odd")))
        XCTAssertEqual(module.evaluate(with: .int(0), and: scope), .success(.string("is even")))
    }

    func testBranchingWithPiping() throws {
        let source = """
            func (I32) main() => String
                |i| i % 2 |>
                |0| "is even",
                |1| "is odd"
            """
        let module = try Module(source: source, path: "main")
        let scope = EvaluationScope(locals: [:])

        XCTAssertEqual(module.evaluate(with: .int(12), and: scope), .success(.string("is even")))
        XCTAssertEqual(module.evaluate(with: .int(11), and: scope), .success(.string("is odd")))
        XCTAssertEqual(module.evaluate(with: .int(10), and: scope), .success(.string("is even")))
        XCTAssertEqual(module.evaluate(with: .int(9), and: scope), .success(.string("is odd")))
        XCTAssertEqual(module.evaluate(with: .int(8), and: scope), .success(.string("is even")))
        XCTAssertEqual(module.evaluate(with: .int(7), and: scope), .success(.string("is odd")))
        XCTAssertEqual(module.evaluate(with: .int(6), and: scope), .success(.string("is even")))
        XCTAssertEqual(module.evaluate(with: .int(5), and: scope), .success(.string("is odd")))
        XCTAssertEqual(module.evaluate(with: .int(4), and: scope), .success(.string("is even")))
        XCTAssertEqual(module.evaluate(with: .int(3), and: scope), .success(.string("is odd")))
        XCTAssertEqual(module.evaluate(with: .int(2), and: scope), .success(.string("is even")))
        XCTAssertEqual(module.evaluate(with: .int(1), and: scope), .success(.string("is odd")))
        XCTAssertEqual(module.evaluate(with: .int(0), and: scope), .success(.string("is even")))
    }


    func testBranchingWithPiping2() throws {
        let source = """
            func (I32) main() => String
                % 2 |>
                |i| i = 0 |>
                |true| "is even",
                |false| "is odd"
            """
        let module = try Module(source: source, path: "main")
        let scope = EvaluationScope(locals: [:])

        XCTAssertEqual(module.evaluate(with: .int(12), and: scope), .success(.string("is even")))
        XCTAssertEqual(module.evaluate(with: .int(11), and: scope), .success(.string("is odd")))
        XCTAssertEqual(module.evaluate(with: .int(10), and: scope), .success(.string("is even")))
        XCTAssertEqual(module.evaluate(with: .int(9), and: scope), .success(.string("is odd")))
        XCTAssertEqual(module.evaluate(with: .int(8), and: scope), .success(.string("is even")))
        XCTAssertEqual(module.evaluate(with: .int(7), and: scope), .success(.string("is odd")))
        XCTAssertEqual(module.evaluate(with: .int(6), and: scope), .success(.string("is even")))
        XCTAssertEqual(module.evaluate(with: .int(5), and: scope), .success(.string("is odd")))
        XCTAssertEqual(module.evaluate(with: .int(4), and: scope), .success(.string("is even")))
        XCTAssertEqual(module.evaluate(with: .int(3), and: scope), .success(.string("is odd")))
        XCTAssertEqual(module.evaluate(with: .int(2), and: scope), .success(.string("is even")))
        XCTAssertEqual(module.evaluate(with: .int(1), and: scope), .success(.string("is odd")))
        XCTAssertEqual(module.evaluate(with: .int(0), and: scope), .success(.string("is even")))
    }

    func testLoop() throws {
        let source = """
            func main(a: I32, b: I32) => I32
                a |>
                |i < b| (i * 2)^,
                |i| i
        """
        let module = try Module(source: source, path: "main")
        var scope = EvaluationScope(locals: ["a": .int(1), "b": .int(9)])
        XCTAssertEqual(module.evaluate(with: .nothing, and: scope), .success(.int(16)))
        
        scope = EvaluationScope(locals: ["a": .int(3), "b": .int(9)])
        XCTAssertEqual(module.evaluate(with: .nothing, and: scope), .success(.int(12)))
        
        scope = EvaluationScope(locals: ["a": .int(3), "b": .int(20)])
        XCTAssertEqual(module.evaluate(with: .nothing, and: scope), .success(.int(24)))
        
        scope = EvaluationScope(locals: ["a": .int(2), "b": .int(20)])
        XCTAssertEqual(module.evaluate(with: .nothing, and: scope), .success(.int(32)))
        
        scope = EvaluationScope(locals: ["a": .int(5), "b": .int(31)])
        XCTAssertEqual(module.evaluate(with: .nothing, and: scope), .success(.int(40)))

        scope = EvaluationScope(locals: ["a": .int(7), "b": .int(5)])
        XCTAssertEqual(module.evaluate(with: .nothing, and: scope), .success(.int(7)))
    }
}

