
extension ParamDefinition: Hashable {
    static func == (lhs: ParamDefinition, rhs: ParamDefinition) -> Bool {
        lhs.name == rhs.name &&
        lhs.type == rhs.type
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.name)
        hasher.combine(self.type)
    }
}

extension FunctionDefinition: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.name)
        hasher.combine(self.scope)
        hasher.combine(self.params)
        hasher.combine(self.inputType)
    }

    static func == (lhs: FunctionDefinition, rhs: FunctionDefinition) -> Bool {
        lhs.name == rhs.name &&
        lhs.scope == rhs.scope &&
        lhs.params == rhs.params &&
        lhs.inputType == rhs.inputType
    }
}

extension TypeIdentifier: Hashable {

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
        default:
            return false
        }
    }

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
        }
    }
}

extension FlatNominalType: Hashable {
    static func == (lhs: FlatNominalType, rhs: FlatNominalType) -> Bool {
        lhs.typeName == rhs.typeName && lhs.typeArguments == rhs.typeArguments
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.typeName)
        // hasher.combine(self.typeArguments)
        // TODO: should consider how type arguments would work with this
    }
}

extension NominalType: Hashable {
    static func == (lhs: NominalType, rhs: NominalType) -> Bool {
        lhs.chain == rhs.chain
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.chain)
    }
}

extension StructuralType.Lambda: Hashable {
    static func == (lhs: StructuralType.Lambda, rhs: StructuralType.Lambda) -> Bool {
        lhs.input == rhs.input && lhs.output == rhs.output
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.input)
        hasher.combine(self.output)
    }
}


extension StructuralType.UnnamedTuple: Hashable {
    static func == (lhs: StructuralType.UnnamedTuple, rhs: StructuralType.UnnamedTuple) -> Bool {
        lhs.types == rhs.types
    }

    static func == (lhs: StructuralType.UnnamedTuple, rhs: StructuralType.NamedTuple) -> Bool {
        lhs.types == rhs.types.map { $0.type } 
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.types)
    }
}

extension StructuralType.NamedTuple: Hashable {
    static func == (lhs: StructuralType.NamedTuple, rhs: StructuralType.NamedTuple) -> Bool {
        lhs.types.map { $0.type } == rhs.types.map { $0.type }
    }

    static func == (lhs: StructuralType.NamedTuple, rhs: StructuralType.UnnamedTuple) -> Bool {
        lhs.types.map { $0.type } == rhs.types
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.types)
    }
}
