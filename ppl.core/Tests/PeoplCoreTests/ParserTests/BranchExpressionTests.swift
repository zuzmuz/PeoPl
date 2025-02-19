import XCTest
@testable import PeoplCore

final class BranchExpressionTests: XCTestCase {
    func testIsEven() throws {
        let source = """
                func main() => String
                    3 |>
                    |i: i % 2 = 0| "is even",
                    |_| "is odd"
            """
        let module = try Module(source: source, path: "main")

        XCTAssertEqual(module.statements.count, 1)
        let statement = module.statements[0]
        guard case let .functionDefinition(functionDefinition) = statement else {
            XCTAssertTrue(false)
            return
        }

        let body = functionDefinition.body

        guard case let .piped(left, right) = body?.expressionType else {
            XCTAssertTrue(false)
            return
        }

        if case let .intLiteral(value) = left.expressionType {
            XCTAssertEqual(value, 3)
        } else {
            XCTAssertTrue(false)
        }

        if case let .branched(branched) = right.expressionType {
            XCTAssertEqual(branched.branches.count, 2)
            XCTAssertNil(branched.lastBranch)
            
            let branch1 = branched.branches[0]
            XCTAssertEqual(branch1.captureGroup.count, 1)
            if case let .argument(argument) = branch1.captureGroup[0],
                case let .binary(.equal, left, right) = argument.value.expressionType,
                case let .intLiteral(value3) = right.expressionType,
                case let .binary(.modulo, left, right) = left.expressionType,
                case let .field(value1) = left.expressionType,
                case let .intLiteral(value2) = right.expressionType
            {
                XCTAssertEqual(argument.name, "i")
                XCTAssertEqual(value1, "i")
                XCTAssertEqual(value2, 2)
                XCTAssertEqual(value3, 0)
            } else {
                XCTAssertTrue(false)
            }

            if case let .simple(expression) = branch1.body,
                case let .stringLiteral(body) = expression.expressionType { 
                XCTAssertEqual(body, "is even")                              
            } else {                                                         
                XCTAssertTrue(false)                                         
            }                                                                
                                                                             
            let branch2 = branched.branches[1]
            XCTAssertEqual(branch2.captureGroup.count, 1)
            if case let .simple(expression) = branch2.captureGroup[0],
                case let .field(value) = expression.expressionType
            {
                XCTAssertEqual(value, "_")
            } else {
                XCTAssertTrue(false)
            }

            if case let .simple(expression) = branch2.body,
                case let .stringLiteral(body) = expression.expressionType { 
                XCTAssertEqual(body, "is odd")                              
            } else {                                                         
                XCTAssertTrue(false)                                         
            }                                                                

        } else {
            XCTAssertTrue(false)
        }
    }

    func testLooping() throws {
        let source = """
                func print(from: I32, to: I32) => Nothing
                    from |>
                    |i < to| (
                        |i % 2 = 0| (i |> print(format: "{} is even")),
                        |i| (i |> print(format: "{} is odd"))
                        |> +1
                    )^,
                    Nothing
            """
        let module = try Module(source: source, path: "main")

        XCTAssertEqual(module.statements.count, 1)
        let statement = module.statements[0]
        guard case let .functionDefinition(functionDefinition) = statement else {
            XCTAssertTrue(false)
            return
        }

        let body = functionDefinition.body

        guard case let .piped(left, right) = body?.expressionType else {
            XCTAssertTrue(false)
            return
        }

        if case .field("from") = left.expressionType {
        } else {
            XCTAssertTrue(false)
        }

        guard case let .branched(branched) = right.expressionType else {
            XCTAssertTrue(false)
            return
        }

        XCTAssertEqual(branched.branches.count, 1)

        XCTAssertNotNil(branched.lastBranch)

        if case .nothing = branched.lastBranch?.expressionType {
        } else {
            XCTAssertTrue(false)
        }

        let branch = branched.branches[0]
        XCTAssertEqual(branch.captureGroup.count, 1)

        if case let .simple(expression) = branch.captureGroup[0],
            case let .binary(.lessThan, left, right) = expression.expressionType,
            case let .field(value1) = left.expressionType,
            case let .field(value2) = right.expressionType
        {
            XCTAssertEqual(value1, "i")
            XCTAssertEqual(value2, "to")
        } else {
            XCTAssertTrue(false)
        }

        guard case let .looped(expression) = branch.body else {
            XCTAssertTrue(false)
            return
        }

        if case let .piped(left, right) = expression.expressionType,
            case let .unary(.plus, unary) = right.expressionType,
            case let .intLiteral(value) = unary.expressionType,
            case let .branched(branched) = left.expressionType
        {
            XCTAssertEqual(value, 1)
            XCTAssertEqual(branched.branches.count, 2)

            // TODO: run test on capture groups and bodies of these

        } else {
            XCTAssertTrue(false)
        }
    }
}
