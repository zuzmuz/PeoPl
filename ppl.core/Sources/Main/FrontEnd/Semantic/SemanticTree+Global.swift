extension Semantic {
	static let IntId: Semantic.QualifiedIdentifier = .init(chain: ["Int"])
	static let FloatId: Semantic.QualifiedIdentifier = .init(chain: ["Float"])
	static let BoolId: Semantic.QualifiedIdentifier = .init(chain: ["Bool"])

	static let IntType: Semantic.Expression = .nominal(
		IntId,
		type: .type,
		kind: .compiletimeValue
	)
	static let FloatType: Semantic.Expression = .nominal(
		FloatId,
		type: .type,
		kind: .compiletimeValue
	)
	static let BoolType: Semantic.Expression = .nominal(
		BoolId,
		type: .type,
		kind: .compiletimeValue
	)

	static let globals: [Semantic.QualifiedIdentifier: Semantic.Expression] = [
		IntId: .type,
		FloatId: .type,
		BoolId: .type,
		.init(
			chain: [
				.operation(
					op: .plus, lhs: IntType, rhs: IntType)
			]):
			.operation(
				lhs: IntType, rhs: IntType,
				output: .nominal(IntId, type: .type, kind: .compiletimeValue)),
		.init(
			chain: [
				.operation(
					op: .plus, lhs: IntType, rhs: IntType)
			]):
			.operation(
				lhs: IntType, rhs: IntType,
				output: .nominal(IntId, type: .type, kind: .compiletimeValue)),
	]
}
