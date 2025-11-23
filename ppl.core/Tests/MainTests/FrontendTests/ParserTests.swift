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
		case (.lambda(let lhs), .lambda(let rhs)):
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

extension Syntax.TypeDefinition: Testable {
	func assertEqual(with: Syntax.TypeDefinition) {
		zip(self.expressions, with.expressions).forEach {
			$0.assertEqual(with: $1)
		}
	}
}

extension Syntax.Function: Testable {
	func assertEqual(
		with: Self
	) {
		if let withInput = with.input {
			XCTAssertNotNil(input)
			if let input {
				input.assertEqual(with: withInput)
			}
		} else {
			XCTAssertNil(input)
		}

		XCTAssertEqual(arguments.count, with.arguments.count)

		zip(arguments, with.arguments).forEach {
			$0.assertEqual(with: $1)
		}

		output.assertEqual(with: with.output)
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

extension Syntax.Lambda: Testable {
	func assertEqual(
		with: Self
	) {
		if let prefix {
			XCTAssertNotNil(with.prefix)
			if let withPrefix = with.prefix {
				prefix.assertEqual(with: withPrefix)
			}
		} else {
			XCTAssertNil(with.prefix)
		}

		self.body.assertEqual(with: with.body)
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
				tag: .init(chain: [tag]),
				typeSpecifier: typeSpecifier,
				expression: expression)
		)
	}

	static func tagged(
		_ tag: Syntax.QualifiedIdentifier,
		_ expression: Syntax.Expression,
		_ typeSpecifier: Syntax.Expression? = nil
	) -> Syntax.Expression {
		return .taggedExpression(
			.init(
				tag: tag,
				typeSpecifier: typeSpecifier,
				expression: expression)
		)
	}

	static func lambda(
		_ prefix: Syntax.Expression,
		_ body: Syntax.Expression
	) -> Syntax.Expression {
		return .lambda(
			.init(prefix: prefix, body: body)
		)
	}

	static func lambda(
		_ body: Syntax.Expression
	) -> Syntax.Expression {
		return .lambda(
			.init(prefix: nil, body: body)
		)
	}
}

// swiftlint:disable:next type_body_length
final class ParserTests: XCTestCase {
	let fileNames: [String: Syntax.Module] = [
		"types": .init(
			sourceName: "types",
			definitions: [
				.tagged(
					"Basic",
					.typeDefinition([
						.tagged("a", .nominal(.chain(["Int"])))
					])),
				.tagged(
					"Multiple",
					.typeDefinition([
						.tagged("a", .nominal(.chain(["Int"]))),
						.tagged("b", .nominal(.chain(["Float"]))),
						.tagged("c", .nominal(.chain(["String"]))),
					])),
				.tagged(
					"Nested",
					.typeDefinition([
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
				.tagged(
					.chain(["Scoped", "Basic"]),
					.typeDefinition([
						.tagged("a", .nominal(.chain(["Int"])))
					])
				),
				.tagged(
					.chain(["Scoped", "Multiple", "Times"]),
					.typeDefinition([
						.tagged("a", .nominal(.chain(["Int"]))),
						.tagged("e", .nominal(.chain(["Bool"]))),
					])
				),
				.tagged(
					.chain(["ScopedTypes"]),
					.typeDefinition([
						.tagged("x", .nominal(.chain(["CG", "Float"]))),
						.tagged("y", .nominal(.chain(["CG", "Vector"]))),
					])
				),
				.tagged(
					.chain(["TypeWithNothing"]),
					.typeDefinition([
						.tagged("m", .nothing),
						.tagged("n", .nothing),
					])
				),
				.tagged(
					.chain(["Numbered"]),
					.typeDefinition([
						.tagged("_1", .nominal(.chain(["One"]))),
						.tagged("_2", .nominal(.chain(["Two"]))),
						.tagged("_3", .nominal(.chain(["Three"]))),
					])
				),
				.tagged(
					.chain(["Tuple"]),
					.typeDefinition([
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
				.tagged(
					.chain(["Mix"]),
					.typeDefinition([
						.nominal(.chain(["Int"])),
						.tagged("named", .nominal(.chain(["Int"]))),
						.nominal(.chain(["Float"])),
						.tagged("other", .nominal(.chain(["Float"]))),
					])
				),
				.tagged(
					.chain(["Choice"]),
					.squareCall(
						.chain(["choice"]),
						[
							.tagged("first", .nothing),
							.tagged("second", .nothing),
							.tagged("third", .nothing),
						]
					)
				),
				.tagged(
					.chain(["Shape"]),
					.squareCall(
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
				.tagged(
					.chain(["Graphix", "Color"]),
					.squareCall(
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
				.tagged(
					.chain(["Union"]),
					.squareCall(
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
				.tagged(
					.chain(["Nested", "Stuff"]),
					.typeDefinition([
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
				.tagged("well", .nothing),
				.tagged(
					"hello",
					.stringLiteral("Hello, World!"),
				),
				.tagged(
					"arithmetics",
					.binary(
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
				.tagged(
					"hexOctBin",
					.binary(
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
				.tagged(
					"big_numbers",
					.intLiteral(1_000_000_000),
				),
				.tagged(
					"floating",
					.binary(
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
				.tagged(
					"prefix",
					.binary(
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
				.tagged(
					"conditions",
					.binary(
						.binary(
							.nominal(.chain(["you"])),
							.and,
							.nominal(.chain(["me"])),
						),
						.or,
						.nothing
					)
				),
				.tagged(
					.chain(["complex", "Conditions"]),
					.binary(
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
				.tagged(
					.chain(["What", "are", "the", "Odds"]),
					.lambda(
						.pipe(
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
			module.assertEqual(with: reference)
		}
	}
}
