extension Syntax.QualifiedIdentifier {
    func display() -> String {
        self.chain.joined(separator: "\\")
    }
}
