// import XCTest
//
// @testable import PeoplCore
//
// final class FunctionDeclarationsTests: XCTestCase {
//     func testNoErrors() throws {
//         let source = """
//             func hi() => Nothing
//                 Nothing
//             func hi(a: I32) => Nothing
//                 Nothing
//             func main() => Nothing
//                 Nothing
//             """
//
//         let module = try Module(source: source, path: "main")
//         let builtins = Builtins.getBuiltinContext()
//
//         let checker = module.resolveFunctionDefinitions(typesDefinitions: [:], builtins: builtins)
//
//         XCTAssertEqual(checker.errors.count, 0)
//         XCTAssertEqual(checker.functions.count, 3)
//         XCTAssertEqual(checker.functionsIdentifiers.count, 2)
//
//         if let hiFunction = checker.functionsIdentifiers[.init(scope: nil, name: "hi")],
//             let mainFunction = checker.functionsIdentifiers[.init(scope: nil, name: "main")]
//         {
//             XCTAssertEqual(hiFunction.count, 2)
//             XCTAssertEqual(mainFunction.count, 1)
//
//         } else {
//             XCTAssertTrue(false)
//         }
//
//         XCTAssertEqual(checker.functionsInputTypeIdentifiers.count, 1)
//
//         if let nothingInputFunctions = checker.functionsInputTypeIdentifiers[.nothing()] {
//             XCTAssertEqual(nothingInputFunctions.count, 3)
//         } else {
//             XCTAssertTrue(false)
//         }
//     }
//
//     func testErrorDuplicates() throws {
//         let source = """
//             func hi() => Nothing
//                 Nothing
//             func hi() => I32
//                 3
//             func main() => Nothing
//                 Nothing
//         """
//
//         let module = try Module(source: source, path: "main")
//         let builtins = Builtins.getBuiltinContext()
//
//         let checker = module.resolveFunctionDefinitions(typesDefinitions: [:], builtins: builtins)
//
//         XCTAssertEqual(checker.errors.count, 1)
//
//         if let error = checker.errors.first,
//             case let FunctionSemanticError.redeclaration(locations) = error
//         {
//             XCTAssertEqual(locations.count, 2)
//
//             let sortedLocations = locations.sorted()
//
//             XCTAssertEqual(sortedLocations[0].pointRange.lowerBound.line, 0)
//             XCTAssertEqual(sortedLocations[1].pointRange.lowerBound.line, 2)
//         } else {
//             XCTAssertTrue(false)
//         }
//
//         XCTAssertEqual(checker.functions.count, 2)
//         XCTAssertEqual(checker.functionsIdentifiers.count, 2)
//
//         if let hiFunction = checker.functionsIdentifiers[.init(scope: nil, name: "hi")],
//             let mainFunction = checker.functionsIdentifiers[.init(scope: nil, name: "main")]
//         {
//             XCTAssertEqual(hiFunction.count, 1)
//             XCTAssertEqual(mainFunction.count, 1)
//
//         } else {
//             XCTAssertTrue(false)
//         }
//
//         XCTAssertEqual(checker.functionsInputTypeIdentifiers.count, 1)
//
//         if let nothingInputFunctions = checker.functionsInputTypeIdentifiers[.nothing()] {
//             XCTAssertEqual(nothingInputFunctions.count, 2)
//         } else {
//             XCTAssertTrue(false)
//         }
//     }
//
//     func testMultipleDuplicates() throws {
//         let source = """
//             func hi() => Nothing
//                 Nothing
//             func hi() => String
//                 "hi"
//             func bye() => Nothing
//                 Nothing
//             func bye() => String
//                 "bye"
//             func bye(not_clashing: I32) => Nothing
//                 Nothing
//             func main() => Nothing
//                 Nothing
//             """
//
//         let module = try Module(source: source, path: "main")
//         let builtins = Builtins.getBuiltinContext()
//
//         let checker = module.resolveFunctionDefinitions(typesDefinitions: [:], builtins: builtins)
//
//         XCTAssertEqual(checker.errors.count, 2)
//
//         XCTAssertEqual(checker.functions.count, 4)
//         XCTAssertEqual(checker.functionsIdentifiers.count, 3)
//
//         if let hiFunction = checker.functionsIdentifiers[.init(scope: nil, name: "hi")],
//             let byeFunction = checker.functionsIdentifiers[.init(scope: nil, name: "bye")],
//             let mainFunction = checker.functionsIdentifiers[.init(scope: nil, name: "main")]
//         {
//             XCTAssertEqual(hiFunction.count, 1)
//             XCTAssertEqual(byeFunction.count, 2)
//             XCTAssertEqual(mainFunction.count, 1)
//
//         } else {
//             XCTAssertTrue(false)
//         }
//
//         XCTAssertEqual(checker.functionsInputTypeIdentifiers.count, 1)
//     }
// }
