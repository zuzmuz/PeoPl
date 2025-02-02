import XCTest
@testable import PeoplCore

final class PipeAndCallsExpressionTests: XCTestCase {
    func testHelloWorld() throws {
        let source = """
                func main() => Nothing
                    "Hello World";
                    print()..
            """
        let module = try Module(source: source, path: "main")

        XCTAssertEqual(module.statements.count, 1)
        let statement = module.statements[0]
        guard case let .functionDefinition(functionDefinition) = statement else {
            XCTAssertTrue(false)
            return
        }

        let body = functionDefinition.body

        if case let .piped(left, right) = body.expressionType,
            case let .stringLiteral(left) = left.expressionType,
            case let .call(call) = right.expressionType,
            case let .simple(command) = call.command,
            case let .field(name) = command.expressionType
        {
            XCTAssertEqual(left, "Hello World")
            XCTAssertEqual(call.arguments.count, 0)
            XCTAssertEqual(name, "print")
        } else {
            XCTAssertTrue(false)
        }
    }

    func testStringFormatting() throws {
        let source = """
            func main() => Nothing
                (1 + 2) * 3;
                print(format: "the operations value is {}")
                ..
        """
        let module = try Module(source: source, path: "main")

        XCTAssertEqual(module.statements.count, 1)
        let statement = module.statements[0]
        guard case let .functionDefinition(functionDefinition) = statement else {
            XCTAssertTrue(false)
            return
        }

        let body = functionDefinition.body

        if case let .piped(left, right) = body.expressionType,
            case let .call(call) = right.expressionType,
            case let .times(left, right) = left.expressionType,
            case let .intLiteral(value3) = right.expressionType,
            case let .plus(left, right) = left.expressionType,
            case let .intLiteral(value1) = left.expressionType,
            case let .intLiteral(value2) = right.expressionType,
            case let .simple(command) = call.command,
            case let .field(name) = command.expressionType
        {
            XCTAssertEqual(value1, 1)
            XCTAssertEqual(value2, 2)
            XCTAssertEqual(value3, 3)

            XCTAssertEqual(call.arguments.count, 1)
            let argument = call.arguments[0]
            XCTAssertEqual(argument.name, "format")
            XCTAssertEqual(name, "print")

            guard case let .stringLiteral(formatString) = argument.value.expressionType else {
                XCTAssertTrue(false)
                return
            }

            XCTAssertEqual(formatString, "the operations value is {}")
        
        } else {
            XCTAssertTrue(false)
        }
    }

    func testScopedCalls() throws {
    }
}
