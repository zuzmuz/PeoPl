#if ANALYZER
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
			.access(selfExpression, selfField, selfType),
			.access(withExpression, withField, withType)
		):
			selfExpression.assertEqual(with: withExpression)
			XCTAssertEqual(selfField, withField)
			XCTAssertEqual(selfType, withType)
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
		case let (
			.branched(selfMatrix, selfType),
			.branched(withMatrix, withType)
		):
			XCTAssertEqual(selfType, withType)
			XCTAssertEqual(
				selfMatrix.rows.count,
				withMatrix.rows.count
			)
			for (selfRow, withRow) in zip(selfMatrix.rows, withMatrix.rows) {
				selfRow.pattern.assertEqual(
					with: withRow.pattern
				)
				XCTAssertEqual(
					selfRow.guardExpression.type,
					withRow.guardExpression.type
				)
				selfRow.guardExpression.assertEqual(
					with: withRow.guardExpression
				)
				selfRow.body.assertEqual(with: withRow.body)
			}
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
						arguments: [.named("a"): .int, .named("b"): .int]
					):
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
											tag: .named("a"), type: .int
										),
										right: .fieldInScope(
											tag: .named("b"), type: .int
										),
										type: .int
									),
									type: .int
								),
								right: .intLiteral(3),
								type: .int
							),
							right: .binary(
								.minus,
								left: .fieldInScope(
									tag: .named("a"), type: .int
								),
								right: .fieldInScope(
									tag: .named("b"), type: .int
								),
								type: .int
							),
							type: .bool
						),
					.init(
						identifier: .chain(["functionCall"]),
						inputType: (.input, .nothing),
						arguments: [
							.named("a"): .int,
							.named("b"): .int,
							.named("c"): .int,
						]
					):
						.call(
							signature: .init(
								identifier: .chain(["arithmetic"]),
								inputType: (.input, .int),
								arguments: [
									.named("a"): .int, .named("b"): .int,
								]
							),
							input: .binary(
								.plus,
								left: .fieldInScope(
									tag: .named("a"), type: .int
								),
								right: .fieldInScope(
									tag: .named("b"), type: .int
								),
								type: .int
							),
							arguments: [
								.named("a"): .fieldInScope(
									tag: .named("b"), type: .int
								),
								.named("b"): .fieldInScope(
									tag: .named("c"), type: .int
								),
							],
							type: .bool
						),
					.init(
						identifier: .chain(["access"]),
						inputType: (.input, .nothing),
						arguments: [
							.named("r"): .nominal(.chain(["Record"]))
						]
					):
						.call(
							signature: .init(
								identifier: .chain(["arithmetic"]),
								inputType: (.input, .int),
								arguments: [
									.named("a"): .int, .named("b"): .int,
								]
							),
							input: .intLiteral(1),
							arguments: [
								.named("a"): .access(
									expression: .fieldInScope(
										tag: .named("r"),
										type: .nominal(.init(chain: ["Record"]))
									),
									field: .named("a"),
									type: .int
								),
								.named("b"): .access(
									expression: .fieldInScope(
										tag: .named("r"),
										type: .nominal(.init(chain: ["Record"]))
									),
									field: .named("b"),
									type: .int
								),
							],
							type: .bool
						),
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
				withExtension: "ppl"
			)!
			let source = try Syntax.Source(url: sourceUrl)
			let module = TreeSitterModulParser.parseModule(source: source)

			let (
				typeDeclarations,
				typeLookup,
				typeErrors
			) = module.resolveTypeSymbols(
				contextTypeDeclarations: intrinsicDeclarations.typeDeclarations
			)

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
					.functionDeclarations
			)

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
						context: context
					)
					expressionDefinitions[signature] = expression
				}
			}

			XCTAssertEqual(
				expressionDefinitions.count,
				reference.expressionDefinitions.count
			)

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
#endif
