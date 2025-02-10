import XCTest

@testable import PeoplCore

final class FunctionSignatureTests: XCTestCase {
    func testHashableSignatureSimple() throws {
        let functionDefinition = FunctionDefinition(
            inputType: .simpleNominalType(name: "I32"),
            scope: nil,
            name: "my_function",
            params: [],
            outputType: .simpleNominalType(name: "String"),
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
            case let .functionDefinition(myFunction) = myFunction
        else {
            XCTAssertTrue(false)
            return
        }

        XCTAssertEqual(functionDefinition, myFunction)
    }

    func testHashableSignatureAdvanced() throws {
        let functionDefintion = FunctionDefinition(
            inputType: .simpleTuple(names: ["Type1", "Type2"]),
            scope: .init(chain: [.init(typeName: "Scope", typeArguments: [], location: .nowhere)], location: .nowhere),
            name: "my_function",
            params: [
                .init(
                    name: "first",
                    type: .simpleNamedTuple(names: [("a", "Arg"), ("b", "Brg")]),
                    location: .nowhere),
                .init(
                    name: "second",
                    type: .simpleLambda(inputs: ["T", "Y"], output: "O"),
                    location: .nowhere)
            ],
            outputType: .nothing(location: .nowhere),
            body: .init(
                location: .nowhere,
                expressionType: .nothing),
            location: .nowhere)
    }
}
