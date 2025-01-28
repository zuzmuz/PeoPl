import SwiftTreeSitter

extension Statement {

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
}
