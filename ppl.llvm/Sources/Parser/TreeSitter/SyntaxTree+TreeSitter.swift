import SwiftTreeSitter
import TreeSitterPeoPl
import Foundation

// MARK: TreeSitter node extension functions
// -----------------------------------------

extension Node {
    func compactMapChildren<T>(block: (Node) -> T?) -> [T] {
        (0..<childCount).compactMap { i in
            guard let child = child(at: i) else { return nil }
            return block(child)
        }
    }

    func compactMapChildrenEnumerated<T>(block: (Int, Node) -> T?) -> [T] {
        (0..<childCount).compactMap { i in
            guard let child = child(at: i) else { return nil }
            return block(i, child)
        }
    }

    func getString(in source: String) -> String? {
        guard let range = Swift.Range(self.range, in: source) else { return nil }
        return String(source[range])
    }
}


// MARK: - the syntax tree source
// ------------------------------

extension SyntaxTree {
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
            Statement(from: node, source: outputString)
        }
    }
}


extension Statement {
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
        // case "implementation_statement":
        //     self = .implementationStatement(.init(from: node, source: source))
        // case "constants_statement":
        //     self = .constantsStatement(.init(from: node))
        default:
            return nil
        }
    }
}


// MARK: - type definitions
// ------------------------

extension ParamDefinition {
    static let rawValue = "param_definition"

    init?(from node: Node, source: String) {
        guard let paramNameNode = node.child(at: 0),
              let paramNameRange = Swift.Range(paramNameNode.range, in: source),
              let paramTypeNode = node.child(at: 2),
              let paramType = TypeIdentifier(from: paramTypeNode, source: source) else { return nil }
        self.name = String(source[paramNameRange])
        self.type = paramType
    }
}

extension TypeDefinition {
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
}

extension TypeDefinition.Simple {

    init?(from node: Node, source: String) {
        guard let identifierNode = node.child(at: 0),
              let identifier = NominalType(from: identifierNode, source: source) else { return nil }
        self.identifier = identifier

        if let paramListNode = node.child(at: 1) {
            self.params = paramListNode.compactMapChildren { paramNode in
                if paramNode.nodeType == ParamDefinition.rawValue {
                    return ParamDefinition(from: paramNode, source: source)
                } else {
                    return nil
                }
            }
        } else {
            self.params = []
        }
    }
}

extension TypeDefinition.Meta {

    init?(from node: Node, source: String) {
        guard let identifierNode = node.child(at: 0),
              let identifier = NominalType(from: identifierNode, source: source) else { return nil }
        self.identifier = identifier
        self.cases = node.compactMapChildren { childNode in
            if childNode.nodeType == TypeDefinition.CodingKeys.simple.rawValue {
                return TypeDefinition.Simple(from: childNode, source: source)
            }
            return nil
        }
    }
}

// MARK: - function definitions
// ----------------------------


extension FunctionDefinition {

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

        self.body = if let child = node.child(byFieldName: CodingKeys.body.rawValue),
            let body = Expression(from: child, source: source) {
                body
        } else {
            nil
        }

        self.name = name
        self.outputType = outputType
        // self.body = body
    }
}


// MARK: - types
// -------------

extension TypeIdentifier {
    static let rawValue = "type_identifier"

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

extension NominalType {

    enum CodingKeys: String, CodingKey {
        case specific = "specific_nominal_type"
        case generic = "generic_nominal_type"
    }

    init?(from node: Node, source: String) {
        switch node.nodeType {
        case CodingKeys.specific.rawValue:
            guard let name = node.getString(in: source) else { return nil }
            self = .specific(name)
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
}

extension NominalType.GenericType {

    init?(from node: Node, source: String) {
        guard let typeNameNode = node.child(at: 0),
              let name = typeNameNode.getString(in: source) else { return nil }
        self.name = name
        self.associatedTypes = node.compactMapChildren { childNode in
            if childNode.nodeType == TypeIdentifier.rawValue {
                return TypeIdentifier(from: childNode, source: source)
            } else {
                return nil
            }
        }
    }

}

extension StructuralType {

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
}

extension StructuralType.Lambda {

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


// MARK: - Expressions
// -------------------

extension Expression {

    enum CodingKeys: String, CodingKey {
        case simple
        case call = "call_expression"
        case branched = "branched_expression"
        case piped = "piped_expression"
    }

    init?(from node: Node, source: String) {
        switch node.nodeType {
        case CodingKeys.call.rawValue:
            return nil
        case CodingKeys.branched.rawValue:
            return nil
        case CodingKeys.piped.rawValue:
            return nil
        default:
            guard let simple = Expression.Simple(from: node, source: source) else { return nil }
            self = .simple(simple)
        }
    }
}

extension Expression.Simple {

    enum CodingKeys: String, CodingKey {
        case intLiteral = "int_literal"
        case floatLiteral = "float_literal"
        case stringLiteral = "string_literal"
        case boolLiteral = "bool_literal"

        case positive = "unary_positive"
        case negative = "unary_negative"
        case not = "unary_not"

        case plus = "binary_plus"
        case minus = "binary_minus"
        case times = "binary_times"
        case by = "binary_by"

        case equal = "binary_equal"
        case different = "binary_different"
        case lessThan = "binary_less_than"
        case lessThanEqual = "binary_less_than_or_equal"
        case greaterThan = "binary_greater_than"
        case greaterThanEqual = "binary_greater_than_or_equal"
        case or = "binary_or"
        case and = "binary_and"

        case tuple
        case parenthesized
        case lambda
        case field
        case access
    }

    init?(from node: Node, source: String) {
        switch node.nodeType {
        case CodingKeys.intLiteral.rawValue:
            guard let intText = node.getString(in: source),
                  let intValue = Int(intText) else { return nil }
            self = .intLiteral(intValue)
        case CodingKeys.floatLiteral.rawValue:
            guard let floatText = node.getString(in: source),
                  let floatValue = Float(floatText) else { return nil }
            self = .floatLiteral(floatValue)
        case CodingKeys.stringLiteral.rawValue:
            guard let stringValue = node.getString(in: source) else { return nil }
            self = .stringLiteral(stringValue)
        case CodingKeys.boolLiteral.rawValue:
            guard let boolText = node.getString(in: source),
                  let boolValue = Bool(boolText) else { return nil }
            self = .boolLiteral(boolValue)
        default:
            return nil
        }
    }
}


