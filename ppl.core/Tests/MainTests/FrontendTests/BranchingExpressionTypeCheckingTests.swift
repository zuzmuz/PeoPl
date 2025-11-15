#if ANALYZER
import XCTest

@testable import Main

extension Semantic.Pattern: Testable {
	func assertEqual(with: Self) {
		switch (self, with) {
		case (.wildcard, .wildcard):
			break
		case let (.binding(selfBinding), .binding(withBinding)):
			XCTAssertEqual(selfBinding, withBinding)
		case let (.value(selfValue), .value(withValue)):
			selfValue.assertEqual(with: withValue)
		case let (
			.constructor(selfTag, selfPattern),
			.constructor(withTag, withPattern)
		):
			XCTAssertEqual(selfTag, withTag)
			selfPattern.assertEqual(with: withPattern)
		case let (.destructor(selfFields), .destructor(withFields)):
			XCTAssertEqual(selfFields.count, withFields.count)
			for (selfTag, selfPattern) in selfFields {
				guard let withPattern = withFields[selfTag] else {
					XCTFail("missing field \(selfTag) in \(withFields)")
					return
				}
				selfPattern.assertEqual(with: withPattern)
			}
		default:
			XCTFail("comparing incompatable patterns \(self) and \(with)")
		}
	}
}

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
						arguments: [:]
					):
						.branched(
							matrix: .init(rows: [
								.init(
									pattern: .destructor([
										.named("a"): .value(.intLiteral(0)),
										.named("b"): .value(.intLiteral(0)),
									]),
									bindings: [:],
									guardExpression: .boolLiteral(true),
									body: .intLiteral(0)
								),
								.init(
									pattern: .destructor([
										.named("a"): .value(.intLiteral(0)),
										.named("b"): .binding(.named("b")),
									]),
									bindings: [:],
									guardExpression: .boolLiteral(true),
									body: .intLiteral(1)
								),
								.init(
									pattern: .destructor([
										.named("a"): .wildcard,
										.named("b"): .binding(.named("b")),
									]),
									bindings: [:],
									guardExpression: .boolLiteral(true),
									body: .intLiteral(2)
								),
								.init(
									pattern: .binding(.named("s")),
									bindings: [:],
									guardExpression: .boolLiteral(true),
									body: .intLiteral(3)
								),
							]),
							type: .int,
						)
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
				withExtension: "ppl"
			)!
			let source = try Syntax.Source(url: sourceURL)
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
