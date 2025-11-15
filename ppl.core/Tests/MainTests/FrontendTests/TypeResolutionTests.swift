#if ANALYZER
import XCTest

@testable import Main

final class TypeResolutionTests: XCTestCase {
	let fileNames:
		[String: (
			typeDeclarations: Semantic.TypeDeclarationsMap,
			typeErrors: [Semantic.Error]
		)] = [
			"goodtypes": (
				[
					.chain(["simple"]): .raw(
						.record([
							.named("a"): .nominal(.chain(["Int"])),
							.named("b"): .nominal(.chain(["Float"])),
						])
					),
					.chain(["enum"]): .raw(
						.choice([
							.named("first"): .nothing,
							.named("second"): .nothing,
							.named("third"): .nothing,
						])
					),
					.chain(["Shape"]): .raw(
						.choice([
							.named("circle"): .raw(
								.record([
									.named("radius"): .nominal(
										.chain(["Float"])
									)
								])
							),
							.named("rectangle"): .raw(
								.record([
									.named("width"): .nominal(
										.chain(["Float"])
									),
									.named("height"): .nominal(
										.chain(["Float"])
									),
								])
							),
							.named("triangle"): .raw(
								.record([
									.named("base"): .nominal(.chain(["Float"])),
									.named("height"): .nominal(
										.chain(["Float"])
									),
								])
							),
						])
					),
					.chain(["Point"]): .raw(
						.record([
							.unnamed(0): .nominal(.chain(["Float"])),
							.unnamed(1): .nominal(.chain(["Float"])),
						])
					),
					.chain(["Circle"]): .raw(
						.record([
							.named("center"): .nominal(.chain(["Point"])),
							.named("radius"): .nominal(.chain(["Float"])),
						])
					),
					.chain(["Rectangle"]): .raw(
						.record([
							.named("topLeft"): .nominal(.chain(["Point"])),
							.named("width"): .nominal(.chain(["Float"])),
							.named("height"): .nominal(.chain(["Float"])),
						])
					),
					.chain(["Triangle"]): .raw(
						.record([
							.named("pointA"): .nominal(.chain(["Point"])),
							.named("pointB"): .nominal(.chain(["Point"])),
							.named("pointC"): .nominal(.chain(["Point"])),
						])
					),
					.chain(["Geometry", "Shape"]): .raw(
						.choice([
							.named("circle"): .nominal(.chain(["Circle"])),
							.named("rectangle"): .nominal(
								.chain(["Rectangle"])
							),
							.named("triangle"): .nominal(.chain(["Triangle"])),
						])
					),
				],
				[]
			),
			"redeclared_types": (
				typeDeclarations: [
					.chain(["redeclared"]): .raw(
						.record([
							.unnamed(0): .nominal(.chain(["Int"])),
							.unnamed(1): .nominal(.chain(["Float"])),
							.unnamed(2): .nominal(.chain(["Bool"])),
						])
					),
					.chain(["declared"]): .raw(
						.record([
							.unnamed(0): .nominal(.chain(["redeclared"]))
						])
					),
				],
				typeErrors: [
					.init(
						location: .nowhere,
						errorChoice: .typeRedeclaration(
							identifier: .chain(["redeclared"]),
							otherLocations: [
								.nowhere,  // FIX: add correct locations
								.nowhere,
							]
						)
					),
					.init(
						location: .nowhere,
						errorChoice: .typeRedeclaration(
							identifier: .chain(["redeclared"]),
							otherLocations: [
								.nowhere,  // FIX: add correct locations
								.nowhere,
							]
						)
					),
				]
			),
			"cyclical_types": (
				typeDeclarations: [
					.chain(["A"]): .raw(
						.record([
							.unnamed(0): .nominal(.chain(["B"]))
						])
					),
					.chain(["B"]): .raw(
						.record([
							.unnamed(0): .nominal(.chain(["C"]))
						])
					),
					.chain(["C"]): .raw(
						.record([
							.unnamed(0): .nominal(.chain(["D"]))
						])
					),
					.chain(["D"]): .raw(
						.record([
							.named("a"): .raw(
								.record([
									.named("x"): .raw(
										.record([
											.unnamed(0): .nominal(.chain(["A"]))
										])
									)
								])
							)
						])
					),
				],
				typeErrors: [
					.init(
						location: .nowhere,
						errorChoice: .cyclicType(
							stack: [
								.init(
									identifier: .chain(["A"]),
									definition: .record([
										.untagged(
											typeSpecifier: .nominalType(
												.chain(["B"])
											)
										)
									])
								),
								.init(
									identifier: .chain(["B"]),
									definition: .record([
										.untagged(
											typeSpecifier: .nominalType(
												.chain(["C"])
											)
										)
									])
								),
								.init(
									identifier: .chain(["C"]),
									definition: .record([
										.untagged(
											typeSpecifier: .nominalType(
												.chain(["D"])
											)
										)
									])
								),
								.init(
									identifier: .chain(["D"]),
									definition: .record([
										.tagged(
											tag: "a",
											typeSpecifier: .record([
												.tagged(
													tag: "x",
													typeSpecifier: .record([
														.untagged(
															typeSpecifier:
																.nominalType(
																	.chain(["A"])
																)
														)
													])
												)
											])
										)
									])
								),
							]
						)
					),
					.init(
						location: .nowhere,
						errorChoice: .cyclicType(
							stack: [
								.init(
									identifier: .chain(["A"]),
									definition: .record([
										.untagged(
											typeSpecifier: .nominalType(
												.chain(["B"])
											)
										)
									])
								),
								.init(
									identifier: .chain(["B"]),
									definition: .record([
										.untagged(
											typeSpecifier: .nominalType(
												.chain(["C"])
											)
										)
									])
								),
								.init(
									identifier: .chain(["C"]),
									definition: .record([
										.untagged(
											typeSpecifier: .nominalType(
												.chain(["D"])
											)
										)
									])
								),
								.init(
									identifier: .chain(["D"]),
									definition: .record([
										.tagged(
											tag: "a",
											typeSpecifier: .record([
												.tagged(
													tag: "x",
													typeSpecifier: .record([
														.untagged(
															typeSpecifier:
																.nominalType(
																	.chain(["A"])
																)
														)
													])
												)
											])
										)
									])
								),
							]
						)
					),
					.init(
						location: .nowhere,
						errorChoice: .cyclicType(
							stack: [
								.init(
									identifier: .chain(["A"]),
									definition: .record([
										.untagged(
											typeSpecifier: .nominalType(
												.chain(["B"])
											)
										)
									])
								),
								.init(
									identifier: .chain(["B"]),
									definition: .record([
										.untagged(
											typeSpecifier: .nominalType(
												.chain(["C"])
											)
										)
									])
								),
								.init(
									identifier: .chain(["C"]),
									definition: .record([
										.untagged(
											typeSpecifier: .nominalType(
												.chain(["D"])
											)
										)
									])
								),
								.init(
									identifier: .chain(["D"]),
									definition: .record([
										.tagged(
											tag: "a",
											typeSpecifier: .record([
												.tagged(
													tag: "x",
													typeSpecifier: .record([
														.untagged(
															typeSpecifier:
																.nominalType(
																	.chain(["A"])
																)
														)
													])
												)
											])
										)
									])
								),
							]
						)
					),
					.init(
						location: .nowhere,
						errorChoice: .cyclicType(
							stack: [
								.init(
									identifier: .chain(["A"]),
									definition: .record([
										.untagged(
											typeSpecifier: .nominalType(
												.chain(["B"])
											)
										)
									])
								),
								.init(
									identifier: .chain(["B"]),
									definition: .record([
										.untagged(
											typeSpecifier: .nominalType(
												.chain(["C"])
											)
										)
									])
								),
								.init(
									identifier: .chain(["C"]),
									definition: .record([
										.untagged(
											typeSpecifier: .nominalType(
												.chain(["D"])
											)
										)
									])
								),
								.init(
									identifier: .chain(["D"]),
									definition: .record([
										.tagged(
											tag: "a",
											typeSpecifier: .record([
												.tagged(
													tag: "x",
													typeSpecifier: .record([
														.untagged(
															typeSpecifier:
																.nominalType(
																	.chain(["A"])
																)
														)
													])
												)
											])
										)
									])
								),
							]
						)
					),
				]
			),
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
			let (typeDeclarations, _, typeErrors) =
				module.resolveTypeSymbols(
					contextTypeDeclarations: intrinsicDeclarations
						.typeDeclarations
				)
			XCTAssertEqual(typeErrors.count, reference.typeErrors.count)
			zip(
				typeErrors.sorted { $0.location < $1.location },
				reference.typeErrors
			).forEach {
				$0.assertEqual(with: $1)
			}
			XCTAssertEqual(
				typeDeclarations.count,
				reference.typeDeclarations.count
			)
			for (identifier, typeSpecifier) in typeDeclarations {
				XCTAssertNotNil(reference.typeDeclarations[identifier])
				if let referenceTypeSpecifier =
					reference.typeDeclarations[identifier]
				{
					XCTAssertEqual(typeSpecifier, referenceTypeSpecifier)
				}
			}
		}
	}
}
#endif
