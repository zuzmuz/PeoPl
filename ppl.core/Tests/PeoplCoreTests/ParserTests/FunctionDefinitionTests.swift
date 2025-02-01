import XCTest

@testable import PeoplCore

final class SignatureTests: XCTestCase {

    func testSimple() throws {
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

        XCTAssertEqual(functionDefinition.name, "main")
        XCTAssertEqual(functionDefinition.inputType, TypeIdentifier.nothing)
        XCTAssertTrue(functionDefinition.scope == nil)
        XCTAssertEqual(functionDefinition.params.count, 0)
        XCTAssertEqual(functionDefinition.outputType, TypeIdentifier.nothing)
    }

    func testScoped1() throws {
        let source = """
            func Scope.main() => Nothing
                Nothing..
        """
        let module = try Module(source: source, path: "main")
        XCTAssertEqual(module.statements.count, 1)
        let statement = module.statements[0]
        guard case let .functionDefinition(functionDefinition) = statement else {
            XCTAssertTrue(false)
            return
        }

        XCTAssertEqual(functionDefinition.name, "main")
        XCTAssertEqual(functionDefinition.inputType, TypeIdentifier.nothing)
        XCTAssertNotEqual(functionDefinition.scope, nil)
        XCTAssertEqual(functionDefinition.scope!.chain.count, 1)
        XCTAssertEqual(functionDefinition.scope!.chain[0].typeName, "Scope")
        XCTAssertEqual(functionDefinition.scope!.chain[0].typeArguments.count, 0)
        XCTAssertEqual(functionDefinition.params.count, 0)
        XCTAssertEqual(functionDefinition.outputType, TypeIdentifier.nothing)
    }

    func testScoped2() throws {
        let source = """
            func Scope1::Scope2.main() => Nothing
                Nothing..
        """
        let module = try Module(source: source, path: "main")
        XCTAssertEqual(module.statements.count, 1)
        let statement = module.statements[0]
        guard case let .functionDefinition(functionDefinition) = statement else {
            XCTAssertTrue(false)
            return
        }

        XCTAssertEqual(functionDefinition.name, "main")
        XCTAssertEqual(functionDefinition.inputType, TypeIdentifier.nothing)
        XCTAssertNotEqual(functionDefinition.scope, nil)
        XCTAssertEqual(functionDefinition.scope!.chain.count, 2)
        XCTAssertEqual(functionDefinition.scope!.chain[0].typeName, "Scope1")
        XCTAssertEqual(functionDefinition.scope!.chain[0].typeArguments.count, 0)
        XCTAssertEqual(functionDefinition.scope!.chain[1].typeName, "Scope2")
        XCTAssertEqual(functionDefinition.scope!.chain[1].typeArguments.count, 0)
        XCTAssertEqual(functionDefinition.params.count, 0)
        XCTAssertEqual(functionDefinition.outputType, TypeIdentifier.nothing)
    }

    func testScoped10() throws {
        let source = """
            func Scope1::Scope2::Scope3::Scope4::Scope5::Scope6::Scope7::Scope8::Scope9::Scope10.main() => Nothing
                Nothing..
        """
        let module = try Module(source: source, path: "main")
        XCTAssertEqual(module.statements.count, 1)
        let statement = module.statements[0]
        guard case let .functionDefinition(functionDefinition) = statement else {
            XCTAssertTrue(false)
            return
        }

        XCTAssertEqual(functionDefinition.name, "main")
        XCTAssertEqual(functionDefinition.inputType, TypeIdentifier.nothing)
        XCTAssertNotEqual(functionDefinition.scope, nil)
        XCTAssertEqual(functionDefinition.scope!.chain.count, 10)
        XCTAssertEqual(functionDefinition.scope!.chain[0].typeName, "Scope1")
        XCTAssertEqual(functionDefinition.scope!.chain[0].typeArguments.count, 0)
        XCTAssertEqual(functionDefinition.scope!.chain[1].typeName, "Scope2")
        XCTAssertEqual(functionDefinition.scope!.chain[1].typeArguments.count, 0)
        XCTAssertEqual(functionDefinition.scope!.chain[2].typeName, "Scope3")
        XCTAssertEqual(functionDefinition.scope!.chain[2].typeArguments.count, 0)
        XCTAssertEqual(functionDefinition.scope!.chain[3].typeName, "Scope4")
        XCTAssertEqual(functionDefinition.scope!.chain[3].typeArguments.count, 0)
        XCTAssertEqual(functionDefinition.scope!.chain[4].typeName, "Scope5")
        XCTAssertEqual(functionDefinition.scope!.chain[4].typeArguments.count, 0)
        XCTAssertEqual(functionDefinition.scope!.chain[5].typeName, "Scope6")
        XCTAssertEqual(functionDefinition.scope!.chain[5].typeArguments.count, 0)
        XCTAssertEqual(functionDefinition.scope!.chain[6].typeName, "Scope7")
        XCTAssertEqual(functionDefinition.scope!.chain[6].typeArguments.count, 0)
        XCTAssertEqual(functionDefinition.scope!.chain[7].typeName, "Scope8")
        XCTAssertEqual(functionDefinition.scope!.chain[7].typeArguments.count, 0)
        XCTAssertEqual(functionDefinition.scope!.chain[8].typeName, "Scope9")
        XCTAssertEqual(functionDefinition.scope!.chain[8].typeArguments.count, 0)
        XCTAssertEqual(functionDefinition.scope!.chain[9].typeName, "Scope10")
        XCTAssertEqual(functionDefinition.scope!.chain[9].typeArguments.count, 0)
        XCTAssertEqual(functionDefinition.params.count, 0)
        XCTAssertEqual(functionDefinition.outputType, TypeIdentifier.nothing)
    }

    func testInput() throws {
        let source = """
            func (Input) Scope.main() => Nothing
                Nothing..
        """
        let module = try Module(source: source, path: "main")
        XCTAssertEqual(module.statements.count, 1)
        let statement = module.statements[0]
        guard case let .functionDefinition(functionDefinition) = statement else {
            XCTAssertTrue(false)
            return
        }

        XCTAssertEqual(functionDefinition.name, "main")
        guard case let .nominal(inputType) = functionDefinition.inputType else {
            XCTAssertTrue(false)
            return
        }
        XCTAssertEqual(inputType.chain.count, 1)
        XCTAssertEqual(inputType.chain[0].typeName, "Input")
        XCTAssertEqual(inputType.chain[0].typeArguments.count, 0)
        XCTAssertNotEqual(functionDefinition.scope, nil)
        XCTAssertEqual(functionDefinition.scope!.chain.count, 1)
        XCTAssertEqual(functionDefinition.scope!.chain[0].typeName, "Scope")
        XCTAssertEqual(functionDefinition.scope!.chain[0].typeArguments.count, 0)
        XCTAssertEqual(functionDefinition.params.count, 0)
        XCTAssertEqual(functionDefinition.outputType, TypeIdentifier.nothing)
    }

}
