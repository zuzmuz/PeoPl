import XCTest

@testable import Main

extension Semantic.Expression: Testable {
    func assertEqual(
        with: Self
    ) {
        switch (self, with) {
        case (.nothing, .nothing), (.never, .never):
            break
        case let (.intLiteral(selfLiteral), .intLiteral(withLiteral)):
            XCTAssertEqual(selfLiteral, withLiteral)
        case let (.floatLiteral(selfLiteral), .floatLiteral(withLiteral)):
            XCTAssertEqual(selfLiteral, withLiteral)
        case let (.stringLiteral(selfLiteral), .stringLiteral(withLiteral)):
            XCTAssertEqual(selfLiteral, withLiteral)
        case let (.boolLiteral(selfLiteral), .boolLiteral(withLiteral)):
            XCTAssertEqual(selfLiteral, withLiteral)
        case let (.input(selfType), .input(withType)):
            XCTAssertEqual(selfType, withType)
        case let (
            .unary(selfOperator, selfExpression, selfType),
            .unary(withOperator, withExpression, withType)
        ):
            XCTAssertEqual(selfOperator, withOperator)
            selfExpression.assertEqual(with: withExpression)
            XCTAssertEqual(selfType, withType)
        case let (
            .binary(selfOperator, selfLeft, selfRight, selfType),
            .binary(withOperator, withLeft, withRight, withType)
        ):
            XCTAssertEqual(selfOperator, withOperator)
            selfLeft.assertEqual(with: withLeft)
            selfRight.assertEqual(with: withRight)
            XCTAssertEqual(selfType, withType)
        case let (
            .initializer(selfType, selfArguments),
            .initializer(withType, withArguments)
        ):
            XCTAssertEqual(selfType, withType)
            XCTAssertEqual(selfArguments.count, withArguments.count)
            for (selfTag, selfExpression) in selfArguments {
                guard let withExpression = withArguments[selfTag] else {
                    XCTFail("Missing argument \(selfTag)")
                    return
                }
                selfExpression.assertEqual(with: withExpression)
            }
        case let (
            .call(selfSignature, selfInput, selfArguments, selfType),
            .call(withSignature, withInput, withArguments, withType)
        ):
            XCTAssertEqual(selfSignature, withSignature)
            selfInput.assertEqual(with: withInput)
            XCTAssertEqual(selfArguments.count, withArguments.count)
            for (selfTag, selfExpression) in selfArguments {
                guard let withExpression = withArguments[selfTag] else {
                    XCTFail("Missing argument \(selfTag)")
                    return
                }
                selfExpression.assertEqual(with: withExpression)
            }
            XCTAssertEqual(selfType, withType)
        case let (
            .fieldInScope(selfField, selfType),
            .fieldInScope(withField, withType)
        ):
            XCTAssertEqual(selfField, withField)
            XCTAssertEqual(selfType, withType)
        // case let (
        //     .branching(selfBranches, selfType),
        //     .branching(withBranches, withType)
        // ):
        //     XCTAssertEqual(selfType, withType)
        //     XCTAssertEqual(selfBranches.count, withBranches.count)
        //     for (selfBranch, withBranch) in zip(selfBranches, withBranches) {
        //         XCTAssertEqual(
        //             selfBranch.matchExpression.condition.type,
        //             withBranch.matchExpression.condition.type)
        //         selfBranch.matchExpression.condition.assertEqual(
        //             with: withBranch.matchExpression.condition)
        //         XCTAssertEqual(
        //             selfBranch.guardExpression.type,
        //             withBranch.guardExpression.type)
        //         selfBranch.guardExpression.assertEqual(
        //             with: withBranch.guardExpression)
        //         selfBranch.body.assertEqual(with: withBranch.body)
        //     }
        default:
            fatalError("can't compare \(self) with \(with)")
        }
    }
}

final class ExpressionTypeCheckingTests: XCTestCase {
    let fileNames:
        [String: (
            expressionDefinitions: Semantic.FunctionDefinitionsMap,
            expressionErrors: [Semantic.Error]
        )] = [
            "goodexpressions": (
                expressionDefinitions: [
                    .init(
                        identifier: .chain(["arithmetic"]),
                        inputType: (.input, .int),
                        arguments: [.named("a"): .int, .named("b"): .int]):
                        .binary(
                            .greaterThan,
                            left: .binary(
                                .minus,
                                left: .binary(
                                    .times,
                                    left: .input(type: .int),
                                    right: .binary(
                                        .plus,
                                        left: .fieldInScope(
                                            tag: .named("a"), type: .int),
                                        right: .fieldInScope(
                                            tag: .named("b"), type: .int),
                                        type: .int),
                                    type: .int
                                ),
                                right: .intLiteral(3),
                                type: .int
                            ),
                            right: .binary(
                                .minus,
                                left: .fieldInScope(
                                    tag: .named("a"), type: .int),
                                right: .fieldInScope(
                                    tag: .named("b"), type: .int),
                                type: .int),
                            type: .bool),
                    .init(
                        identifier: .chain(["functionCall"]),
                        inputType: (.input, .nothing),
                        arguments: [
                            .named("a"): .int,
                            .named("b"): .int,
                            .named("c"): .int,
                        ]):
                        .call(
                            signature: .init(
                                identifier: .chain(["arithmetic"]),
                                inputType: (.input, .int),
                                arguments: [
                                    .named("a"): .int, .named("b"): .int,
                                ]),
                            input: .binary(
                                .plus,
                                left: .fieldInScope(
                                    tag: .named("a"), type: .int),
                                right: .fieldInScope(
                                    tag: .named("b"), type: .int),
                                type: .int),
                            arguments: [
                                .named("a"): .fieldInScope(
                                    tag: .named("b"), type: .int),
                                .named("b"): .fieldInScope(
                                    tag: .named("c"), type: .int),
                            ],
                            type: .bool),

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

            let (
                functionDeclarations,
                functionBodyExpressions,
                functionLookup,
                functionErrors
            ) =
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

            XCTAssertEqual(
                expressionDefinitions.count,
                reference.expressionDefinitions.count)

            for (signature, expression) in expressionDefinitions {
                XCTAssertNotNil(reference.expressionDefinitions[signature])
                if let referenceExpression =
                    reference.expressionDefinitions[signature]
                {
                    expression.assertEqual(with: referenceExpression)
                }
            }
        }
    }
}
