import XCTest

@testable import Main

// MARK: - Testable Protocol

extension Syntax.Module: Testable {
	func assertEqual(
		with: Self
	) {
		XCTAssertEqual(
			definitions.count,
			with.definitions.count,
			"Module \(sourceName) definition counts do not match"
		)
		zip(definitions, with.definitions).forEach {
			$0.assertEqual(with: $1)
		}
	}
}

extension Syntax.Definition: Testable {
	func assertEqual(
		with: Self
	) {
		XCTAssertEqual(
			identifier,
			with.identifier,
			"Type definition identifier \(identifier) does not match \(with.identifier)"
		)

		if let withTypeSpecifier = with.typeSpecifier {
			XCTAssertNotNil(typeSpecifier)
			if let typeSpecifier = typeSpecifier {
				typeSpecifier.assertEqual(with: withTypeSpecifier)
			}
		}

		definition.assertEqual(with: with.definition)
	}
}

extension Syntax.Expression: Testable {
	func assertEqual(
		with: Self
	) {
		switch (self, with) {
		case (.literal(let lhs), .literal(let rhs)):
			lhs.assertEqual(with: rhs)
		case (.unary(let lhs), .unary(let rhs)):
			lhs.assertEqual(with: rhs)
		case (.binary(let lhs), .binary(let rhs)):
			lhs.assertEqual(with: rhs)
		case (.nominal(let lhs), .nominal(let rhs)):
			XCTAssertEqual(lhs, rhs)
		case (.typeDefinition(let lhs), .typeDefinition(let rhs)):
			lhs.assertEqual(with: rhs)
		case (.function(let lhs), .function(let rhs)):
			lhs.assertEqual(with: rhs)
		case (.call(let lhs), .call(let rhs)):
			lhs.assertEqual(with: rhs)
		case (.access(let lhs), .access(let rhs)):
			lhs.assertEqual(with: rhs)
		case (.binding(let lhs), .binding(let rhs)):
			lhs.assertEqual(with: rhs)
		case (.taggedExpression(let lhs), .taggedExpression(let rhs)):
			lhs.assertEqual(with: rhs)
		case (.branched(let lhs), .branched(let rhs)):
			lhs.assertEqual(with: rhs)
		case (.piped(let lhs), .piped(let rhs)):
			lhs.assertEqual(with: rhs)
		default:
			XCTFail("Expressions \(self) do not match \(with)")
		}
	}
}

extension Syntax.Literal: Testable {
	func assertEqual(
		with: Self
	) {
		XCTAssertEqual(value, with.value)
	}
}

extension Syntax.Unary: Testable {
	func assertEqual(
		with: Self
	) {
		XCTAssertEqual(op, with.op)
		expression.assertEqual(with: with.expression)
	}
}

extension Syntax.Binary: Testable {
	func assertEqual(
		with: Self
	) {
		XCTAssertEqual(op, with.op)
		left.assertEqual(with: with.left)
		right.assertEqual(with: with.right)
	}
}

extension Syntax.Function: Testable {
	func assertEqual(
		with: Self
	) {
		if let withSignature = with.signature {
			XCTAssertNotNil(signature)
			if let signature = signature {
				signature.assertEqual(with: withSignature)
			}
		} else {
			XCTAssertNil(signature)
		}
		body.assertEqual(with: with.body)
	}
}

extension Syntax.TypeDefinition: Testable {
	func assertEqual(with: Syntax.TypeDefinition) {
		zip(self.expressions, with.expressions).forEach {
			$0.assertEqual(with: $1)
		}
	}
}

extension Syntax.FunctionType: Testable {
	func assertEqual(
		with: Self
	) {
		if let withInputType = with.inputType {
			XCTAssertNotNil(inputType)
			if let inputType = inputType {
				inputType.assertEqual(with: withInputType)
			}
		} else {
			XCTAssertNil(inputType)
		}

		XCTAssertEqual(arguments.count, with.arguments.count)

		zip(arguments, with.arguments).forEach {
			$0.assertEqual(with: $1)
		}

		outputType.assertEqual(with: with.outputType)
	}
}

