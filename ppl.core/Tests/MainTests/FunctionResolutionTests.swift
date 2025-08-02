import XCTest

@testable import Main

final class FunctionResolutionTests: XCTestCase {
    let fileNames:
        [String: (
            functionDeclarations: Semantic.FunctionDeclarationsMap,
            functionErrors: [Semantic.Error]
        )] = [
            "goodfunctions": (
                [
                    .init(
                        identifier: .chain(["with", "input"]),
                        inputType: (.input, .nominal(.chain(["Float"]))),
                        arguments: [:]
                    ): .nominal(.chain(["Float"])),
                    .init(
                        identifier: .chain(["add"]),
                        inputType: (.input, .nothing),
                        arguments: [
                            .named("a"): .nominal(.chain(["Int"])),
                            .named("b"): .nominal(.chain(["Int"])),
                        ]
                    ): .nominal(.chain(["Int"])),
                    .init(
                        identifier: .chain(["overload"]),
                        inputType: (.input, .nothing),
                        arguments: [
                            .named("a"): .nominal(.chain(["Int"]))
                        ]
                    ): .nominal(.chain(["Int"])),
                    .init(
                        identifier: .chain(["overload"]),
                        inputType: (.input, .nothing),
                        arguments: [
                            .named("a"): .nominal(.chain(["Int"])),
                            .named("b"): .nominal(.chain(["Int"])),
                        ]
                    ): .nominal(.chain(["Int"])),
                    .init(
                        identifier: .chain(["overload"]),
                        inputType: (.input, .nothing),
                        arguments: [
                            .named("a"): .nominal(.chain(["Int"])),
                            .named("c"): .nominal(.chain(["Int"])),
                        ]
                    ): .nominal(.chain(["Int"])),
                ],
                []
            )
        ]

    func testFiles() throws {

        let bundle = Bundle.module
        let intrinsicDeclarations = Semantic.getIntrinsicDeclarations()

        for (name, reference) in fileNames {
            let sourceUrl = bundle.url(
                forResource: "analyzer_\(name)",
                withExtension: "ppl")!
            let source = try Syntax.Source(url: sourceUrl)
            let module = TreeSitterModulParser.parseModule(source: source)
            let (typeDeclarations, _, _) =
                module.resolveTypeSymbols(
                    contextTypeDeclarations: intrinsicDeclarations
                        .typeDeclarations)
            let (functionDeclarations, _, functionErrors) =
                module.resolveFunctionSymbols(
                    typeDeclarations: typeDeclarations,
                    contextFunctionDeclarations: intrinsicDeclarations
                        .functionDeclarations)

            XCTAssertEqual(
                functionErrors.count,
                reference.functionErrors.count)
            for (signature, typeSpecifier) in functionDeclarations {
                XCTAssertNotNil(reference.functionDeclarations[signature])
                if let referenceFunction =
                    reference.functionDeclarations[signature]
                {
                    XCTAssertEqual(typeSpecifier, referenceFunction)
                }
            }
        }
    }
}
