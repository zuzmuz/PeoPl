import XCTest

@testable import Main

final class SemanticTests: XCTestCase {

	let fileNames: [(String, String)] = [
		("one", "true"),
		// Add more test files as needed
	]

	func testFiles() throws {
		let bundle = Bundle.module

		for (name, reference) in fileNames {
			let sourceUrl = bundle.url(
				forResource: "semantic_\(name)",
				withExtension: "ppl"
			)!
			let source = try Syntax.Source(url: sourceUrl)
			let module = TreeSitterModulParser.parseModule(source: source)

			let expressions = module.resolveExpressions(
				scope: .init(chain: ["one"]),
				context: Semantic.globals
			)
			print(expressions.errors)
			print(expressions.context.debugDisplay)
		}
	}
}
