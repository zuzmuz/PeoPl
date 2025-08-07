import XCTest

@testable import Main

final class ExpressionTypeCheckingTests: XCTestCase {
    // let fileNames:
    //     [String: (
    //         expressionDefinitions: Semantic.FunctionDefinitionsMap,
    //         expressionErrors: [Semantic.Error]
    //     )] = [
    //         "goodexpression": (
    //             expressionDefinitions: [
    //                 .init(
    //                     identifier: .chain(["factorial"]),
    //                     inputType: (.input, .nothing),
    //                     arguments: [
    //                         .named("n"): .nominal(.chain(["Int"]))
    //                     ]
    //                 ): .branching(
    //                     branches: [
    //                         (
    //                             match: .init(
    //                                 condition: .binary(
    //                                     .equal,
    //                                     left: ,
    //                                     right: Semantic.Expression,
    //                                     type: Semantic.TypeSpecifier
    //                                 ),
    //                                 bindings: [Semantic.Tag : Semantic.TypeSpecifier]),
    //                             guard: Semantic.Expression,
    //                             body: Semantic.Expression
    //                         )
    //                     ],
    //                     type: .int
    //                 )
    //             ],
    //             expressionErrors: []
    //         )
    //     ]
}
