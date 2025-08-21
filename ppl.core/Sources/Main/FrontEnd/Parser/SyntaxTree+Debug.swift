extension Syntax.QualifiedIdentifier {
	func display() -> String {
		chain.joined(separator: "\\")
	}
}
