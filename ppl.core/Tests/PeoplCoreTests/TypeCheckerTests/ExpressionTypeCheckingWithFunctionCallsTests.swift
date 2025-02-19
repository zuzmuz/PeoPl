import XCTest

@testable import PeoplCore

final class ExpressionTypeCheckingWithFunctionCallsTests: XCTestCase {
    func testSimpleCall() throws {
        let source = """
            func factorial(n: I32) => I32
                |n = 0| 1
                |_| n * factorial(n - 1)

            func main() => Bool
                factorial(n: 5) |>
                |n| n > 100
            """

        let module = try Module(source: source, path: "main")
        let builtins = Builtins.getDeclarationContext()

        let declarationsChecker = FunctionDeclarationChecker(
            context: module,
            builtins: builtins,
            typeDeclarationChecker: .init(context: module, builtins: builtins))

        XCTAssertEqual(declarationsChecker.errors.count, 0)
        XCTAssertEqual(declarationsChecker.functions.count, 82)

        guard let mainFunction = declarationsChecker.functionsIdentifiers[.init(scope: nil, name: "main")] else {
            XCTAssertTrue(false)
            return
        }
        
        do {
            let inferredType = try mainFunction.first!.body!.checkType(
                with: .empty,
                localScope: LocalScope(
                    fields: [:]
                ),
                context: TypeCheckerContext(
                    functions: declarationsChecker.functions,
                    functionsIdentifiers: declarationsChecker.functionsIdentifiers,
                    functionsInputTypeIdentifiers: declarationsChecker.functionsInputTypeIdentifiers
                )
            )
            XCTAssertEqual(inferredType.typeIdentifier, Builtins.bool)
        } catch {
            XCTAssertTrue(false)
        }
    }
}
