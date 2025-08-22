import XCTest

@testable import Main

final class UnnamedArgumentsTests: XCTestCase {
	let filenNames:
		[String: (
			typeDeclarations: Semantic.TypeDeclarationsMap,
			expressionDefinitions: Semantic.FunctionDefinitionsMap
		)] = [
			"unnamedparams": (
				typeDeclarations: [
					.chain(["Pos"]): .raw(
						.record([
							.named("a"): .nominal(.chain(["Float"])),
							.named("b"): .nominal(.chain(["Bool"])),
							.unnamed(0): .nominal(.chain(["Int"])),
							.unnamed(1): .nominal(.chain(["Float"])),
						])
					)
				],
				expressionDefinitions: [:]
			)
		]

	func testFiles() throws {
		let bundle = Bundle.module
		let intrinsicDeclarations = Semantic.getIntrinsicDeclarations()

		for (name, reference) in filenNames {
			let sourceUrl = bundle.url(
				forResource: "analyzer_\(name)",
				withExtension: "ppl"
			)!

			let source = try Syntax.Source(url: sourceUrl)
			let module = TreeSitterModulParser.parseModule(source: source)
			let (typeDeclarations, typeLookup, _) =
				module.resolveTypeSymbols(
					contextTypeDeclarations: intrinsicDeclarations.typeDeclarations)
			let allTypeDeclarations = intrinsicDeclarations.typeDeclarations
				.merging(typeDeclarations) { $1 }

			let (
				functionDeclarations,
				functionBodyExpressions,
				_,
				_
			) = module.resolveFunctionSymbols(
				typeLookup: typeLookup,
				typeDeclarations: allTypeDeclarations,
				contextFunctionDeclarations: intrinsicDeclarations
					.functionDeclarations)

		}
	}
}
