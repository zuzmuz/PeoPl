import SwiftTreeSitter

enum TypeDefinition: Encodable {
    case simple(Simple)
    case meta(Meta)

    init?(from node: Node, source: String) {
        guard let child = node.child(at: 1) else { return nil }
        switch child.nodeType {
        case CodingKeys.meta.rawValue:
            guard let meta = Meta(from: child, source: source) else { return nil }
            self = .meta(meta)
        case CodingKeys.simple.rawValue:
            guard let simple = Simple(from: child, source: source) else { return nil }
            self = .simple(simple)
        default:
            return nil
        }
    }

    enum CodingKeys: String, CodingKey {
        case simple = "simple_type_definition"
        case meta = "meta_type_definition"
    }

    func encode(to encoder: any Encoder) throws {
        var container =  encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .simple(simple):
            try container.encode(simple, forKey: .simple)
        case let .meta(meta):
            try container.encode(meta, forKey: .meta)
        }
    }

    struct Simple: Encodable {
        let identifier: NominalType
        let params: [Param]

        init?(from node: Node, source: String) {
            guard let identifierNode = node.child(at: 0),
                  let identifier = NominalType(from: identifierNode, source: source) else { return nil }
            self.identifier = identifier

            if let paramListNode = node.child(at: 1) {
                self.params = paramListNode.compactMapChildren { paramNode in
                    if paramNode.nodeType == "param_declaration" {
                        return Param(from: paramNode, source: source)
                    } else {
                        return nil
                    }
                }
            } else {
                self.params = []
            }
        }

        struct Param: Encodable {
            let name: String
            let type: TypeIdentifier

            init?(from node: Node, source: String) {
                guard let paramNameNode = node.child(at: 0),
                      let paramNameRange = Swift.Range(paramNameNode.range, in: source),
                      let paramTypeNode = node.child(at: 2),
                      let paramType = TypeIdentifier(from: paramTypeNode, source: source) else { return nil }
                self.name = String(source[paramNameRange])
                self.type = paramType
            }
        }
    }

    struct Meta: Encodable {
        let identifier: NominalType
        let cases: [Simple]

        init?(from node: Node, source: String) {
            guard let identifierNode = node.child(at: 0),
                  let identifier = NominalType(from: identifierNode, source: source) else { return nil }
            self.identifier = identifier
            self.cases = node.compactMapChildren { childNode in
                if childNode.nodeType == TypeDefinition.CodingKeys.simple.rawValue {
                    return Simple(from: childNode, source: source)
                }
                return nil
            }
        }
    }
}
