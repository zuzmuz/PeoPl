
// MARK: - the syntax tree source
// ------------------------------

extension Statement {
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .typeDefinition(definition):
            try container.encode(definition, forKey: .typeDefinition)
        case let .functionDefinition(definition):
            try container.encode(definition, forKey: .functionDefinition)
        }
    }
}


// MARK: - type definitions
// ------------------------

extension TypeDefinition {
    func encode(to encoder: any Encoder) throws {
        var container =  encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .simple(simple):
            try container.encode(simple, forKey: .simple)
        case let .meta(meta):
            try container.encode(meta, forKey: .meta)
        }
    }
}

// MARK: - types
// -------------

extension TypeIdentifier {
    func encode(to encoder: any Encoder) throws {
        switch self {
        case let .nominal(nominal):
            try nominal.encode(to: encoder)
        case let .structural(structural):
            try structural.encode(to: encoder)
        }
    }
}

extension NominalType {
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .specific(name):
            try container.encode(name, forKey: .specific)
        case let .generic(generic):
            try container.encode(generic, forKey: .generic)
        }
    }
}

extension StructuralType {
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .tuple(types):
            try container.encode(types, forKey: .tuple)
        case let .lambda(lambda):
            try container.encode(lambda, forKey: .lambda)
        }
    }
}

// MARK: - Expressions
// -------------------

extension Expression {
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .simple(simple):
            try container.encode(simple, forKey: .simple)
        default:
            break
        }
    }
}

extension Expression.Simple {
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .intLiteral(value):
            try container.encode(value, forKey: .intLiteral)
        case let .floatLiteral(value):
            try container.encode(value, forKey: .floatLiteral)
        case let .stringLiteral(value):
            try container.encode(value, forKey: .stringLiteral)
        case let .boolLiteral(value):
            try container.encode(value, forKey: .boolLiteral)
        case let .positive(expression):
            try container.encode(expression, forKey: .positive)
        case let .negative(expression):
            try container.encode(expression, forKey: .negative)
        case let .plus(left, right):
            try container.encode(["left": left, "right": right], forKey: .plus)
        case let .minus(left, right):
            try container.encode(["left": left, "right": right], forKey: .minus)
        case let .times(left, right):
            try container.encode(["left": left, "right": right], forKey: .times)
        case let .by(left, right):
            try container.encode(["left": left, "right": right], forKey: .by)
        case let .equal(left, right):
            try container.encode(["left": left, "right": right], forKey: .equal)
        case let .different(left, right):
            try container.encode(["left": left, "right": right], forKey: .different)
        case let .lessThan(left, right):
            try container.encode(["left": left, "right": right], forKey: .lessThan)
        case let .lessThanEqual(left, right):
            try container.encode(["left": left, "right": right], forKey: .lessThanEqual)
        case let .greaterThan(left, right):
            try container.encode(["left": left, "right": right], forKey: .greaterThan)
        case let .greaterThanEqual(left, right):
            try container.encode(["left": left, "right": right], forKey: .greaterThanEqual)
        case let .or(left, right):
            try container.encode(["left": left, "right": right], forKey: .or)
        case let .and(left, right):
            try container.encode(["left": left, "right": right], forKey: .and)
        default:
            break
        }
    }
}
