import XCTest

@testable import PeoplCore

final class ExpressionTests: XCTestCase {

    func testNothing() throws {
        let source = """
                func main() => Nothing
                    Nothing..
            """
        let module = try Module(source: source, path: "main")

        XCTAssertEqual(module.statements.count, 1)
        let statement = module.statements[0]
        guard case let .functionDefinition(functionDefinition) = statement else {
            XCTAssertTrue(false)
            return
        }

        let body = functionDefinition.body

        guard case .nothing = body.expressionType else {
            XCTAssertTrue(false)
            return
        }
    }

    func testNever() throws {
        let source = """
                func main() => Never
                    Never..
            """
        let module = try Module(source: source, path: "main")

        XCTAssertEqual(module.statements.count, 1)
        let statement = module.statements[0]
        guard case let .functionDefinition(functionDefinition) = statement else {
            XCTAssertTrue(false)
            return
        }

        let body = functionDefinition.body

        guard case .never = body.expressionType else {
            XCTAssertTrue(false)
            return
        }
    }

    func testArithmetics() throws {
        let source = """
                func main() => I32
                    5-2+3*4-6*5/2+1+10%3..
            """
        let module = try Module(source: source, path: "main")

        XCTAssertEqual(module.statements.count, 1)
        let statement = module.statements[0]
        guard case let .functionDefinition(functionDefinition) = statement else {
            XCTAssertTrue(false)
            return
        }

        let body = functionDefinition.body

        guard case let .plus(left, right) = body.expressionType else {
            XCTAssertTrue(false)
            return
        }

        guard case let .mod(left1, right) = right.expressionType else {
            XCTAssertTrue(false)
            return
        }

        if case let .intLiteral(valueRight) = right.expressionType,
            case let .intLiteral(valueLeft) = left1.expressionType
        {
            XCTAssertEqual(valueRight, 3)
            XCTAssertEqual(valueLeft, 10)
        } else {
            XCTAssertTrue(false)
            return
        }

        guard case let .plus(left, right) = left.expressionType else {
            XCTAssertTrue(false)
            return
        }

        if case let .intLiteral(value) = right.expressionType,
            case let .minus(left, right) = left.expressionType
        {
            XCTAssertEqual(value, 1)

            guard case let .by(left1, right) = right.expressionType else {
                XCTAssertTrue(false)
                return
            }

            if case let .intLiteral(value) = right.expressionType,
                case let .times(left, right) = left1.expressionType
            {
                XCTAssertEqual(value, 2)

                if case let .intLiteral(valueLeft) = left.expressionType,
                    case let .intLiteral(valueRight) = right.expressionType
                {
                    XCTAssertEqual(valueLeft, 6)
                    XCTAssertEqual(valueRight, 5)
                } else {
                    XCTAssertTrue(false)
                }
            }

            guard case let .plus(left, right) = left.expressionType else {
                XCTAssertTrue(false)
                return
            }
            guard case let .times(left1, right) = right.expressionType else {
                XCTAssertTrue(false)
                return
            }

            if case let .intLiteral(leftValue) = left1.expressionType,
                case let .intLiteral(rightValue) = right.expressionType
            {
                XCTAssertEqual(leftValue, 3)
                XCTAssertEqual(rightValue, 4)
            } else {
                XCTAssertTrue(false)
            }

            guard case let .minus(left, right) = left.expressionType else {
                XCTAssertTrue(false)
                return
            }
            if case let .intLiteral(leftValue) = left.expressionType,
                case let .intLiteral(rightValue) = right.expressionType
            {
                XCTAssertEqual(leftValue, 5)
                XCTAssertEqual(rightValue, 2)
            } else {
                XCTAssertTrue(false)
            }
        } else {
            XCTAssertTrue(false)
        }
    }

    func testComparisonEqual() throws {
        let source = """
                func main() => I32
                    -5+10+3 = 2*3 + 10/2..
            """
        let module = try Module(source: source, path: "main")

        XCTAssertEqual(module.statements.count, 1)
        let statement = module.statements[0]
        guard case let .functionDefinition(functionDefinition) = statement else {
            XCTAssertTrue(false)
            return
        }

        let body = functionDefinition.body

        guard case let .equal(left, right) = body.expressionType else {
            XCTAssertTrue(false)
            return
        }

        guard case let .plus(left1, right) = right.expressionType else {
            XCTAssertTrue(false)
            return
        }

        if case let .times(left1, right1) = left1.expressionType,
            case let .by(left2, right2) = right.expressionType,
            case let .intLiteral(left1Value) = left1.expressionType,
            case let .intLiteral(right1Value) = right1.expressionType,
            case let .intLiteral(left2Value) = left2.expressionType,
            case let .intLiteral(right2Value) = right2.expressionType
        {
            XCTAssertEqual(left1Value, 2)
            XCTAssertEqual(right1Value, 3)
            XCTAssertEqual(left2Value, 10)
            XCTAssertEqual(right2Value, 2)
        } else {
            XCTAssertTrue(false)
            return
        }

        guard case let .plus(left, right) = left.expressionType else {
            XCTAssertTrue(false)
            return
        }

        if case let .intLiteral(rightestValue) = right.expressionType, 
            case let .plus(left, right) = left.expressionType,
            case let .intLiteral(rightValue) = right.expressionType,
            case let .negative(unary) = left.expressionType,
            case let .intLiteral(leftValue) = unary.expressionType
        {
            XCTAssertEqual(leftValue, 5)
            XCTAssertEqual(rightValue, 10)
            XCTAssertEqual(rightestValue, 3)
        } else {
            XCTAssertTrue(false)
        }
    }
}
