// import XCTest
//
// @testable import PeoplCore
//
// final class TypesAnalyzerTests: XCTestCase {
//     func testSimpleTypes() throws {
//         let source = """
//             type User
//                 first_name: String
//                 last_name: String
//                 age: I32
//
//             type Role
//                 title: String
//             """
//         let module = try Module(source: source, path: "main")
//
//         let result = module.semanticCheck()
//
//         switch result {
//         case .errors:
//             XCTAssertTrue(false)
//         case .context(let context):
//             XCTAssertEqual(context.functions.count, 0)
//             XCTAssertEqual(context.types.count, 2)
//         }
//     }
//
//     func testInvalidTypes() throws {
//         let source = """
//             type User
//                 first_name: Sring
//                 last_name: String
//                 age: I31
//
//             type Role
//                 user: Usr
//             """
//         let module = try Module(source: source, path: "main")
//
//         let result = module.semanticCheck()
//         
//         // TODO: think of adding tests for locations
//         let wrongTypes = Set(["Sring", "I31", "Usr"])
//
//         switch result {
//         case .errors(let errors):
//             XCTAssertEqual(errors.count, 3)
//             
//             errors.forEach { error in
//                 switch error {
//                 case let .type(.typeNotInScope(_, type, _)):
//                     XCTAssertTrue(wrongTypes.contains(type.chain.first!.typeName))
//                 default:
//                     XCTAssertTrue(false)
//                 }
//             }
//         case .context:
//             XCTAssertTrue(false)
//         }
//     }
//
//     func testRedeclarations() throws {
//         let source = """
//             type User
//                 x: I32
//             type User
//                 y: I32
//             """
//         let module = try Module(source: source, path: "main")
//
//         let result = module.semanticCheck()
//
//         switch result {
//         case .errors(let errors):
//             XCTAssertEqual(errors.count, 1)
//             
//             errors.forEach { error in
//                 switch error {
//                 case .type(.redeclaration):
//                     XCTAssertTrue(true)
//                 default:
//                     XCTAssertTrue(false)
//                 }
//             }
//         case .context:
//             XCTAssertTrue(false)
//         }
//     }
// }
