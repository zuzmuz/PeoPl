import XCTest

@testable import PeoplCore

// MARK: - Type System Parsing Tests
// ==================================

class TypeSystemParsingTests: XCTestCase {

    // MARK: - Function Type Tests
    // ---------------------------

    func testSimpleFunctionTypes() throws {
        let source = """
            identity: (Int) [] -> Int {
                1
            }

            constant: () -> String {
                "hello"
            }

            consumer: (String) -> Nothing {
                _
            }

            panic: () -> Never {
                never
            }
            """

        let module = try Syntax.Module(source: source, path: "functions.ppl")

        XCTAssertEqual(module.definitions.count, 4)

        guard
            case let .valueDefinition(identityDefinition) =
                module.definitions[0]
        else {
            XCTFail("Expected identity function definition")
            return
        }
        XCTAssertEqual(identityDefinition.identifier.chain, ["identity"])
        XCTAssertTrue(identityDefinition.arguments.isEmpty)

        guard
            case let .function(signature, _) =
                identityDefinition.definition.expressionType
        else {
            XCTFail("Expected function as expression type")
            return
        }
        XCTAssertNotNil(signature)
        guard case let .nominal(type) = signature?.inputType else {
            XCTFail("Expected nominal input type")
            return
        }
        XCTAssertEqual(type.identifier.chain, ["Int"])

        guard case let .nominal(type) = signature?.outputType else {
            XCTFail("Expected nominal input type")
            return
        }
        XCTAssertEqual(type.identifier.chain, ["Int"])

        XCTAssertTrue(signature!.arguments.isEmpty)

        guard
            case let .valueDefinition(identityDefinition) =
                module.definitions[1]
        else {
            XCTFail("Expected constant function definition")
            return
        }
        XCTAssertEqual(identityDefinition.identifier.chain, ["constant"])
        XCTAssertTrue(identityDefinition.arguments.isEmpty)

        guard
            case let .function(signature, _) =
                identityDefinition.definition.expressionType
        else {
            XCTFail("Expected function as expression type")
            return
        }

        XCTAssertNil(signature!.inputType)

        guard case let .nominal(type) = signature?.outputType else {
            XCTFail("Expected nominal input type")
            return
        }
        XCTAssertEqual(type.identifier.chain, ["String"])

        XCTAssertTrue(signature!.arguments.isEmpty)

        guard
            case let .valueDefinition(identityDefinition) =
                module.definitions[2]
        else {
            XCTFail("Expected consumer function definition")
            return
        }
        XCTAssertEqual(identityDefinition.identifier.chain, ["consumer"])
        XCTAssertTrue(identityDefinition.arguments.isEmpty)

        guard
            case let .function(signature, _) =
                identityDefinition.definition.expressionType
        else {
            XCTFail("Expected function as expression type")
            return
        }

        guard case let .nominal(type) = signature?.inputType else {
            XCTFail("Expected nominal input type")
            return
        }
        XCTAssertEqual(type.identifier.chain, ["String"])

        guard case .nothing = signature?.outputType else {
            XCTFail("Expected nothing output type")
            return
        }

        XCTAssertTrue(signature!.arguments.isEmpty)

        guard
            case let .valueDefinition(identityDefinition) =
                module.definitions[3]
        else {
            XCTFail("Expected panic function definition")
            return
        }
        XCTAssertEqual(identityDefinition.identifier.chain, ["panic"])
        XCTAssertTrue(identityDefinition.arguments.isEmpty)

        guard
            case let .function(signature, _) =
                identityDefinition.definition.expressionType
        else {
            XCTFail("Expected function as expression type")
            return
        }

        XCTAssertNil(signature!.inputType)

        guard case .never = signature?.outputType else {
            XCTFail("Expected never output type")
            return
        }
        XCTAssertTrue(signature!.arguments.isEmpty)
    }

    func testMultiArgumentFunctionTypes() throws {
        let source = """
            add: [x: Int, y: Int] -> Int {
                x + y
            }

            format[n: Int]: (String) [args: [String ** n]] -> String {
                _
            }
            """

        let module = try Syntax.Module(
            source: source, path: "multi_arg_functions.lang")

        XCTAssertEqual(module.definitions.count, 2)

        guard case .valueDefinition(let addDef) = module.definitions[0] else {
            XCTFail("Expected add function definition")
            return
        }
        XCTAssertEqual(addDef.identifier.chain, ["add"])
    }

    func testHigherOrderFunctionTypes() throws {
        let source = """
            map[T, U]: (List[T]) [transform: (T) -> U] -> List[U] {
                _
            }

            filter[T]: (List[T]) [predicate: (T) -> Bool] -> List[T] {
                _
            }
            """

        let module = try Syntax.Module(
            source: source, path: "higher_order.lang")

        XCTAssertEqual(module.definitions.count, 2)

    }

    // MARK: - Product Type Tests (using [])
    // -------------------------------------

    func testProductTypeDefinitions() throws {
        let source = """
            Pair: [Int, String]
            Triple: [Int, String, Bool]
            NestedProduct: [[Int, String], Bool]
            """

        let module = try Syntax.Module(source: source, path: "products")

        XCTAssertEqual(module.definitions.count, 3)

        guard case .typeDefinition(let pairDef) = module.definitions[0] else {
            XCTFail("Expected type definition")
            return
        }
        XCTAssertEqual(pairDef.identifier.chain, ["Pair"])

        guard case .product(let product) = pairDef.definition else {
            XCTFail("Expected product type")
            return
        }
        XCTAssertEqual(product.typeFields.count, 2)
    }

