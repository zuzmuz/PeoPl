import XCTest
@testable import PeoplCore

final class FunctionSignatureTests: XCTestCase {
    func testHashableSignatures() throws {
        let functionDefinition = FunctionDefinition(
            inputType: .nominal(
                .init(
                    chain: [
                        .init(
                            typeName: "I32",
                            typeArguments: [],
                            location: .nowhere)
                    ],
                    location: .nowhere)),
            scope: nil,
            name: "my_function",
            params: [],
            outputType: .nominal(
                .init(
                    chain: [
                        .init(
                            typeName: "String",
                            typeArguments: [],
                            location: .nowhere)
                    ],
                    location: .nowhere)),
            body: .init(
                location: .nowhere,
                expressionType: .nothing),
            location: .nowhere)


        let source = """
            func (I32) my_function() => String
                |_| "return string"
            """
        let module = try Module(source: source, path: "main")

        guard let myFunction = module.statements.first, 
            case let .functionDefinition(myFunction) = myFunction else {
            XCTAssertTrue(false)
            return
        }

        XCTAssertEqual(functionDefinition, myFunction)
    }
}
