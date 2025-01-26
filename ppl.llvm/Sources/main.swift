import Foundation
import SwiftTreeSitter
import TreeSitterPeoPl

enum Statement {
    case typeDeclaration(TypeDeclaration)
    case functionDeclaration(FunctionDeclaration)
    case implementationStatement(ImplementationStatement)
    // case constantsStatement(ConstantsStatement)

    init?(from node: Node) {
        switch node.nodeType {
        case "type_declaration":
            guard let typeDeclaration = TypeDeclaration(from: node) else { return nil }
            self = .typeDeclaration(typeDeclaration)
        case "function_declaration":
            self = .functionDeclaration(.init(from: node))
        case "implementation_statement":
            self = .implementationStatement(.init(from: node))
        // case "constants_statement":
        //     self = .constantsStatement(.init(from: node))
        default:
            return nil
        }
    }

    enum TypeDeclaration {
        case simple(Simple)
        case meta(Meta)

        enum Identifier {
            case name(String)
            case generic(String, associatedTypes: [Identifier])
            // case tuple
            // case inlineLambda

            init?(from node: Node) {

                print(node.compactMapChildren { $0.nodeType })
                return nil
            }
        }

        init?(from node: Node) {
            guard let child = node.child(at: 1) else { return nil }
            switch child.nodeType {
            case "meta_type_declaration":
                self = .meta(.init())
            case "simple_type_declaration":
                guard let simple = Simple(from: child) else { return nil }
                self = .simple(simple)
            default:
                return nil
            }
        }

        struct Simple {
            let identifier: Identifier
            let params: [String]

            init?(from node: Node) {

                guard let identifierNode = node.child(at: 0),
                      let identifier = Identifier(from: identifierNode) else { return nil }
                self.identifier = identifier
                self.params = []
            }
        }

        struct Meta {
        }
    }

    struct FunctionDeclaration {
        // let inputType: String
        // let name: String
        // let params: [(name: String, value: String)]
        // let outputType: String
        // let body: String

        init(from: Node) {
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

        init(from: Node) {
            // subType = from.child(at: 0)?.string ?? ""
            // superType = from.child(at: 1)?.string ?? ""
        }
    }
}

extension Node {
    func compactMapChildren<T>(block: (Node) -> T?) -> [T] {
        (0..<childCount).compactMap { i in
            guard let child = child(at: i) else { return nil }
            return block(child)
        }
    }
}

enum SemanticError: Error {
    case sourceUnreadable
}

struct SyntaxTree {


    let statements: [Statement]


    init(path: String) throws {
        let language = Language(tree_sitter_peopl())
        let parser = Parser()
        try parser.setLanguage(language)

        let fileHandle = FileHandle(forReadingAtPath: path)

        guard let outputData = try fileHandle?.read(upToCount: Int.max),
            let outputString = String(data: outputData, encoding: .utf8)
        else {
            throw SemanticError.sourceUnreadable
        }

        let tree = parser.parse(outputString)
        guard let rootNode = tree?.rootNode else {
            throw SemanticError.sourceUnreadable
        }

        self.statements = rootNode.compactMapChildren { node in
            Statement(from: node)
        }

        // print(statements)
    }
}

let parser = try SyntaxTree(path: "../examples/type_system.ppl")
