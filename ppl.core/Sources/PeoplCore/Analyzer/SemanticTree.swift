// MARK: Language Semantic Tree
// ============================
// This file defines the semantic tree structure of valid type checked
// Peopl code.

enum Semantic {

    typealias DefinitionHash = Int
    typealias Tag = String

    struct Module {
        let definitions: [DefinitionHash: Definition]
        let definitionsSyntaxNodes: [DefinitionHash: Syntax.Definition]
    }
    
    enum Definition {
        case specificTypeDefinition(TypeDefinition)
        case specificValueDefinition(ValueDefinition)
    }

    struct TypeDefinition {

    }

    struct ValueDefinition {
    }

    enum TypeSpecifier {
        case nothing
        case never
        case tuple([TypeSpecifier])
        case record([Tag: TypeSpecifier])
        case union([TypeSpecifier])
        case choice([Tag: TypeSpecifier])

        case function(Function)
    }

    struct Function {
    }
}

