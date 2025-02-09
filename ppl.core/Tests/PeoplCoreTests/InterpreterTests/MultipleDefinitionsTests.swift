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

    func testCallingWithArgument() throws {
        let source = """
            func add(this: I32, that: I32) => I32
                this + that
            func main() => I32
                add(this: 2, that: 3)
        """
        let module = try Module(source: source, path: "main")
        let project = Project(modules: ["main": module])

        XCTAssertEqual(module.statements.count, 2)
        let scope = EvaluationScope()
        XCTAssertEqual(project.evaluate(with: .nothing, and: scope), .success(.int(5)))
    }

    func testRecursion() throws {
        let source = """
            func factorial(of: I32) => I32
                of |>
                |value <= 1| 1,
                |value| value*factorial(of: value-1)

            func (I32) main() => I32
                |i| factorial(of: i)
        """
        let module = try Module(source: source, path: "main")
        let project = Project(modules: ["main": module])

        XCTAssertEqual(module.statements.count, 2)
        let scope = EvaluationScope()
        XCTAssertEqual(project.evaluate(with: .int(5), and: scope), .success(.int(120)))
        XCTAssertEqual(project.evaluate(with: .int(4), and: scope), .success(.int(24)))
        XCTAssertEqual(project.evaluate(with: .int(3), and: scope), .success(.int(6)))
        XCTAssertEqual(project.evaluate(with: .int(2), and: scope), .success(.int(2)))
        XCTAssertEqual(project.evaluate(with: .int(1), and: scope), .success(.int(1)))
        XCTAssertEqual(project.evaluate(with: .int(0), and: scope), .success(.int(1)))
    }

    func testCallWithInput() throws {
        let source = """
            func (I32) factorial() => I32
                |value <= 1| 1,
                |value| value * (value - 1 |> factorial())
            func (I32) main() => I32
                factorial()
        """
        let module = try Module(source: source, path: "main")
        let project = Project(modules: ["main": module])

        XCTAssertEqual(module.statements.count, 2)
        let scope = EvaluationScope()
        XCTAssertEqual(project.evaluate(with: .int(5), and: scope), .success(.int(120)))
        XCTAssertEqual(project.evaluate(with: .int(4), and: scope), .success(.int(24)))
        XCTAssertEqual(project.evaluate(with: .int(3), and: scope), .success(.int(6)))
        XCTAssertEqual(project.evaluate(with: .int(2), and: scope), .success(.int(2)))
        XCTAssertEqual(project.evaluate(with: .int(1), and: scope), .success(.int(1)))
        XCTAssertEqual(project.evaluate(with: .int(0), and: scope), .success(.int(1)))
    }

    func testCallWithInputAccessed() throws {
        let source = """
            func (I32) factorial() => I32
                |value <= 1| 1,
                |value| value * (value - 1).factorial()
            func (I32) main() => I32
                factorial()
        """
        let module = try Module(source: source, path: "main")
        let project = Project(modules: ["main": module])

        XCTAssertEqual(module.statements.count, 2)
        let scope = EvaluationScope()
        XCTAssertEqual(project.evaluate(with: .int(5), and: scope), .success(.int(120)))
        XCTAssertEqual(project.evaluate(with: .int(4), and: scope), .success(.int(24)))
        XCTAssertEqual(project.evaluate(with: .int(3), and: scope), .success(.int(6)))
        XCTAssertEqual(project.evaluate(with: .int(2), and: scope), .success(.int(2)))
        XCTAssertEqual(project.evaluate(with: .int(1), and: scope), .success(.int(1)))
        XCTAssertEqual(project.evaluate(with: .int(0), and: scope), .success(.int(1)))
    }

    func testFactorialWithTCO() throws { // Not really
        let source = """
            func (I32) factorial() => I32
                factorial(acc: 1)

            func (I32) factorial(acc: I32) => I32
                |input <= 1| acc,
                |input| (input-1).factorial(acc: acc*input)

            func (I32) main() => I32
                factorial()
        """
        let module = try Module(source: source, path: "main")
        let project = Project(modules: ["main": module])

        XCTAssertEqual(module.statements.count, 3)
        let scope = EvaluationScope()
        XCTAssertEqual(project.evaluate(with: .int(5), and: scope), .success(.int(120)))
        XCTAssertEqual(project.evaluate(with: .int(4), and: scope), .success(.int(24)))
        XCTAssertEqual(project.evaluate(with: .int(3), and: scope), .success(.int(6)))
        XCTAssertEqual(project.evaluate(with: .int(2), and: scope), .success(.int(2)))
        XCTAssertEqual(project.evaluate(with: .int(1), and: scope), .success(.int(1)))
        XCTAssertEqual(project.evaluate(with: .int(0), and: scope), .success(.int(1)))
    }
}
