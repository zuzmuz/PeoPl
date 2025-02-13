import XCTest
@testable import PeoplCore

final class ExpressionTypeCheckingTests: XCTestCase {
    func testSimpleSucceed() throws {
        let source = """
            func main() => Bool
                3 * 2 -1 /6 |>
                |value| value > 2 |>
                |true| "bigger than 2",
                |_| "larger" |>
                |text| text = "bigger than 2"
            """

        let module = try Module(source: source, path: "main")

        guard case let .functionDefinition(mainFunction) = module.statements.first else {
            XCTAssertTrue(false)
            return
        }
        
        do {
            let inferredType = try mainFunction.body.checkType(
                with: .nothing(),
                localScope: LocalScope(
                    fields: [:]
                ),
                context: TypeCheckerContext(
                    functions: [:],
                    functionsIdentifiers: [:],
                    functionsInputTypeIdentifiers: [:]
                )
            )
            XCTAssertEqual(inferredType, Builtins.bool)
        } catch {
            XCTAssertTrue(false)
        }
    }

    func testSimpleFail1() throws {
        let source = """
            func main() => Bool
                3 * 2 -1 /6 |>
                |value| value > 2 |>
                |true| "bigger than 2",
                |_| "larger" |>
                |text| text = 3
            """
        let module = try Module(source: source, path: "main")
        guard case let .functionDefinition(mainFunction) = module.statements.first else {
            XCTAssertTrue(false)
            return
        }

        do throws(ExpressionSemanticError) {
            let _ = try mainFunction.body.checkType(
                with: .nothing(),
                localScope: LocalScope(
                    fields: [:]
                ),
                context: TypeCheckerContext(
                    functions: [:],
                    functionsIdentifiers: [:],
                    functionsInputTypeIdentifiers: [:]
                )
            )
            XCTAssertTrue(false)
        } catch {
            guard case let .invalidOperation(expression, leftType, rightType) = error,
                case let .equal(leftExpression, rightExpression) = expression.expressionType,
                case let .field(left) = leftExpression.expressionType,
                case let .intLiteral(right) = rightExpression.expressionType
            else {
                XCTAssertTrue(false)
                return
            }

            XCTAssertEqual(leftType, Builtins.string)
            XCTAssertEqual(rightType, Builtins.i32)
            
            XCTAssertEqual(left, "text")
            XCTAssertEqual(right, 3)
        }
    }
}
