import XCTest

@testable import Main

final class BranchingExpressionTypeCheckingTests: XCTestCase {
    let fileNames:
        [String: (
            expressionDefinitions: Semantic.FunctionDefinitionsMap,
            expressionErrors: [Semantic.Error]
        )] = [
            "branchingexpressions": (
                expressionDefinitions: [
                    .init(
                        identifier: .chain(["pattern"]),
                        inputType: (.input, .nominal(.chain(["Struct"]))),
                        arguments: [:]):
                        .nothing
                ],
                expressionErrors: []
            )
        ]

    func testFiles() throws {
        let bundle = Bundle.module
        let intrinsicDeclarations = Semantic.getIntrinsicDeclarations()

        for (name, reference) in fileNames {
            let sourceURL = bundle.url(
                forResource: "analyzer_\(name)",
                withExtension: "ppl")!
            let source = try Syntax.Source(url: sourceURL)
            let module = TreeSitterModulParser.parseModule(source: source)

            let (
                typeDeclarations,
                typeLookup,
                typeErrors
            ) = module.resolveTypeSymbols(
                contextTypeDeclarations: intrinsicDeclarations.typeDeclarations)

            let allTypeDeclarations = intrinsicDeclarations.typeDeclarations
                .merging(typeDeclarations) { $1 }

            let (
                functionDeclarations,
                functionBodyExpressions,
                functionLookup,
                functionErrors
            ) = module.resolveFunctionSymbols(
                typeLookup: typeLookup,
                typeDeclarations: allTypeDeclarations,
                contextFunctionDeclarations: intrinsicDeclarations
                    .functionDeclarations)

            let context = Semantic.DeclarationsContext(
                typeDeclarations: allTypeDeclarations,
                functionDeclarations: intrinsicDeclarations
                    .functionDeclarations
                    .merging(functionDeclarations) { $1 },
                operatorDeclarations: intrinsicDeclarations.operatorDeclarations
            )

            var expressionDefinitions: Semantic.FunctionDefinitionsMap = [:]

            for (signature, body) in functionBodyExpressions {
                if let outputype = functionDeclarations[signature] {
                    // TODO: should catch the errors and check for them
                    let expression = try signature.checkBody(
                        body: body,
                        outputType: outputype,
                        context: context)
                    expressionDefinitions[signature] = expression
                }
            }

            print("expressionDefinitions: \(expressionDefinitions)")
        }
    }
}
