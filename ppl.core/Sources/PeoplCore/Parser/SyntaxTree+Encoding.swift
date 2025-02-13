import Foundation

protocol DebugableSyntaxNode: Encodable, CustomStringConvertible {
}

extension DebugableSyntaxNode {
    var description: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        guard let encoded = try? encoder.encode(self),
            let description = String(data: encoded, encoding: .utf8) else { return "description failed" }
        return description
    }
}
// MARK: - the syntax tree source
// ------------------------------

extension Statement: DebugableSyntaxNode {
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

extension TypeDefinition: DebugableSyntaxNode {
    func encode(to encoder: any Encoder) throws {
        var container =  encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .simple(simple):
            try container.encode(simple, forKey: .simple)
        case let .sum(meta):
            try container.encode(meta, forKey: .sum)
        }
    }
}

// MARK: - types
// -------------

extension TypeIdentifier: DebugableSyntaxNode {
    func encode(to encoder: any Encoder) throws {
        switch self {
        case .nothing:
            try "nothing".encode(to: encoder)
        case .never:
            try "never".encode(to: encoder)
        case let .nominal(nominal):
            try nominal.encode(to: encoder)
        case let .unnamedTuple(tuple):
            try tuple.encode(to: encoder)
        case let .namedTuple(tuple):
            try tuple.encode(to: encoder)
        case let .lambda(lambda):
            try lambda.encode(to: encoder)
        case let .union(union):
            try union.encode(to: encoder)
        }
    }
}

// MARK: - Expressions
// -------------------

extension Expression.ExpressionType: DebugableSyntaxNode {
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .nothing:
            try container.encode("nothing", forKey: .nothing)
        case .never:
            try container.encode("never", forKey: .never)
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
        case let .multiplied(expression):
            try container.encode(expression, forKey: .multiplied)
        case let .divided(expression):
            try container.encode(expression, forKey: .divided)
        case let .moduled(expression):
            try container.encode(expression, forKey: .moduled)
        case let .anded(expression):
            try container.encode(expression, forKey: .anded)
        case let .ored(expression):
            try container.encode(expression, forKey: .ored)
        case let .not(expression):
            try container.encode(expression, forKey: .not)
        case let .plus(left, right):
            try container.encode(["left": left, "right": right], forKey: .plus)
        case let .minus(left, right):
            try container.encode(["left": left, "right": right], forKey: .minus)
        case let .times(left, right):
            try container.encode(["left": left, "right": right], forKey: .times)
        case let .by(left, right):
            try container.encode(["left": left, "right": right], forKey: .by)
        case let .mod(left, right):
            try container.encode(["left": left, "right": right], forKey: .mod)
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
        case let .namedTuple(expressions):
            try container.encode(expressions, forKey: .namedTuple)
        case let .unnamedTuple(expressions):
            try container.encode(expressions, forKey: .unnamedTuple)
        case let .lambda(expression):
            try container.encode(expression, forKey: .lambda)
        case let .call(call):
            try container.encode(call, forKey: .call)
        case let .access(accessExpression):
            try container.encode(accessExpression, forKey: .access)
        case let .field(field):
            try container.encode(field, forKey: .field)
        case let .branched(branched):
            try container.encode(branched, forKey: .branched)
        case let .piped(left, right):
            try container.encode(["left": left, "right": right], forKey: .piped)
        }
    }
}

extension Expression.Prefix: DebugableSyntaxNode {
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: Expression.Prefix.CodingKeys.self)
        switch self {
        case let .simple(expression):
            try container.encode(expression, forKey: .simple)
        case let .type(type):
            try container.encode(type, forKey: .type)
        }
    }
}

extension Expression.Branched.Branch.Body: DebugableSyntaxNode {
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: Expression.Branched.Branch.Body.CodingKeys.self)
        switch self {
        case let .simple(simple):
            try simple.encode(to: encoder)
        case let .looped(expression):
            try container.encode(expression, forKey: .looped)
        }
    }
}
