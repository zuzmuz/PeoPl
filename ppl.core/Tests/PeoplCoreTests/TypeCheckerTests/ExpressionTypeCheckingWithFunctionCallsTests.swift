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
        let builtins = Builtins.getBuiltinContext()

        let checker = module.resolveFunctionDefinitions(typesDefinitions: [:], builtins: builtins)

        XCTAssertEqual(checker.errors.count, 0)
        XCTAssertEqual(checker.functions.count, 2)

        guard let mainFunction = checker.functionsIdentifiers[.init(scope: nil, name: "main")] else {
            XCTAssertTrue(false)
            return
        }
        
        do {
            let context = SemanticContext(
                types: [:],
                functions: checker.functions,
                functionsIdentifiers: checker.functionsIdentifiers,
                functionsInputTypeIdentifiers: checker.functionsInputTypeIdentifiers,
                operators: [:]
            )
            let inferredType = try mainFunction.first!.body!.checkType(
                with: .nothing(),
                localScope: LocalScope(
                    fields: [:]
                ),
                context: context
            )
            XCTAssertEqual(inferredType.typeIdentifier, Builtins.bool)
        } catch {
            XCTAssertTrue(false)
        }
    }
}
