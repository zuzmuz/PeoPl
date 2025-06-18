import XCTest

@testable import PeoplCore

final class AnalyzerTests: XCTestCase {
    let fileNames:
        [String: Result<
            Semantic.Context,
            Semantic.ErrorList
        >] = [
            "functions": .success(
                .init(definitions: .init(valueDefinitions: [:])))
        ]

    func testFiles() throws {
        let bundle = Bundle.module

        for (name, reference) in fileNames {
            let sourceUrl = bundle.url(
                forResource: "analyzer_\(name)",
                withExtension: "ppl")!
            let source = try Syntax.Module(url: sourceUrl)
            let result = source.semanticCheck()
            print(result)
            switch (result, reference) {
            case (.success, .success):
                break
            default:
                XCTFail("Results do not match for \(name)")
            }
            // source.assertEqual(with: reference)
        }
    }
}
