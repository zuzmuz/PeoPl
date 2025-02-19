import XCTest
@testable import PeoplCore

final class PipeAndCallsExpressionTests: XCTestCase {
    func testHelloWorld() throws {
        let source = """
                func main() => Nothing
                    "Hello World" |>
                    print()
            """
        let module = try Module(source: source, path: "main")

        XCTAssertEqual(module.statements.count, 1)
        let statement = module.statements[0]
        guard case let .functionDefinition(functionDefinition) = statement else {
            XCTAssertTrue(false)
            return
        }

        let body = functionDefinition.body

        if case let .piped(left, right) = body?.expressionType,
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
                (1 + 2) * 3 |>
                print(format: "the operations value is {}")
                
        """
        let module = try Module(source: source, path: "main")

        XCTAssertEqual(module.statements.count, 1)
        let statement = module.statements[0]
        guard case let .functionDefinition(functionDefinition) = statement else {
            XCTAssertTrue(false)
            return
        }

        let body = functionDefinition.body

        if case let .piped(left, right) = body?.expressionType,
            case let .call(call) = right.expressionType,
            case let .binary(.times, left, right) = left.expressionType,
            case let .intLiteral(value3) = right.expressionType,
            case let .binary(.plus, left, right) = left.expressionType,
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
        let source = """
            func main() => Nothing
                A::B.some_function(a: 1, b: 3) |>
                C.another(c: true) |>
                D::E::F.final(d: "one", e: "two", f: "three")
        """
        let module = try Module(source: source, path: "main")

        XCTAssertEqual(module.statements.count, 1)
        let statement = module.statements[0]
        guard case let .functionDefinition(functionDefinition) = statement else {
            XCTAssertTrue(false)
            return
        }

        let body = functionDefinition.body

        if case let .piped(left, right) = body?.expressionType,
            case let .call(call3) = right.expressionType,
            case let .piped(left, right) = left.expressionType,
            case let .call(call1) = left.expressionType,
            case let .call(call2) = right.expressionType,
            case let .simple(command1) = call1.command,
            case let .simple(command2) = call2.command,
            case let .simple(command3) = call3.command,
            case let .access(access1) = command1.expressionType,
            case let .access(access2) = command2.expressionType,
            case let .access(access3) = command3.expressionType,
            case let .type(scope1) = access1.accessed,
            case let .type(scope2) = access2.accessed,
            case let .type(scope3) = access3.accessed
        {
            XCTAssertEqual(call1.arguments.count, 2)
            XCTAssertEqual(call1.arguments[0].name, "a")
            XCTAssertEqual(call1.arguments[1].name, "b")

            if case let .intLiteral(value1) = call1.arguments[0].value.expressionType,
                case let .intLiteral(value2) = call1.arguments[1].value.expressionType
            {
                XCTAssertEqual(value1, 1)
                XCTAssertEqual(value2, 3)
            } else {
                XCTAssertTrue(false)
            }

            XCTAssertEqual(call2.arguments.count, 1)
            XCTAssertEqual(call2.arguments[0].name, "c")

            if case let .boolLiteral(value1) = call2.arguments[0].value.expressionType
            {
                XCTAssertEqual(value1, true)
            } else {
                XCTAssertTrue(false)
            }


            XCTAssertEqual(call3.arguments.count, 3)
            XCTAssertEqual(call3.arguments[0].name, "d")
            XCTAssertEqual(call3.arguments[1].name, "e")
            XCTAssertEqual(call3.arguments[2].name, "f")

            if case let .stringLiteral(value1) = call3.arguments[0].value.expressionType,
                case let .stringLiteral(value2) = call3.arguments[1].value.expressionType,
                case let .stringLiteral(value3) = call3.arguments[2].value.expressionType
            {
                XCTAssertEqual(value1, "one")
                XCTAssertEqual(value2, "two")
                XCTAssertEqual(value3, "three")
            } else {
                XCTAssertTrue(false)
            }

            XCTAssertEqual(access1.field, "some_function")
            XCTAssertEqual(access2.field, "another")
            XCTAssertEqual(access3.field, "final")
            
            XCTAssertEqual(scope1.chain.count, 2)
            XCTAssertEqual(scope1.chain[0].typeName, "A")
            XCTAssertEqual(scope1.chain[1].typeName, "B")

            XCTAssertEqual(scope2.chain.count, 1)
            XCTAssertEqual(scope2.chain[0].typeName, "C")

            XCTAssertEqual(scope3.chain.count, 3)
            XCTAssertEqual(scope3.chain[0].typeName, "D")
            XCTAssertEqual(scope3.chain[1].typeName, "E")
            XCTAssertEqual(scope3.chain[2].typeName, "F")
        } else {
            XCTAssertTrue(false)
        }
    }
}
