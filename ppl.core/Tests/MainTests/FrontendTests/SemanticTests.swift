import XCTest

@testable import Main

final class SemanticTests: XCTestCase {

	let fileNames: [(String, String)] = [
		("example1.ppl", "example1_reference.txt"),
		("example2.ppl", "example2_reference.txt"),
		// Add more test files as needed
	]

	func testFiles() throws {
		let bundle = Bundle.module

		// for (name, reference) in fileNames {
		// 	let sourceUrl = bundle.url(
		// 		forResource: "semantic_\(name)",
		// 		withExtension: "ppl"
		// 	)!
		// 	let source = try Syntax.Source(url: sourceUrl)
		// 	let module = TreeSitterModulParser.parseModule(source: source)
		//
		// }
	}
}
