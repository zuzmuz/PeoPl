// MARK: Language Semantic Tree
// ============================
// This file defines the semantic tree structure of valid type checked
// Peopl code.

enum Semantic {

    // typealias DefinitionHash = Int
    typealias Tag = String
    typealias TypeDefinitionMap = [Syntax.ScopedIdentifier: (
        TypeDefinition, Syntax.TypeDefinition
    )]
    typealias ValueDefinitionMap = [Syntax.ScopedIdentifier: (
        ValueDefinition, Syntax.ValueDefinition
    )]

    struct Context {
        let typeDefinitions: TypeDefinitionMap
        let valueDefinition: ValueDefinitionMap
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
