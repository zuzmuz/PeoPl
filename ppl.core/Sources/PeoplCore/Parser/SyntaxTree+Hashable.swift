
extension Syntax.ParamDefinition: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.name)
        hasher.combine(self.type)
    }

    static func == (lhs: Syntax.ParamDefinition, rhs: Syntax.ParamDefinition) -> Bool {
        lhs.name == rhs.name &&
        lhs.type == rhs.type
    }
}

extension Syntax.TypeDefinition: Hashable {
    func hash(into hasher: inout Hasher) {
        switch self {
        case let .simple(simple):
            hasher.combine(simple)
        case let .sum(sum):
            hasher.combine(sum)
        }
    }
    static func == (lhs: Syntax.TypeDefinition, rhs: Syntax.TypeDefinition) -> Bool {
        switch (lhs, rhs) {
        case let (.simple(lhs), .simple(rhs)):
            return lhs == rhs
        case let (.sum(lhs), .sum(rhs)):
            return lhs == rhs
        default:
            return false
        }
    }
}

extension Syntax.TypeDefinition.Simple: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.identifier)
    }

    static func == (lhs: Syntax.TypeDefinition.Simple, rhs: Syntax.TypeDefinition.Simple) -> Bool {
        lhs.identifier == rhs.identifier
    }
}

extension Syntax.TypeDefinition.Sum: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.identifier)
    }

    static func == (lhs: Syntax.TypeDefinition.Sum, rhs: Syntax.TypeDefinition.Sum) -> Bool {
        lhs.identifier == rhs.identifier
    }
}

extension Syntax.FunctionIdentifier: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.name)
        hasher.combine(self.scope)
    }
    static func == (lhs: Syntax.FunctionIdentifier, rhs: Syntax.FunctionIdentifier) -> Bool {
        lhs.name == rhs.name && lhs.scope == rhs.scope
    }
}

extension Syntax.FunctionDefinition: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.inputType)
        hasher.combine(self.functionIdentifier)
        hasher.combine(self.params)
    }

    static func == (lhs: Syntax.FunctionDefinition, rhs: Syntax.FunctionDefinition) -> Bool {
        lhs.inputType == rhs.inputType &&
        lhs.functionIdentifier == rhs.functionIdentifier &&
        lhs.params == rhs.params
    }
}

extension Syntax.OperatorOverloadDefinition: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.left)
        hasher.combine(self.op)
        hasher.combine(self.right)
    }

    static func == (lhs: Syntax.OperatorOverloadDefinition, rhs: Syntax.OperatorOverloadDefinition) -> Bool {
        lhs.left == rhs.left &&
        lhs.op == rhs.op &&
        lhs.right == rhs.right
    }
}

extension Syntax.TypeIdentifier: Hashable {
    func hash(into hasher: inout Hasher) {
        switch self {
        case .nothing:
            hasher.combine("nothing")
        case .never:
            hasher.combine("never")
        case let .nominal(nominal):
            hasher.combine(nominal)
        case let .lambda(lambda):
            hasher.combine(lambda)
        case let .unnamedTuple(tuple):
            hasher.combine(tuple)
        case let .namedTuple(tuple):
            hasher.combine(tuple)
        case let .union(union):
            hasher.combine(union)
        }
    }

    static func == (lhs: Syntax.TypeIdentifier, rhs: Syntax.TypeIdentifier) -> Bool {
        switch (lhs, rhs) {
        case (.nothing, .nothing):
            return true
        case (.never, .never):
            return true
        // TODO: it would be interesting if structural types can be equal to structural ones
        case let (.nominal(lhs), .nominal(rhs)):
            return lhs == rhs
        case let (.lambda(lhs), .lambda(rhs)):
            return lhs == rhs
        case let (.unnamedTuple(lhs), .unnamedTuple(rhs)):
            return lhs == rhs
        case let (.namedTuple(lhs), .namedTuple(rhs)):
            return lhs == rhs
        case let (.union(lhs), .union(rhs)):
            return lhs == rhs
        default:
            return false
        }
    }
}

extension Syntax.FlatNominalType: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.typeName)
        // hasher.combine(self.typeArguments)
        // TODO: should consider how type arguments would work with this
    }

    static func == (lhs: Syntax.FlatNominalType, rhs: Syntax.FlatNominalType) -> Bool {
        lhs.typeName == rhs.typeName // && lhs.typeArguments == rhs.typeArguments
    }
}

extension Syntax.NominalType: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.chain)
    }
    static func == (lhs: Syntax.NominalType, rhs: Syntax.NominalType) -> Bool {
        lhs.chain == rhs.chain
    }
}

extension Syntax.StructuralType.Lambda: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.input)
        hasher.combine(self.output)
    }
    static func == (lhs: Syntax.StructuralType.Lambda, rhs: Syntax.StructuralType.Lambda) -> Bool {
        lhs.input == rhs.input && lhs.output == rhs.output
    }
}


extension Syntax.StructuralType.UnnamedTuple: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.types)
    }

    static func == (lhs: Syntax.StructuralType.UnnamedTuple, rhs: Syntax.StructuralType.UnnamedTuple) -> Bool {
        lhs.types == rhs.types
    }

    static func == (lhs: Syntax.StructuralType.UnnamedTuple, rhs: Syntax.StructuralType.NamedTuple) -> Bool {
        lhs.types == rhs.types.map { $0.type } 
    }
}

extension Syntax.StructuralType.NamedTuple: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.types)
    }

    static func == (lhs: Syntax.StructuralType.NamedTuple, rhs: Syntax.StructuralType.NamedTuple) -> Bool {
        lhs.types.map { $0.type } == rhs.types.map { $0.type }
    }

    static func == (lhs: Syntax.StructuralType.NamedTuple, rhs: Syntax.StructuralType.UnnamedTuple) -> Bool {
        lhs.types.map { $0.type } == rhs.types
    }
}

extension Syntax.UnionType: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.types)
    }

    static func == (lhs: Syntax.UnionType, rhs: Syntax.UnionType) -> Bool {
        lhs.types == rhs.types
    }
}

