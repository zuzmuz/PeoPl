import XCTest

@testable import Main

final class ExpressionTypeCheckingTests: XCTestCase {
    let fileNames:
        [String: (
            expressionDefinitions: Semantic.FunctionDefinitionsMap,
            expressionErrors: [Semantic.Error]
        )] = [
            "goodexpressions": (
                expressionDefinitions: [
                    .init(
                        identifier: .chain(["factorial"]),
                        inputType: (.input, .int),
                        arguments: [:]
                    ): .branching(
                        branches: [
                            (
                                match: .init(
                                    condition: .binary(
                                        .equal,
                                        left: .input(type: .int),
                                        right: .intLiteral(1),
                                        type: .bool
                                    ),
                                    bindings: [:]),
                                guard: .boolLiteral(true),
                                body: .intLiteral(1)
                            )
                        ],
                        type: .int
                    )
                ],
                expressionErrors: []
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

            let (functionDeclarations, functionLookup, functionErrors) =
                module.resolveFunctionSymbols(
                    typeLookup: [:],
                    typeDeclarations: intrinsicDeclarations.typeDeclarations,
                    contextFunctionDeclarations: intrinsicDeclarations
                        .functionDeclarations)

            let context = Semantic.DeclarationsContext(
                typeDeclarations: intrinsicDeclarations.typeDeclarations,
                functionDeclarations: intrinsicDeclarations
                    .functionDeclarations
                    .merging(functionDeclarations) { $1 },
                operatorDeclarations: intrinsicDeclarations.operatorDeclarations
            )

            for (signature, definition) in functionLookup {
                if let outputype = functionDeclarations[signature] {
                    let exprression = try signature.checkBody(
                        body: definition.definition,
                        outputType: outputype,
                        context: context)
                }
            }
        }
    }
}