    func testRecordTypeDefinitions() throws {
        let source = """
            Person: [name: String, age: Int]
            Point: [x: Float, y: Float, z: Float]
            Mixed: [id: Int, data: [String, Bool], meta: [created: String]]
            """

        let module = try Syntax.Module(source: source, path: "records")

        XCTAssertEqual(module.definitions.count, 3)

        guard case .typeDefinition(let personDef) = module.definitions[0] else {
            XCTFail("Expected person type definition")
            return
        }
        XCTAssertEqual(personDef.identifier.chain, ["Person"])

        // Verify it's a product type with tagged fields
        guard case .product(let product) = personDef.definition else {
            XCTFail("Expected product type")
            return
        }
        XCTAssertEqual(product.typeFields.count, 2)
    }

    // MARK: - Sum Type Tests (using choice [])
    // ----------------------------------------

    func testSimpleSumTypes() throws {
        let source = """
            Optional[T]: choice [T, Nothing]
            """

        let module = try Syntax.Module(source: source, path: "optional")

        XCTAssertEqual(module.definitions.count, 1)

        guard case .typeDefinition(let colorDef) = module.definitions[0] else {
            XCTFail("Expected color type definition")
            return
        }
        XCTAssertEqual(colorDef.identifier.chain, ["Optional"])

        // Verify it's a sum type
        guard case .sum(let sum) = colorDef.definition else {
            XCTFail("Expected sum type")
            return
        }
        XCTAssertEqual(sum.typeFields.count, 2)
    }

    func testTaggedSumTypes() throws {
        let source = """
            Color: choice [red, green, blue]
            Result[T, E]: choice [success: T, error: E]
            """

        let module = try Syntax.Module(
            source: source, path: "tagged_unions")

        XCTAssertEqual(module.definitions.count, 2)

        guard case .typeDefinition(let resultDef) = module.definitions[1] else {
            XCTFail("Expected result type definition")
            return
        }
        XCTAssertEqual(resultDef.identifier.chain, ["Result"])
        XCTAssertEqual(resultDef.arguments.count, 2)  // Generic parameter T

        guard case .sum(let sum) = resultDef.definition else {
            XCTFail("Expected sum type")
            return
        }
        XCTAssertEqual(sum.typeFields.count, 2)
    }

    // MARK: - Complex Type Definitions
    // --------------------------------

    func testComplexMixedTypes() throws {
        let source = """
            Complex: [
                id: String,
                data: choice [
                    simple: Int,
                    nested: [value: T, meta: [created: String, modified: String]]
                ]
            ]
            """

        let module = try Syntax.Module(source: source, path: "complex.lang")

        XCTAssertEqual(module.definitions.count, 1)

        guard case .typeDefinition(let complexDef) = module.definitions[0]
        else {
            XCTFail("Expected Complex type definition")
            return
        }
        XCTAssertEqual(complexDef.identifier.chain, ["Complex"])

        guard case .product(let product) = complexDef.definition else {
            XCTFail("Expected product type for Complex")
            return
        }
        XCTAssertEqual(product.typeFields.count, 2)
    }

    // MARK: - Error Cases
    // -------------------

    func testInvalidTypeSyntax() {
        // Test that invalid syntax throws appropriate errors
        let invalidSources = [
            "invalid: () [] ->",  // Missing output type
            "bad: -> Int",  // Missing input specification
            "broken: []",  // Missing type annotation
            "type Invalid = choice []",  // Empty choice
        ]

        for source in invalidSources {
            XCTAssertThrowsError(
                try Syntax.Module(source: source, path: "invalid.lang")
            ) { error in
                print("Expected error for invalid syntax: \(error)")
            }
        }
    }

    func testInvalidIdentifierCapitalization() {
        let invalidSources = [
            "type lowercase = [Int]",  // Type identifier should be capitalized
        ]

        for source in invalidSources {
            XCTAssertThrowsError(
                try Syntax.Module(source: source, path: "invalid_caps.lang")
            ) { error in
                print("Expected error for invalid capitalization: \(error)")
            }
        }
    }

    // MARK: - Edge Cases
    // ------------------

    func testEmptyModule() throws {
        let source = ""
        let module = try Syntax.Module(source: source, path: "empty.lang")
        XCTAssertTrue(module.definitions.isEmpty)
    }

    func testComplexWhitespaceHandling() throws {
        let source = """

            Spaced   :   [  x : Int  ,  y : String  ]

            spaced : (Bool) [  x : Int  ,  y : String  ] ->   Bool {
                _
            }


            """

        let module = try Syntax.Module(source: source, path: "whitespace.lang")
        XCTAssertEqual(module.definitions.count, 2)

        guard case .typeDefinition(let typeDef) = module.definitions[0] else {
            XCTFail("Expected type definition")
            return
        }
        XCTAssertEqual(typeDef.identifier.chain, ["Spaced"])

        guard case .valueDefinition(let spacedDef) = module.definitions[1]
        else {
            XCTFail("Expected spaced definition")
            return
        }
        XCTAssertEqual(spacedDef.identifier.chain, ["spaced"])
    }
}
