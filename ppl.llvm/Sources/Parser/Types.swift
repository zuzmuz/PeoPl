import SwiftTreeSitter

enum TypeIdentifier: Encodable {
    static let rawValue = "type_identifier"

    case nominal(NominalType)
    case structural(StructuralType)

    init?(from node: Node, source: String) {
        guard let child = node.child(at: 0) else { return nil }
        if let nominal = NominalType(from: child, source: source) {
            self = .nominal(nominal)
        } else if let structural = StructuralType(from: child, source: source) {
            self = .structural(structural)
        } else {
            return nil
        }
    }

    func encode(to encoder: any Encoder) throws {
        switch self {
        case let .nominal(nominal):
            try nominal.encode(to: encoder)
        case let .structural(structural):
            try structural.encode(to: encoder)
        }
    }
}

enum NominalType: Encodable {
    case specific(String)
    case generic(GenericType)

    enum CodingKeys: String, CodingKey {
        case specific = "specific_nominal_type"
        case generic = "generic_nominal_type"
    }

    init?(from node: Node, source: String) {
        switch node.nodeType {
        case CodingKeys.specific.rawValue:
            guard let range = Swift.Range(node.range, in: source) else { return nil }
            self = .specific(String(source[range]))
        case CodingKeys.generic.rawValue:
            guard let genericType = GenericType(from: node, source: source) else { return nil }
            self = .generic(genericType)
        default: return nil
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .specific(name):
            try container.encode(name, forKey: .specific)
        case let .generic(generic):
            try container.encode(generic, forKey: .generic)
        }
    }

    struct GenericType: Encodable {
        let name: String
        let associatedTypes: [TypeIdentifier]

        init?(from node: Node, source: String) {
            guard let typeNameNode = node.child(at: 0),
                  let range = Swift.Range(typeNameNode.range, in: source) else { return nil }
            self.associatedTypes = node.compactMapChildren { childNode in
                if childNode.nodeType == TypeIdentifier.rawValue {
                    return TypeIdentifier(from: childNode, source: source)
                } else {
                    return nil
                }
            }
            self.name = String(source[range])
        }
    }
}

enum StructuralType: Encodable {
    indirect case lambda(Lambda)
    case tuple([TypeIdentifier])

    enum CodingKeys: String, CodingKey {
        case lambda = "lambda_structural_type"
        case tuple = "tuple_structural_type"
    }
    
    init?(from node: Node, source: String) {
        switch node.nodeType {
        case CodingKeys.tuple.rawValue:
            self = .tuple(node.compactMapChildren { child in
                if child.nodeType == TypeIdentifier.rawValue {
                    return TypeIdentifier(from: child, source: source)
                }
                return nil
            })
        case CodingKeys.lambda.rawValue:
            guard let lambda = Lambda(from: node, source: source) else { return nil }
            self = .lambda(lambda)
        default:
            return nil
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .tuple(types):
            try container.encode(types, forKey: .tuple)
        case let .lambda(lambda):
            try container.encode(lambda, forKey: .lambda)
        }
    }

    struct Lambda: Encodable {
        let input: [TypeIdentifier]
        let output: TypeIdentifier

        init?(from node: Node, source: String) {
            self.input = node.compactMapChildrenEnumerated { (index, child) in
                if child.nodeType == TypeIdentifier.rawValue && index < node.childCount - 1 {
                    return TypeIdentifier(from: child, source: source)
                }
                return nil
            }
            guard let outputNode = node.child(at: node.childCount-1),
                  let output = TypeIdentifier(from: outputNode, source: source) else { return nil }
            self.output = output
        }
    }
}

