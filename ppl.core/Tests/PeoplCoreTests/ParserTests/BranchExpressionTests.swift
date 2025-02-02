import XCTest
@testable import PeoplCore

final class BranchExpressionTests: XCTestCase {
    func testHelloWorld() throws {
        let source = """
                func main() => String
                    3;
                    |i % 2 = 0| "is even",
                    |_| "is odd"
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

        guard case let .piped(left, right) = body.expressionType else {
            XCTAssertTrue(false)
            return
        }

        if case let .branched(branched) = right.expressionType {
            XCTAssertEqual(branched.branches.count, 2)
            
            let branch1 = branched.branches[0]
            XCTAssertEqual(branch1.captureGroup.count, 1)
            if case let .simple(expression) = branch1.captureGroup[0],
                case let .equal(left, right) = expression.expressionType,
                case let .intLiteral(value3) = right.expressionType,
                case let .mod(left, right) = left.expressionType,
                case let .field(value1) = left.expressionType,
                case let .intLiteral(value2) = right.expressionType
            {
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
}