extension Syntax.Call: Testable {
	func assertEqual(
		with: Self
	) {
		if let selfPrefix = prefix {
			XCTAssertNotNil(with.prefix)
			if let withPrefix = with.prefix {
				selfPrefix.assertEqual(with: withPrefix)
			}
		} else {
			XCTAssertNil(with.prefix)
		}

		XCTAssertEqual(
			arguments.count,
			with.arguments.count,
			"Call expression arguments mismatch")

		zip(arguments, with.arguments).forEach {
			$0.assertEqual(with: $1)
		}
	}
}

extension Syntax.Access: Testable {
	func assertEqual(
		with: Self
	) {
		prefix.assertEqual(with: with.prefix)
		XCTAssertEqual(field, with.field)
	}
}

extension Syntax.Binding: Testable {
	func assertEqual(
		with: Self
	) {
		XCTAssertEqual(identifier, with.identifier)
	}
}

extension Syntax.TaggedExpression: Testable {
	func assertEqual(
		with: Self
	) {
		XCTAssertEqual(tag, with.tag)
		expression.assertEqual(with: with.expression)
	}
}

extension Syntax.Branched: Testable {
	func assertEqual(
		with: Self
	) {
		XCTAssertEqual(branches.count, with.branches.count)
		zip(branches, with.branches).forEach {
			$0.assertEqual(with: $1)
		}
	}
}

extension Syntax.Branched.Branch: Testable {
	func assertEqual(
		with: Self
	) {
		matchExpression.assertEqual(with: with.matchExpression)

		if let withGuardExpression = with.guardExpression {
			XCTAssertNotNil(guardExpression)
			if let guardExpression = guardExpression {
				guardExpression.assertEqual(with: withGuardExpression)
			}
		} else {
			XCTAssertNil(guardExpression)
		}

		body.assertEqual(with: with.body)
	}
}

extension Syntax.Pipe: Testable {
	func assertEqual(
		with: Self
	) {
		left.assertEqual(with: with.left)
		right.assertEqual(with: with.right)
	}
}

// MARK: - Syntax Util Extensions

extension Syntax.QualifiedIdentifier {
	static func chain(
		_ components: [String]
	) -> Syntax.QualifiedIdentifier {
		return .init(chain: components)
	}
}

extension Syntax.Expression {
	static let nothing: Syntax.Expression = .literal(.init(value: .nothing))
	static func intLiteral(_ value: UInt64) -> Syntax.Expression {
		return .literal(.init(value: .intLiteral(value)))
	}

	static func floatLiteral(_ value: Double) -> Syntax.Expression {
		return .literal(.init(value: .floatLiteral(value)))
	}

	static func stringLiteral(_ value: String) -> Syntax.Expression {
		return .literal(.init(value: .stringLiteral(value)))
	}

	static func unary(
		_ op: Operator,
		_ expression: Syntax.Expression
	) -> Syntax.Expression {
		return .unary(.init(op: op, expression: expression))
	}

	static func binary(
		_ lhs: Syntax.Expression,
		_ op: Operator,
		_ rhs: Syntax.Expression
	) -> Syntax.Expression {
		return .binary(
			.init(op: op, left: lhs, right: rhs)
		)
	}

	static func typeDefinition(
		_ expressions: [Syntax.Expression]
	) -> Syntax.Expression {
		return .typeDefinition(.init(expressions: expressions))
	}

	static func call(
		_ identifier: Syntax.QualifiedIdentifier,
		_ arguments: [Syntax.Expression] = []
	) -> Syntax.Expression {
		return .call(
			.init(
				prefix: .nominal(identifier),
				arguments: arguments
			)
		)
	}

	static func squareCall(
		_ identifier: Syntax.QualifiedIdentifier,
		_ arguments: [Syntax.Expression] = []
	) -> Syntax.Expression {
		return .call(
			identifier,
			[
				.typeDefinition(arguments)
			]
		)
	}

	static func call(
		_ prefix: Syntax.Expression,
		_ arguments: [Syntax.Expression] = []
	) -> Syntax.Expression {
		return .call(
			.init(prefix: prefix, arguments: arguments)
		)
	}

