import Foundation
import SwiftTreeSitter

enum Statement: Encodable {
    case typeDefinition(TypeDefinition)
    case functionDefinition(FunctionDefinition)
    // case implementationStatement(ImplementationStatement)
    // case constantsStatement(ConstantsStatement)

    enum CodingKeys: String, CodingKey {
        case typeDefinition = "type_definition"
        case functionDefinition = "function_definition"
        // case implementationStatement
        // case constantsStatement
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .typeDefinition(definition):
            try container.encode(definition, forKey: .typeDefinition)
        case let .functionDefinition(definition):
            try container.encode(definition, forKey: .functionDefinition)
        }
    }

    init?(from node: Node, source: String) {
        switch node.nodeType {
        case CodingKeys.typeDefinition.rawValue:
            guard let typeDefinition = TypeDefinition(from: node, source: source) else { return nil }
            self = .typeDefinition(typeDefinition)
        case CodingKeys.functionDefinition.rawValue:
            guard let functionDefinition = FunctionDefinition(from: node, source: source) else { return nil }
            self = .functionDefinition(functionDefinition)
        // case "function_declaration":
        //     self = .functionDeclaration(.init(from: node, source: source))
        // case "implementation_statement":
        //     self = .implementationStatement(.init(from: node, source: source))
        // case "constants_statement":
        //     self = .constantsStatement(.init(from: node))
        default:
            return nil
        }
    }
}
