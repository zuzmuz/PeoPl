import XCTest

@testable import Main

final class FunctionResolutionTests: XCTestCase {
    let fileNames:
        [String: (
            functionDeclarations: Semantic.FunctionDeclarationsMap,
            functionErrors: [Semantic.Error]
        )] = [
            "goodfunctions": (
                functionDeclarations: [
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
                            .named("b"): .nominal(.chain(["Float"])),
                        ]
                    ): .nominal(.chain(["Int"])),
                    .init(
                        identifier: .chain(["overload"]),
                        inputType: (.input, .nothing),
                        arguments: [
                            .named("a"): .nominal(.chain(["Int"])),
                            .named("c"): .nominal(.chain(["Float"])),
                        ]
                    ): .nominal(.chain(["Int"])),
                ],
                functionErrors: []
            ),
            "redeclared_functions": (
                functionDeclarations: [
                    .init(
                        identifier: .chain(["first"]),
                        inputType: (.input, .nothing),
                        arguments: [
                            .named("a"): .nominal(.chain(["Int"])),
                            .named("b"): .nominal(.chain(["Bool"])),
                        ]
                    ): .nominal(.chain(["Bool"])),
                    .init(
                        identifier: .chain(["with", "input"]),
                        inputType: (.input, .nominal(.chain(["Float"]))),
                        arguments: [:]
                    ): .nominal(.chain(["Float"])),
                ],
                functionErrors: [
                    .init(
                        location: .nowhere,
                        errorChoice: .functionRedeclaration(
                            signature:
                                .init(
                                    identifier: .chain(["first"]),
                                    inputType: (.input, .nothing),
                                    arguments: [
                                        .named("a"): .nominal(.chain(["Int"])),
                                        .named("b"): .nominal(.chain(["Bool"])),
                                    ]),
                            otherLocations: [
                                .nowhere, .nowhere // FIX: put correct locations
                            ])),
                    .init(
                        location: .nowhere,
                        errorChoice: .functionRedeclaration(
                            signature:
                                .init(
                                    identifier: .chain(["first"]),
                                    inputType: (.input, .nothing),
                                    arguments: [
                                        .named("a"): .nominal(.chain(["Int"])),
                                        .named("b"): .nominal(.chain(["Bool"])),
                                    ]),
                            otherLocations: [
                                .nowhere, .nowhere // FIX: put correct locations
                            ])),
                    .init(
                        location: .nowhere,
                        errorChoice: .functionRedeclaration(
                            signature:
                                .init(
                                    identifier: .chain(["with", "input"]),
                                    inputType: (
                                        .input, .nominal(.chain(["Float"]))
                                    ),
                                    arguments: [:]
                                ),
                            otherLocations: [
                                .nowhere, .nowhere // FIX: put correct locations
                            ])),
                    .init(
                        location: .nowhere,
                        errorChoice: .functionRedeclaration(
                            signature:
                                .init(
                                    identifier: .chain(["with", "input"]),
                                    inputType: (
                                        .input, .nominal(.chain(["Float"]))
                                    ),
                                    arguments: [:]
                                ),
                            otherLocations: [
                                .nowhere, .nowhere // FIX: put correct locations
                            ])),
                ]
            ),
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
            let (typeDeclarations, typeLookup, _) =
                module.resolveTypeSymbols(
                    contextTypeDeclarations: intrinsicDeclarations
                        .typeDeclarations)
            let allTypeDeclarations = intrinsicDeclarations.typeDeclarations
                .merging(typeDeclarations) { $1 }
            let (functionDeclarations, _, functionErrors) =
                module.resolveFunctionSymbols(
                    typeLookup: typeDeclarations,
                    typeDeclarations: allTypeDeclarations,
                    contextFunctionDeclarations: intrinsicDeclarations
                        .functionDeclarations)

            XCTAssertEqual(
                functionErrors.count,
                reference.functionErrors.count)

            zip(
                functionErrors.sorted { $0.location < $1.location },
                reference.functionErrors
            ).forEach {
                $0.assertEqual(with: $1)
            }

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
