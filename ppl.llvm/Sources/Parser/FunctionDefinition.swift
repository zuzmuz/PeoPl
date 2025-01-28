import SwiftTreeSitter


struct FunctionDefinition: Encodable {
    let inputType: TypeIdentifier?
    let name: String
    let params: [ParamDefinition]
    let outputType: TypeIdentifier
    let body: String

    enum CodingKeys: String, CodingKey {
        case inputType = "input_type"
        case name
        case params
        case outputType = "output_type"
        case body
    }

    init?(from node: Node, source: String) {
        self.inputType = if let child = node.child(byFieldName: CodingKeys.inputType.rawValue) {
            TypeIdentifier(from: child, source: source)
        } else {
            nil
        }
        guard let child = node.child(byFieldName: CodingKeys.name.rawValue),
           let name = child.getString(in: source) else {
            return nil
        }
        self.params = if let child = node.child(byFieldName: CodingKeys.params.rawValue) {
            child.compactMapChildren { paramNode in
                if paramNode.nodeType == ParamDefinition.rawValue {
                    return ParamDefinition(from: paramNode, source: source)
                } else {
                    return nil
                }
            }
        } else {
            []
        }
        guard let child = node.child(byFieldName: CodingKeys.outputType.rawValue),
           let outputType = TypeIdentifier(from: child, source: source) else {
            return nil
        }

        guard let child = node.child(byFieldName: CodingKeys.body.rawValue),
           let body = child.getString(in: source) else {
            return nil
        }

        self.name = name
        self.outputType = outputType
        self.body = body
    }
}
