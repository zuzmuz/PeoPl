import XCTest

@testable import PeoplCore

final class TypesAnalyzerTests: XCTestCase {
    func testSimpleCall() throws {
        let source = """
            type User
                first_name: String
                last_name: String
                age: I32

            type Role
                title: String
            """
        let module = try Module(source: source, path: "main")
        let builtins = Builtins.getBuiltinContext()

    }
}
