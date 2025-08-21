extension Syntax.QualifiedIdentifier: Hashable {
	public func hash(into hasher: inout Hasher) {
		hasher.combine(chain)
	}

	public static func == (
		lhs: Self,
		rhs: Self
	) -> Bool {
		lhs.chain == rhs.chain
	}
}
