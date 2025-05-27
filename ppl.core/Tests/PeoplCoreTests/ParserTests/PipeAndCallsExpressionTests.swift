// import XCTest
// @testable import PeoplCore
//
// final class PipeAndCallsExpressionTests: XCTestCase {
//     func testHelloWorld() throws {
//         let source = """
//                 func main() => Nothing
//                     "Hello World" |>
//                     print()
//             """
//         let module = try Syntax.Module(source: source, path: "main")
//
//         XCTAssertEqual(module.statements.count, 1)
//         let statement = module.statements[0]
//         guard case let .functionDefinition(functionDefinition) = statement else {
//             XCTAssertTrue(false)
//             return
//         }
//
//         let body = functionDefinition.body
//
//         if case let .piped(left, right) = body?.expressionType,
//             case let .literal(.stringLiteral(left)) = left.expressionType,
//             case let .functionCall(prefix, arguments) = right.expressionType,
//             case let .field(name) = prefix.expressionType
//         {
//             XCTAssertEqual(left, "Hello World")
//             XCTAssertEqual(arguments.count, 0)
//             XCTAssertEqual(name.identifier, "print")
//             XCTAssertNil(name.scope)
//         } else {
//             XCTAssertTrue(false)
//         }
//     }
//
//     func testStringFormatting() throws {
//         let source = """
//             func main() => Nothing
//                 (1 + 2) * 3 |>
//                 print(format: "the operations value is {}")
//                 
//         """
//         let module = try Syntax.Module(source: source, path: "main")
//
//         XCTAssertEqual(module.statements.count, 1)
//         let statement = module.statements[0]
//         guard case let .functionDefinition(functionDefinition) = statement else {
//             XCTAssertTrue(false)
//             return
//         }
//
//         let body = functionDefinition.body
//
//         if case let .piped(left, right) = body?.expressionType,
//             case let .functionCall(prefix, arguments) = right.expressionType,
//             case let .binary(.times, left, right) = left.expressionType,
//             case let .literal(.intLiteral(value3)) = right.expressionType,
//             case let .binary(.plus, left, right) = left.expressionType,
//             case let .literal(.intLiteral(value1)) = left.expressionType,
//             case let .literal(.intLiteral(value2)) = right.expressionType,
//             case let .field(functionName) = prefix.expressionType
//         {
//             XCTAssertEqual(value1, 1)
//             XCTAssertEqual(value2, 2)
//             XCTAssertEqual(value3, 3)
//
//             XCTAssertEqual(arguments.count, 1)
//             let argument = arguments[0]
//             XCTAssertEqual(argument.name, "format")
//             XCTAssertEqual(functionName.identifier, "print")
//
//             guard case let .literal(.stringLiteral(formatString)) = argument.value.expressionType else {
//                 XCTAssertTrue(false)
//                 return
//             }
//
//             XCTAssertEqual(formatString, "the operations value is {}")
//         
//         } else {
//             XCTAssertTrue(false)
//         }
//     }
//
//     func testScopedCalls() throws {
//         let source = """
//             func main() => Nothing
//                 A::B::some_function(a: 1, b: 3) |>
//                 C::another(c: true) |>
//                 D::E::F::final(d: "one", e: "two", f: "three")
//         """
//         let module = try Syntax.Module(source: source, path: "main")
//
//         XCTAssertEqual(module.statements.count, 1)
//         let statement = module.statements[0]
//         guard case let .functionDefinition(functionDefinition) = statement else {
//             XCTAssertTrue(false)
//             return
//         }
//
//         let body = functionDefinition.body
//
//         if case let .piped(left, right) = body?.expressionType,
//             case let .functionCall(prefix3, arguments3) = right.expressionType,
//             case let .piped(left, right) = left.expressionType,
//             case let .functionCall(prefix1, arguments1) = left.expressionType,
//             case let .functionCall(prefix2, arguments2) = right.expressionType,
//             case let .field(function1) = prefix1.expressionType,
//             case let .field(function2) = prefix2.expressionType,
//             case let .field(function3) = prefix3.expressionType
//         {
//             XCTAssertEqual(arguments1.count, 2)
//             XCTAssertEqual(arguments1[0].name, "a")
//             XCTAssertEqual(arguments1[1].name, "b")
//
//             if case let .literal(.intLiteral(value1)) = arguments1[0].value.expressionType,
//                 case let .literal(.intLiteral(value2)) = arguments1[1].value.expressionType
//             {
//                 XCTAssertEqual(value1, 1)
//                 XCTAssertEqual(value2, 3)
//             } else {
//                 XCTAssertTrue(false)
//             }
//
//             XCTAssertEqual(arguments2.count, 1)
//             XCTAssertEqual(arguments2[0].name, "c")
//
//             if case let .literal(.boolLiteral(value1)) = arguments2[0].value.expressionType
//             {
//                 XCTAssertEqual(value1, true)
//             } else {
//                 XCTAssertTrue(false)
//             }
//
//
//             XCTAssertEqual(arguments3.count, 3)
//             XCTAssertEqual(arguments3[0].name, "d")
//             XCTAssertEqual(arguments3[1].name, "e")
//             XCTAssertEqual(arguments3[2].name, "f")
//
//             if case let .literal(.stringLiteral(value1)) = arguments3[0].value.expressionType,
//                 case let .literal(.stringLiteral(value2)) = arguments3[1].value.expressionType,
//                 case let .literal(.stringLiteral(value3)) = arguments3[2].value.expressionType
//             {
//                 XCTAssertEqual(value1, "one")
//                 XCTAssertEqual(value2, "two")
//                 XCTAssertEqual(value3, "three")
//             } else {
//                 XCTAssertTrue(false)
//             }
//
//             XCTAssertEqual(function1.identifier, "some_function")
//             XCTAssertEqual(function2.identifier, "another")
//             XCTAssertEqual(function3.identifier, "final")
//             
//             XCTAssertEqual(function1.scope?.chain.count, 2)
//             XCTAssertEqual(function1.scope?.chain[0], "A")
//             XCTAssertEqual(function1.scope?.chain[1], "B")
//
//             XCTAssertEqual(function2.scope?.chain.count, 1)
//             XCTAssertEqual(function2.scope?.chain[0], "C")
//
//             XCTAssertEqual(function3.scope?.chain.count, 3)
//             XCTAssertEqual(function3.scope?.chain[0], "D")
//             XCTAssertEqual(function3.scope?.chain[1], "E")
//             XCTAssertEqual(function3.scope?.chain[2], "F")
//         } else {
//             XCTAssertTrue(false)
//         }
//     }
// }
