import SwiftTreeSitter

struct ParamDefinition: Encodable {
    static let rawValue = "param_definition"

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
