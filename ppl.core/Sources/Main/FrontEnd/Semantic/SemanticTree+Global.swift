extension Semantic {
	static let IntId: Semantic.QualifiedIdentifier = .init(chain: ["Int"])
	static let FloatId: Semantic.QualifiedIdentifier = .init(chain: ["Float"])
	static let BoolId: Semantic.QualifiedIdentifier = .init(chain: ["Bool"])

	static let globals: Semantic.Context = [
		IntId: .type,
		FloatId: .type,
		BoolId: .type,
		.init(chain: ["#+(Int,Int)"]): .operation(
			lhs: .nominal(IntId, type: .type, kind: .compiletimeValue),
			rhs: .nominal(IntId, type: .type, kind: .compiletimeValue),
			output: .nominal(IntId, type: .type, kind: .compiletimeValue)),
		.init(chain: ["#-(Int,Int)"]): .operation(
			lhs: .nominal(IntId, type: .type, kind: .compiletimeValue),
			rhs: .nominal(IntId, type: .type, kind: .compiletimeValue),
			output: .nominal(IntId, type: .type, kind: .compiletimeValue)),
		.init(chain: ["#+(Int)"]): .operation(
			lhs: .nominal(IntId, type: .type, kind: .compiletimeValue),
			rhs: .nominal(IntId, type: .type, kind: .compiletimeValue),
			output: .nominal(IntId, type: .type, kind: .compiletimeValue)),
		.init(chain: ["#-(Int)"]): .operation(
			lhs: .nominal(IntId, type: .type, kind: .compiletimeValue),
			rhs: .nominal(IntId, type: .type, kind: .compiletimeValue),
			output: .nominal(IntId, type: .type, kind: .compiletimeValue)),
	]
}
