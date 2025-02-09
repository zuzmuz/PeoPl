
import XCTest
@testable import PeoplCore

final class TuplePipingTests: XCTestCase {
    func testCapturing() throws {
        let source = """
            func main() => I32
                [0, 1] |>
                |i, _| i
        """
        let module = try Module(source: source, path: "main")
        let scope = EvaluationScope(locals: [:])

        XCTAssertEqual(module.evaluate(with: .nothing, and: scope), .success(.int(0)))
    }

    func testCapturingWithScope() throws {
        let source = """
            func main(a: I32, b: I32) => I32
                [a*3, b-2] |>
                |i, j| i%j
        """
        let module = try Module(source: source, path: "main")

        var scope = EvaluationScope(locals: ["a": .int(6), "b": .int(5)])
        XCTAssertEqual(module.evaluate(with: .nothing, and: scope), .success(.int(0)))

        scope = EvaluationScope(locals: ["a": .int(7), "b": .int(13)])
        XCTAssertEqual(module.evaluate(with: .nothing, and: scope), .success(.int(10)))

        scope = EvaluationScope(locals: ["a": .int(6), "b": .int(7)])
        XCTAssertEqual(module.evaluate(with: .nothing, and: scope), .success(.int(3)))
    }

    func testSum() throws {
        let source = """
            func main(from: I32, to: I32) => I32
                [0, from] |>
                |sum, value: value < to| ([sum+value, value+1])^,
                |sum, _| sum
        """
        let module = try Module(source: source, path: "main")
        var scope = EvaluationScope(locals: ["from": .int(0), "to": .int(5)])
        XCTAssertEqual(module.evaluate(with: .nothing, and: scope), .success(.int(10)))
        scope = EvaluationScope(locals: ["from": .int(2), "to": .int(10)])
        XCTAssertEqual(module.evaluate(with: .nothing, and: scope), .success(.int(44)))
        scope = EvaluationScope(locals: ["from": .int(5), "to": .int(4)])
        XCTAssertEqual(module.evaluate(with: .nothing, and: scope), .success(.int(0)))
    }
    
    func testFactorial() throws {
        let source = """
            func main(of: I32) => I32
                [1, 1] |>
                |fact, value: value <= of| ([fact*value, value+1])^,
                |fact, _| fact
        """
        let module = try Module(source: source, path: "main")
        var scope = EvaluationScope(locals: ["of": .int(4)])
        XCTAssertEqual(module.evaluate(with: .nothing, and: scope), .success(.int(24)))
        scope = EvaluationScope(locals: ["of": .int(5)])
        XCTAssertEqual(module.evaluate(with: .nothing, and: scope), .success(.int(120)))
        scope = EvaluationScope(locals: ["of": .int(0)])
        XCTAssertEqual(module.evaluate(with: .nothing, and: scope), .success(.int(1)))
    }

    func testingNamedTuples() throws {
        let source = """
            func main(of: I32) => I32
                [a: 1, b: 1] |>
                |fact, value: value <= of| ([fact*value, value+1])^,
                |fact, _| fact
        """
        let module = try Module(source: source, path: "main")
        var scope = EvaluationScope(locals: ["of": .int(4)])
        XCTAssertEqual(module.evaluate(with: .nothing, and: scope), .success(.int(24)))
        scope = EvaluationScope(locals: ["of": .int(5)])
        XCTAssertEqual(module.evaluate(with: .nothing, and: scope), .success(.int(120)))
        scope = EvaluationScope(locals: ["of": .int(0)])
        XCTAssertEqual(module.evaluate(with: .nothing, and: scope), .success(.int(1)))
    }
}
