import XCTest

@testable import PeoplCore

final class TypesAnalyzerTests: XCTestCase {
    func testSimpleTypes() throws {
        let source = """
            Rectangle: [
                width: F64,
                height: F64,
                x: F64,
                y: F64
            ]
            Circle: [
                x: F64,
                y: F64,
                radius: F64
            ]
            """
        let module = try Syntax.Module(source: source, path: "main")

        let result = module.semanticCheck()

        switch result {
        case .failure:
            XCTAssertTrue(false)
        case let .success(context):
            XCTAssertEqual(context.typeDefinitions.count, 2)
        }
    }

    func testInvalidTypes() throws {
        let source = """
            Rectangle: [
                width: F65,
                height: F64,
                x: F64,
                y: CDD
            ]
            Circle: [
                x: F64,
                y: F64,
                radius: F6
            ]
            """
        let module = try Syntax.Module(source: source, path: "main")

        let result = module.semanticCheck()

        // TODO: think of adding tests for locations
        let wrongTypes = Set(["F6", "F65", "CDD"])

        switch result {
        case let .failure(errorList):
            let errors = errorList.errors

            XCTAssertEqual(errors.count, 3)

            errors.forEach { error in
                switch error {
                case let .type(.typeNotInScope(type)):
                    XCTAssertTrue(
                        wrongTypes.contains(type.chain.first!))
                default:
                    XCTAssertTrue(false)
                }
            }
        case .success:
            XCTAssertTrue(false)
        }
    }

    func testRedeclarations() throws {
        let source = """
            User: [
                x: I32
            ]
            User: [
                y: I32
            ]
            """
        let module = try Syntax.Module(source: source, path: "main")

        let result = module.semanticCheck()

        switch result {
        case let .failure(errorList):
            let errors = errorList.errors
            XCTAssertEqual(errors.count, 1)

            errors.forEach { error in
                switch error {
                case .type(.redeclaration):
                    XCTAssertTrue(true)
                default:
                    XCTAssertTrue(false)
                }
            }
        case .success:
            XCTAssertTrue(false)
        }
    }

    func testCyclical() throws {
        let source = """
            First: [
                x: First
            ]
        """
        let module = try Syntax.Module(source: source, path: "main")

        let result = module.semanticCheck()

        switch result {
        case let .failure(errorList):
            let errors = errorList.errors
            XCTAssertEqual(errors.count, 1)

            errors.forEach { error in
                switch error {
                case let .type(.cyclicType(type, identifier)):
                    XCTAssertTrue(true)
                default:
                    XCTAssertTrue(false)
                }
            }
        case .success:
            XCTAssertTrue(false)
        }
    }

    func testCyclicalAdvanced() throws {
        let source = """
            First: [
                x: Second
            ]
            Second: [
                x: Third
            ]
            Third: [
                x: First
            ]
        """
        let module = try Syntax.Module(source: source, path: "main")
        let result = module.semanticCheck()

        switch result {
        case let .failure(errorList):
            let errors = errorList.errors
            XCTAssertEqual(errors.count, 3)

            errors.forEach { error in
                switch error {
                case let .type(.cyclicType(type, identifier)):
                    XCTAssertTrue(true)
                default:
                    XCTAssertTrue(false)
                }
            }
        case .success:
            XCTAssertTrue(false)
        }
    }
}
