
extension ParamDefinition: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.name)
        hasher.combine(self.type)
    }

    static func == (lhs: ParamDefinition, rhs: ParamDefinition) -> Bool {
        lhs.name == rhs.name &&
        lhs.type == rhs.type
    }
}

extension TypeDefinition: Hashable {
    func hash(into hasher: inout Hasher) {
        switch self {
        case let .simple(simple):
            hasher.combine(simple)
        case let .sum(sum):
            hasher.combine(sum)
        }
    }
    static func == (lhs: TypeDefinition, rhs: TypeDefinition) -> Bool {
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

extension TypeDefinition.Simple: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.identifier)
    }

    static func == (lhs: TypeDefinition.Simple, rhs: TypeDefinition.Simple) -> Bool {
        lhs.identifier == rhs.identifier
    }
}

extension TypeDefinition.Sum: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.identifier)
    }

    static func == (lhs: TypeDefinition.Sum, rhs: TypeDefinition.Sum) -> Bool {
        lhs.identifier == rhs.identifier
    }
}

extension FunctionIdentifier: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.name)
        hasher.combine(self.scope)
    }
    static func == (lhs: FunctionIdentifier, rhs: FunctionIdentifier) -> Bool {
        lhs.name == rhs.name && lhs.scope == rhs.scope
    }
}

extension FunctionDefinition: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.inputType)
        hasher.combine(self.functionIdentifier)
        hasher.combine(self.params)
    }

    static func == (lhs: FunctionDefinition, rhs: FunctionDefinition) -> Bool {
        lhs.inputType == rhs.inputType &&
        lhs.functionIdentifier == rhs.functionIdentifier &&
        lhs.params == rhs.params
    }
}

extension OperatorOverloadDefinition: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.left)
        hasher.combine(self.op)
        hasher.combine(self.right)
    }

    static func == (lhs: OperatorOverloadDefinition, rhs: OperatorOverloadDefinition) -> Bool {
        lhs.left == rhs.left &&
        lhs.op == rhs.op &&
        lhs.right == rhs.right
    }
}

extension TypeIdentifier: Hashable {
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

    static func == (lhs: TypeIdentifier, rhs: TypeIdentifier) -> Bool {
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

extension FlatNominalType: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.typeName)
        // hasher.combine(self.typeArguments)
        // TODO: should consider how type arguments would work with this
    }

    static func == (lhs: FlatNominalType, rhs: FlatNominalType) -> Bool {
        lhs.typeName == rhs.typeName // && lhs.typeArguments == rhs.typeArguments
    }
}

extension NominalType: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.chain)
    }
    static func == (lhs: NominalType, rhs: NominalType) -> Bool {
        lhs.chain == rhs.chain
    }
}

extension StructuralType.Lambda: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.input)
        hasher.combine(self.output)
    }
    static func == (lhs: StructuralType.Lambda, rhs: StructuralType.Lambda) -> Bool {
        lhs.input == rhs.input && lhs.output == rhs.output
    }
}


extension StructuralType.UnnamedTuple: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.types)
    }

    static func == (lhs: StructuralType.UnnamedTuple, rhs: StructuralType.UnnamedTuple) -> Bool {
        lhs.types == rhs.types
    }

    static func == (lhs: StructuralType.UnnamedTuple, rhs: StructuralType.NamedTuple) -> Bool {
        lhs.types == rhs.types.map { $0.type } 
    }
}

extension StructuralType.NamedTuple: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.types)
    }

    static func == (lhs: StructuralType.NamedTuple, rhs: StructuralType.NamedTuple) -> Bool {
        lhs.types.map { $0.type } == rhs.types.map { $0.type }
    }

    static func == (lhs: StructuralType.NamedTuple, rhs: StructuralType.UnnamedTuple) -> Bool {
        lhs.types.map { $0.type } == rhs.types
    }
}

extension UnionType: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.types)
    }

    static func == (lhs: UnionType, rhs: UnionType) -> Bool {
        lhs.types == rhs.types
    }
}

