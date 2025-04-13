import XCTest
@testable import PeoplCore

final class LiteralsExpressionTests: XCTestCase {

    func testStrings() throws {
        let source = """
            func main() => String
                "is this" != "different than this"..
        """
        let module = try Syntax.Module(source: source, path: "main")
        XCTAssertEqual(module.statements.count, 1)
        let statement = module.statements[0]
        guard case let .functionDefinition(functionDefinition) = statement else {
            XCTAssertTrue(false)
            return
        }

        let body = functionDefinition.body

        if case let .binary(.different, left, right) = body?.expressionType,
            case let .stringLiteral(left) = left.expressionType,
            case let .stringLiteral(right) = right.expressionType
        {
            XCTAssertEqual(left, "is this")
            XCTAssertEqual(right, "different than this")
        } else {
            XCTAssertTrue(false)
        }
    }

    func testBools() throws {
        let source = """
            func main() => String
                true or false and not false..
        """
        let module = try Syntax.Module(source: source, path: "main")
        XCTAssertEqual(module.statements.count, 1)
        let statement = module.statements[0]
        guard case let .functionDefinition(functionDefinition) = statement else {
            XCTAssertTrue(false)
            return
        }

        let body = functionDefinition.body

        if case let .binary(.or, left, right) = body?.expressionType,
            case let .boolLiteral(value1) = left.expressionType,
            case let .binary(.and, left, right) = right.expressionType,
            case let .boolLiteral(value2) = left.expressionType,
            case let .unary(.not, unary) = right.expressionType,
            case let .boolLiteral(value3) = unary.expressionType
        {
            XCTAssertEqual(value1, true)
            XCTAssertEqual(value2, false)
            XCTAssertEqual(value3, false)
        } else {
            XCTAssertTrue(false)
        }
    }

    func testTuples() throws {
        let source = """
            func main() => [A, B, C]
                [
                    a: "this thing",
                    b: "this other thing"
                ]
        """
        let module = try Syntax.Module(source: source, path: "main")
        XCTAssertEqual(module.statements.count, 1)
        let statement = module.statements[0]
        guard case let .functionDefinition(functionDefinition) = statement else {
            XCTAssertTrue(false)
            return
        }

        let body = functionDefinition.body

        if case let .namedTuple(arguments) = body?.expressionType {
        }
    }
}
