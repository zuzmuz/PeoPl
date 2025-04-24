import XCTest
@testable import PeoplCore

final class BranchExpressionTests: XCTestCase {
    func testIsEven() throws {
        let source = """
                func main() => String
                    3 |>
                    |$i: i % 2 = 0| "is even",
                    |_| "is odd"
            """
        let module = try Syntax.Module(source: source, path: "main")

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

        if case let .literal(.intLiteral(value)) = left.expressionType {
            XCTAssertEqual(value, 3)
        } else {
            XCTAssertTrue(false)
        }

        if case let .branched(branched) = right.expressionType {
            XCTAssertEqual(branched.branches.count, 2)
            
            let branch1 = branched.branches[0]
            if case let .binding(binding) = branch1.matchExpression,
                case let .binary(.equal, left, right) = branch1.guardExpression?.expressionType,
                case let .literal(.intLiteral(value3)) = right.expressionType,
                case let .binary(.modulo, left, right) = left.expressionType,
                case let .field(value1) = left.expressionType,
                case let .literal(.intLiteral(value2)) = right.expressionType
            {
                XCTAssertEqual(binding, "i")
                XCTAssertEqual(value1.identifier, "i")
                XCTAssertNil(value1.scope)
                XCTAssertEqual(value2, 2)
                XCTAssertEqual(value3, 0)
            } else {
                XCTAssertTrue(false)
            }

            if case let .simple(expression) = branch1.body,
                case let .literal(.stringLiteral(body)) = expression.expressionType { 
                XCTAssertEqual(body, "is even")                              
            } else {                                                         
                XCTAssertTrue(false)                                         
            }                                                                
                                                                             
            let branch2 = branched.branches[1]
            if case let .field(value) = branch2.matchExpression {
                XCTAssertEqual(value.identifier, "_")
            } else {
                XCTAssertTrue(false)
            }

            if case let .simple(expression) = branch2.body,
                case let .literal(.stringLiteral(body)) = expression.expressionType { 
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
                    |$i: i < to| (
                        |_: i % 2 = 0| (i |> print(format: "{} is even")),
                        |_| (i |> print(format: "{} is odd"))
                        |> +1
                    )^,
                    |_| Nothing
            """
        let module = try Syntax.Module(source: source, path: "main")

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

        if case let .field(field) = left.expressionType {
            XCTAssertEqual(field.identifier, "from")
        } else {
            XCTAssertTrue(false)
        }

        guard case let .branched(branched) = right.expressionType else {
            XCTAssertTrue(false)
            return
        }

        XCTAssertEqual(branched.branches.count, 1)



        let branch = branched.branches[0]

        if case let .binary(.lessThan, left, right) = branch.guardExpression?.expressionType,
            case let .field(value1) = left.expressionType,
            case let .field(value2) = right.expressionType
        {
            XCTAssertEqual(value1.identifier, "i")
            XCTAssertEqual(value2.identifier, "to")
        } else {
            XCTAssertTrue(false)
        }

        guard case let .looped(expression) = branch.body else {
            XCTAssertTrue(false)
            return
        }

        if case let .piped(left, right) = expression.expressionType,
            case let .unary(.plus, unary) = right.expressionType,
            case let .literal(.intLiteral(value)) = unary.expressionType,
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