	static func access(
		_ identifier: Syntax.QualifiedIdentifier,
		_ field: String
	) -> Syntax.Expression {
		return .access(
			.init(prefix: .nominal(identifier), field: field)
		)
	}

	static func access(
		_ prefix: Syntax.Expression,
		_ field: String
	) -> Syntax.Expression {
		return .access(
			.init(prefix: prefix, field: field)
		)
	}

	static func pipe(
		_ left: Syntax.Expression,
		_ right: Syntax.Expression,
	) -> Syntax.Expression {
		return .piped(
			.init(
				left: left,
				right: right
			)
		)
	}

	static func branched(
		_ branches: [Syntax.Branched.Branch]
	) -> Syntax.Expression {
		return .branched(
			.init(branches: branches)
		)
	}

	static func tagged(
		_ tag: String,
		_ expression: Syntax.Expression,
		_ typeSpecifier: Syntax.Expression? = nil
	) -> Syntax.Expression {
		return .taggedExpression(
			.init(
				identifier: tag,
				typeSpecifier: typeSpecifier,
				expression: expression)
		)
	}
}

// swiftlint:disable:next type_body_length
final class ParserTests: XCTestCase {
	let fileNames: [String: Syntax.Module] = [
		"types": .init(
			sourceName: "types",
			definitions: [
				.init(
					identifier: .chain(["Basic"]),
					definition: .typeDefinition([
						.tagged("a", .nominal(.chain(["Int"])))
					])
				),
				.init(
					identifier: .chain(["Multiple"]),
					definition: .typeDefinition([
						.tagged("a", .nominal(.chain(["Int"]))),
						.tagged("b", .nominal(.chain(["Float"]))),
						.tagged("c", .nominal(.chain(["String"]))),
					])
				),
				.init(
					identifier: .chain(["Nested"]),
					definition: .typeDefinition([
						.tagged("a", .nominal(.chain(["Int"]))),
						.tagged(
							"d",
							.typeDefinition([
								.tagged("b", .nominal(.chain(["Float"]))),
								.tagged(
									"e",
									.typeDefinition([
										.tagged("c", .nominal(.chain(["String"])))
									])
								),
							])
						),
					])
				),
				.init(
					identifier: .chain(["Scoped", "Basic"]),
					definition: .typeDefinition([
						.tagged("a", .nominal(.chain(["Int"])))
					])
				),
				.init(
					identifier: .chain(["Scoped", "Multiple", "Times"]),
					definition: .typeDefinition([
						.tagged("a", .nominal(.chain(["Int"]))),
						.tagged("e", .nominal(.chain(["Bool"]))),
					])
				),
				.init(
					identifier: .chain(["ScopedTypes"]),
					definition: .typeDefinition([
						.tagged("x", .nominal(.chain(["CG", "Float"]))),
						.tagged("y", .nominal(.chain(["CG", "Vector"]))),
					])
				),
				.init(
					identifier: .chain(["TypeWithNothing"]),
					definition: .typeDefinition([
						.tagged("m", .nothing),
						.tagged("n", .nothing),
					])
				),
				.init(
					identifier: .chain(["Numbered"]),
					definition: .typeDefinition([
						.tagged("_1", .nominal(.chain(["One"]))),
						.tagged("_2", .nominal(.chain(["Two"]))),
						.tagged("_3", .nominal(.chain(["Three"]))),
					])
				),
				.init(
					identifier: .chain(["Tuple"]),
					definition: .typeDefinition([
						.nominal(.chain(["Int"])),
						.nominal(.chain(["Float"])),
						.nominal(.chain(["String"])),
						.nominal(.chain(["Bool"])),
						.nominal(.chain(["Nested", "Scope"])),
						.nominal(
							.chain([
								"Multiple",
								"Nested",
								"Scope",
							])
						),
					])
				),
				.init(
					identifier: .chain(["Mix"]),
					definition: .typeDefinition([
						.nominal(.chain(["Int"])),
						.tagged("named", .nominal(.chain(["Int"]))),
						.nominal(.chain(["Float"])),
						.tagged("other", .nominal(.chain(["Float"]))),
					])
				),
				.init(
					identifier: .chain(["Choice"]),
					definition: .squareCall(
						.chain(["choice"]),
						[
							.tagged("first", .nothing),
							.tagged("second", .nothing),
							.tagged("third", .nothing),
						]
					)
				),
				.init(
					identifier: .chain(["Shape"]),
					definition: .squareCall(
						.chain(["choice"]),
						[
							.tagged(
								"circle",
								.typeDefinition([
									.tagged("radius", .nominal(.chain(["Float"])))
								])
							),
							.tagged(
								"rectangle",
								.typeDefinition([
									.tagged("width", .nominal(.chain(["Float"]))),
									.tagged("height", .nominal(.chain(["Float"]))),
								])
							),
							.tagged(
								"triangle",
								.typeDefinition([
									.tagged("base", .nominal(.chain(["Float"]))),
									.tagged("height", .nominal(.chain(["Float"]))),
								])
							),
						]
					)
				),
				.init(
					identifier: .chain(["Graphix", "Color"]),
					definition: .squareCall(
						.chain(["choice"]),
						[
							.tagged(
								"rgb",
								.typeDefinition([
									.tagged("red", .nominal(.chain(["Float"]))),
									.tagged("green", .nominal(.chain(["Float"]))),
									.tagged("blue", .nominal(.chain(["Float"]))),
								])),
							.tagged(
								"named", .nominal(.chain(["Graphix", "ColorName"]))),
							.tagged(
								"hsv",
								.typeDefinition([
									.tagged("hue", .nominal(.chain(["Float"]))),
									.tagged(
										"saturation", .nominal(.chain(["Float"]))),
									.tagged("value", .nominal(.chain(["Float"]))),
								])
							),
						]
					)
				),
				.init(
					identifier: .chain(["Union"]),
					definition: .squareCall(
						.chain(["choice"]),
						[
							.nominal(.chain(["Int"])),
							.nominal(
								.chain(["Float"])
							),
							.nominal(
								.chain(["String"])
							),
						]
					)
				),
				.init(
					identifier: .chain(["Nested", "Stuff"]),
					definition: .typeDefinition([
						.tagged(
							"first",
							.squareCall(
								.chain(["choice"]),
								[
									.nominal(.chain(["A"])),
									.nominal(.chain(["B"])),
									.nominal(.chain(["C"])),
								]
							)
						),
						.tagged(
							"second",
							.squareCall(
								.chain(["choice"]),
								[
									.tagged("a", .nothing),
									.tagged("b", .nothing),
									.tagged("c", .nothing),
								]
							)
						),
						.tagged(
							"mix",
							.squareCall(
								.chain(["choice"]),
								[
									.nominal(.chain(["First"])),
									.tagged("second", .nominal(.chain(["Second"]))),
									.tagged(
										"third",
										.call(
											.chain(["choice"]),
											[
												.typeDefinition([
													.tagged("_1", .nothing),
													.tagged("_2", .nothing),
													.tagged("_3", .nothing),
												])
											]
										)
									),
								]
							)
						),
					])
				),
			]
		),
		"expressions": .init(
			sourceName: "expressions",
			definitions: [
				.init(identifier: .chain(["well"]), definition: .nothing),
				.init(
					identifier: .chain(["hello"]),
					definition: .stringLiteral("Hello, World!"),
				),
				.init(
					identifier: .chain(["arithmetics"]),
					definition: .binary(
						.binary(
							.binary(
								.binary(
									.intLiteral(1),
									.plus,
									.binary(
										.intLiteral(20),
										.times,
										.binary(
											.intLiteral(5),
											.minus,
											.intLiteral(2),
										)
									)
								),
								.minus,
								.binary(
									.binary(
										.intLiteral(3),
										.by,
										.intLiteral(1)
									),
									.times,
									.intLiteral(3)
								)
							),
							.plus,
							.binary(
								.intLiteral(10),
								.modulo,
								.intLiteral(3)
							)
						),
						.minus,
						.intLiteral(10)
					)
				),
				.init(
					identifier: .chain(["hexOctBin"]),
					definition: .binary(
						.binary(
							.intLiteral(255),
							.plus,
							.binary(
								.intLiteral(240),
								.times,
								.intLiteral(7)
							)
						),
						.minus,
						.intLiteral(56400)
					)
				),
				.init(
					identifier: .chain(["big_numbers"]),
					definition: .intLiteral(1_000_000_000),
				),
				.init(
					identifier: .chain(["floating"]),
					definition: .binary(
						.floatLiteral(1.0),
						.plus,
						.binary(
							.binary(
								.floatLiteral(2.5),
								.times,
								.binary(
									.floatLiteral(3.14),
									.minus,
									.floatLiteral(1.0)
								)
							),
							.by,
							.floatLiteral(2.0)
						)
					)
				),
				.init(
					identifier: .chain(["prefix"]),
					definition: .binary(
						.intLiteral(1),
						.minus,
						.unary(
							.plus,
							.unary(
								.minus,
								.intLiteral(5)
							)
						)
					)
				),
				.init(
					identifier: .chain(["conditions"]),
					definition: .binary(
						.binary(
							.nominal(.chain(["you"])),
							.and,
							.nominal(.chain(["me"])),
						),
						.or,
						.nothing
					)
				),
				.init(
					identifier: .chain(["complex", "Conditions"]),
					definition: .binary(
						.binary(
							.binary(
								.binary(
									.intLiteral(1),
									.plus,
									.intLiteral(3),
								),
								.times,
								.intLiteral(3),
							),
							.greaterThan,
							.intLiteral(42),
						),
						.or,
						.binary(
							.nominal(.chain(["something"])),
							.and,
							.binary(
								.binary(
									.stringLiteral("this"),
									.equal,
									.stringLiteral("that"),
								),
								.or,
								.unary(
									.not,
									.call(.chain(["theSame"]))
								)
							)
						),
					)
				),
				.init(
					identifier: .chain(["What", "are", "the", "Odds"]),
					definition: .pipe(
						.pipe(
							.call(
								.chain(["Object"]),
								[
									.tagged("a", .intLiteral(1)),
									.tagged("b", .intLiteral(2)),
									.tagged("c", .intLiteral(3)),
								],
							),
							.call(
								.chain(["a", "b", "c"]),
								[
									.binary(
										.intLiteral(1),
										.plus,
										.intLiteral(1)
									),
									.binary(
										.intLiteral(2),
										.times,
										.intLiteral(2)
									),
									.binary(
										.nominal(.chain(["b"])),
										.or,
										.call(
											.chain(["x"])
										)
									),
								]
							)
						),
						.branched([
							.init(
								matchExpression: .nominal(.chain(["a"])),
								body: .binary(
									.binary(
										.access(.chain(["a"]), "a"),
										.plus,
										.access(.chain(["a"]), "b")
									),
									.plus,
									.access(.chain(["a"]), "c")
								)
							),
							.init(
								matchExpression: .nominal(.chain(["z", "z"])),
								body: .access(
									.access(.access(.chain(["z"]), "z"), "z"),
									"z"
								)
							),
							.init(
								matchExpression: .binding(
									.init(identifier: "call")
								),
								body: .call(
									.chain(["call"]),
									[
										.pipe(
											.nominal(.chain(["a"])),
											.nominal(.chain(["b"]))
										),
										.tagged(
											"x",
											.pipe(
												.nominal(.chain(["a"])),
												.nominal(.chain(["b"]))
											),
										),
										.tagged(
											"y",
											.pipe(
												.access(
													.chain(["a"]),
													"b"
												),
												.access(
													.chain(["q", "a"]),
													"b"
												)
											)
										),
									]
								)
							),
						])
					)
				),
			]
		),
		// "errors": .init(
		//     sourceName: "errors", definitions: [])
	]

	func testFiles() throws {
		let bundle = Bundle.module

		for (name, reference) in fileNames {
			let sourceUrl = bundle.url(
				forResource: "parser_\(name)",
				withExtension: "ppl"
			)!
			let source = try Syntax.Source(url: sourceUrl)
			let module = TreeSitterModulParser.parseModule(source: source)
			print("The syntax errors: \(module.syntaxErrors)")
			module.assertEqual(with: reference)
		}
	}
}
