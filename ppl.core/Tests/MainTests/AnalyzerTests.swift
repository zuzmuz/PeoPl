import XCTest

@testable import Main

final class AnalyzerTests: XCTestCase {
    let fileNames:
        [String: Result<
            Semantic.Context,
            Semantic.ErrorList
        >] = [
            "goodtypes": .success(
                .init(definitions: .init(valueDefinitions: [:])))
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
            let (typeDeclarations, typeLookup, typeErrors) =
                module.resolveTypeSymbols(
                    contextTypeDeclarations: intrinsicDeclarations
                        .typeDeclarations)
            // module.assertEqual(with: reference)
        }
    }
}
