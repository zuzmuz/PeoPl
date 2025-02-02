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

    func testParenthisizedUnaries() throws {
        let source = """
                func main() => I32
                    not((+4) * (-5) / (-6) > (-3) % (-2))..
            """
        let module = try Module(source: source, path: "main")

        XCTAssertEqual(module.statements.count, 1)
        let statement = module.statements[0]
        guard case let .functionDefinition(functionDefinition) = statement else {
            XCTAssertTrue(false)
            return
        }

        let body = functionDefinition.body

        guard case let .not(unary) = body.expressionType else {
            XCTAssertTrue(false)
            return
        }

        guard case let .greaterThan(left, right) = unary.expressionType else {
            XCTAssertTrue(false)
            return
        }

        if case let .by(left, right) = left.expressionType,
            case let .negative(value3) = right.expressionType,
            case let .times(left, right) = left.expressionType,
            case let .positive(value1) = left.expressionType,
            case let .negative(value2) = right.expressionType,
            case let .intLiteral(value1) = value1.expressionType,
            case let .intLiteral(value2) = value2.expressionType,
            case let .intLiteral(value3) = value3.expressionType 
        {
            XCTAssertEqual(value1, 4)
            XCTAssertEqual(value2, 5)
            XCTAssertEqual(value3, 6)
        } else {
            XCTAssertTrue(false)
        }

        if case let .mod(left, right) = right.expressionType,
            case let .negative(value2) = right.expressionType,
            case let .negative(value1) = left.expressionType,
            case let .intLiteral(value1) = value1.expressionType,
            case let .intLiteral(value2) = value2.expressionType
        {
            XCTAssertEqual(value1, 3)
            XCTAssertEqual(value2, 2)
        } else {
            XCTAssertTrue(false)
        }
    }

    func testLogicals() throws {
        let source = """
                func main() => I32
                    2 > 0 and 10 < 11 or 5 >= 3 and 6 <= 4 or 1 != 3
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

        guard case let .or(left, right) = body.expressionType else {
            XCTAssertTrue(false)
            return
        }

        if case let .different(left1, right1) = right.expressionType,
            case let .or(left, right) = left.expressionType
        {
            if case let .intLiteral(valueLeft) = left1.expressionType,
                case let .intLiteral(valueRight) = right1.expressionType
            {
                XCTAssertEqual(valueLeft, 1)
                XCTAssertEqual(valueRight, 3)
            } else {
                XCTAssertTrue(false)
                return
            }

            if case let .and(left1, right1) = left.expressionType,
                case let .and(left2, right2) = right.expressionType
            {
                if case let .greaterThan(left11, right11) = left1.expressionType,
                    case let .lessThan(left21, right21) = right1.expressionType,
                    case let .intLiteral(left11) = left11.expressionType,
                    case let .intLiteral(right11) = right11.expressionType,
                    case let .intLiteral(left21) = left21.expressionType,
                    case let .intLiteral(right21) = right21.expressionType
                {
                    XCTAssertEqual(left11, 2)
                    XCTAssertEqual(right11, 0)
                    XCTAssertEqual(left21, 10)
                    XCTAssertEqual(right21, 11)
                } else {
                    XCTAssertTrue(false)
                }

                if case let .greaterThanEqual(left11, right11) = left2.expressionType,
                    case let .lessThanEqual(left21, right21) = right2.expressionType,
                    case let .intLiteral(left11) = left11.expressionType,
                    case let .intLiteral(right11) = right11.expressionType,
                    case let .intLiteral(left21) = left21.expressionType,
                    case let .intLiteral(right21) = right21.expressionType
                {
                    XCTAssertEqual(left11, 5)
                    XCTAssertEqual(right11, 3)
                    XCTAssertEqual(left21, 6)
                    XCTAssertEqual(right21, 4)
                } else {
                    XCTAssertTrue(false)
                }

            } else {
                XCTAssertTrue(false)
            }
        } else {
            XCTAssertTrue(false)
        }
    }

    func testFloatLiterals() throws {
        let source = """
                func main() => I32
                    not(
                    1.1 * 3.1
                    = -3.2 / 4.2
                    )
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

        guard case let .not(unary) = body.expressionType else {
            XCTAssertTrue(false)
            return
        }
        
        guard case let .equal(left, right) = unary.expressionType else {
            XCTAssertTrue(false)
            return
        }

        if case let .times(left, right) = left.expressionType,
            case let .floatLiteral(left) = left.expressionType,
            case let .floatLiteral(right) = right.expressionType
        {
            XCTAssertEqual(left, 1.1)
            XCTAssertEqual(right, 3.1)
        } else {
            XCTAssertTrue(false)
            return
        }

        if case let .by(left, right) = right.expressionType,
            case let .negative(left) = left.expressionType,
            case let .floatLiteral(left) = left.expressionType,
            case let .floatLiteral(right) = right.expressionType
        {
            XCTAssertEqual(left, 3.2)
            XCTAssertEqual(right, 4.2)
        } else {
            XCTAssertTrue(false)
            return
        }
    }

    func testSimplePrecedence() throws {
        let source = """
                func main() => I32
                    ((2 + 3) * 4 or 5 / ( 6 - 7))
                    and
                    (8 or 9)
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
        
        guard case let .and(left, right) = body.expressionType else {
            XCTAssertTrue(false)
            return
        }

        if case let .or(left, right) = right.expressionType,
            case let .intLiteral(left) = left.expressionType,
            case let .intLiteral(right) = right.expressionType
        {
            XCTAssertEqual(left, 8)
            XCTAssertEqual(right, 9)
        } else {
            XCTAssertTrue(false)
        }

        if case let .or(left, right) = left.expressionType {
            if case let .times(left, right) = left.expressionType,
                case let .intLiteral(value3) = right.expressionType,
                case let .plus(left, right) = left.expressionType,
                case let .intLiteral(value1) = left.expressionType,
                case let .intLiteral(value2) = right.expressionType
            {
                XCTAssertEqual(value1, 2)
                XCTAssertEqual(value2, 3)
                XCTAssertEqual(value3, 4)
            } else {
                XCTAssertTrue(false)
            }

            if case let .by(left, right) = right.expressionType,
                case let .intLiteral(value1) = left.expressionType,
                case let .minus(left, right) = right.expressionType,
                case let .intLiteral(value2) = left.expressionType,
                case let .intLiteral(value3) = right.expressionType
            {
                XCTAssertEqual(value1, 5)
                XCTAssertEqual(value2, 6)
                XCTAssertEqual(value3, 7)
            } else {
                XCTAssertTrue(false)
            }
        }
    }
}
