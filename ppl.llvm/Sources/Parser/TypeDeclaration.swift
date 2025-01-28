import SwiftTreeSitter
import TreeSitterPeoPl

extension Statement {

    enum TypeDeclaration: Encodable {
        case simple(Simple)
        case meta(Meta)

        init?(from node: Node, source: String) {
            guard let child = node.child(at: 1) else { return nil }
            switch child.nodeType {
            case "meta_type_declaration":
                return nil
            case "simple_type_declaration":
                guard let simple = Simple(from: child, source: source) else { return nil }
                self = .simple(simple)
            default:
                return nil
            }
        }

        enum CodingKeys: String, CodingKey {
            case simple
            case meta
        }

        func encode(to encoder: any Encoder) throws {
            var container =  encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case let .simple(simple):
                try container.encode(simple, forKey: .simple)
            case .meta:
                break
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

        enum TypeIdentifier: Encodable {
            case nominal(NominalType)
            case structural(StructuralType)

            init?(from node: Node, source: String) {
                guard let child = node.child(at: 0) else { return nil }
                if let nominal = NominalType(from: child, source: source) {
                    self = .nominal(nominal)
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
                case specific
                case generic
            }

            init?(from node: Node, source: String) {
                switch node.nodeType {
                case "type_name":
                    guard let range = Swift.Range(node.range, in: source) else { return nil }
                    self = .specific(String(source[range]))
                case "generic_type_identifier":
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
                let associatedTypes: [NominalType]

                init?(from node: Node, source: String) {
                    guard let typeNameNode = node.child(at: 0),
                          let range = Swift.Range(typeNameNode.range, in: source) else { return nil }
                    self.associatedTypes = node.compactMapChildren { childNode in
                        if childNode.nodeType == "type_identifier" {
                            guard let typeIdentifier = childNode.child(at: 0) else { return nil }
                            return NominalType(from: typeIdentifier, source: source)
                        } else {
                            return nil
                        }
                    }
                    self.name = String(source[range])
                }
            }
        }

        enum StructuralType: Encodable {
            indirect case lambda(input: [TypeIdentifier], output: TypeIdentifier)
            case tuple([TypeIdentifier])
        }


        struct Meta: Encodable {
        }
    }
}
