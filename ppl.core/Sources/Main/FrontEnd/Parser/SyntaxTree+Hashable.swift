extension Syntax.QualifiedIdentifier: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.chain)
    }

    public static func == (
        lhs: Self,
        rhs: Self
    ) -> Bool {
        lhs.chain == rhs.chain
    }
}
