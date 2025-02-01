import XCTest

@testable import PeoplCore

final class SignatureTests: XCTestCase {

    func testSimple() throws {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted
        let source = """
            func main() => Nothing
                Nothing..
        """
        let module = try Module(source: source, path: "main")
        XCTAssertEqual(module.statements.count, 1)
        let statement = module.statements[0]
        var functionDefinition: FunctionDefinition!
        switch statement {
        case let .functionDefinition(definition):
            functionDefinition = definition
        default:
            XCTAssertTrue(false)
        }

        XCTAssertEqual(functionDefinition.name, "main")
        XCTAssertEqual(functionDefinition.outputType, TypeIdentifier.nothing)
        XCTAssertEqual(functionDefinition.params.count, 0)
        XCTAssertTrue(functionDefinition.scope == nil)
        // XCTAssertEqual(functionDefinition.location, NodeLocation(line: 1, column: 1))
    }
}
