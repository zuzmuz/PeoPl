
extension Syntax.Definition: Hashable {
    func hash(into hasher: inout Hasher) {
        switch self {
        case let .typeDefinition(typeDefinition):
            hasher.combine(typeDefinition)
        case let .valueDefinition(valueDefinition):
            hasher.combine(valueDefinition)
        }
    }
    static func == (
        lhs: Syntax.Definition,
        rhs: Syntax.Definition
    ) -> Bool {
        switch (lhs, rhs) {
        case let (.typeDefinition(lhs), .typeDefinition(rhs)):
            return lhs == rhs
        case let (.valueDefinition(lhs), .valueDefinition(rhs)):
            return lhs == rhs
        default:
            return false
        }
    }
}

extension Syntax.TypeDefinition: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.identifier)
    }
    
    static func == (
        lhs: Syntax.TypeDefinition,
        rhs: Syntax.TypeDefinition
    ) -> Bool {
        lhs.identifier == rhs.identifier
    }
}

extension Syntax.ScopedIdentifier: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.chain)
    }

    static func == (
        lhs: Syntax.ScopedIdentifier,
        rhs: Syntax.ScopedIdentifier
    ) -> Bool {
        lhs.chain == rhs.chain
    }
}

extension Syntax.ValueDefinition: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.identifier)
        // NOTE: not allowing for function overloading
    }

    static func == (
        lhs: Syntax.ValueDefinition,
        rhs: Syntax.ValueDefinition
    ) -> Bool {
        lhs.identifier == rhs.identifier
    }
}
