import Foundation
import SwiftTreeSitter

enum Statement: Encodable {
    case typeDeclaration(TypeDeclaration)
    // case functionDeclaration(FunctionDeclaration)
    // case implementationStatement(ImplementationStatement)
    // case constantsStatement(ConstantsStatement)

    enum CodingKeys: CodingKey {
        case typeDeclaration
        // case functionDeclaration
        // case implementationStatement
        // case constantsStatement
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .typeDeclaration(declaration):
            try container.encode(declaration, forKey: .typeDeclaration)
        }
    }

    init?(from node: Node, source: String) {
        switch node.nodeType {
        case "type_declaration":
            guard let typeDeclaration = TypeDeclaration(from: node, source: source) else { return nil }
            self = .typeDeclaration(typeDeclaration)
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
    struct FunctionDeclaration {
        // let inputType: String
        // let name: String
        // let params: [(name: String, value: String)]
        // let outputType: String
        // let body: String

        init(from: Node, source: String) {
            // inputType = from.child(at: 0)?.string ?? ""
            // name = from.child(at: 1)?.string ?? ""
            // params = from.child(at: 2)?.children.map { child in
            //     (name: child.child(at: 0)?.string ?? "", value: child.child(at: 1)?.string ?? "")
            // } ?? []
            // outputType = from.child(at: 3)?.string ?? ""
            // body = from.child(at: 4)?.string ?? ""
        }
    }

    struct ImplementationStatement {
        // let subType: String
        // let superType: String

        init(from: Node, source: String) {
            // subType = from.child(at: 0)?.string ?? ""
            // superType = from.child(at: 1)?.string ?? ""
        }
    }
}
