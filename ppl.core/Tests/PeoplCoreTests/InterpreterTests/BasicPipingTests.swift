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
                % 3..
            """
        let module = try Module(source: source, path: "main")
        let scope = EvaluationScope(locals: [:])

        XCTAssertEqual(module.evaluate(with: .int(12), and: scope), .success(.int(1)))
    }
}

