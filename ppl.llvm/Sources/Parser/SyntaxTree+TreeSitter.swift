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

extension Project {
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

        let mainFunction = self.statements.compactMap { statement in
            if case let .functionDefinition(functionDefinition) = statement,
                functionDefinition.name == "main" {
                return functionDefinition
            }
            return nil
        }

        if mainFunction.count == 1, let mainFunction = mainFunction.first {
            self.main = mainFunction
        } else {
            throw SemanticError.mainFunctionNotFound
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

        self.defaultValue = if let defaultValueNode = node.child(byFieldName: "default_value"),
                               let value = Expression.Simple(from: defaultValueNode, source: source) {
            value
        } else { nil }

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
        guard let child = node.child(byFieldName: CodingKeys.body.rawValue),
              let body = Expression(from: child, source: source) else { return nil }

        self.name = name
        self.outputType = outputType
        self.body = body
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
            guard let call = Expression.Call(from: node, source: source) else { return nil }
            self = .call(call)
        case CodingKeys.branched.rawValue:
            guard let branched = Expression.Branched(from: node, source: source) else { return nil }
            self = .branched(branched)
        case CodingKeys.piped.rawValue:
            guard let piped = Expression.Piped(from: node, source: source) else { return nil }
            self = .piped(piped)
        default:
            guard let simple = Expression.Simple(from: node, source: source) else { return nil }
            self = .simple(simple)
        }
    }
}

extension Expression.Simple {

    enum CodingKeys: String, CodingKey {
        case nothing
        case never
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
        case mod = "binary_mod"

        case equal = "binary_equal"
        case different = "binary_different"
        case lessThan = "binary_less_than"
        case lessThanEqual = "binary_less_than_or_equal"
        case greaterThan = "binary_greater_than"
        case greaterThanEqual = "binary_greater_than_or_equal"
        case or = "binary_or"
        case and = "binary_and"

        case tuple = "tuple_literal"
        case parenthesized = "parenthisized_expression"
        case lambda = "lambda_expression"
        case access = "access_expression"

        case field = "field_identifier"

        static let unaryExpression = "unary_expression"
        static let binaryExpression = "binary_expression"
    }


    init?(from node: Node, source: String) {
        switch node.nodeType {
        case CodingKeys.nothing.rawValue:
            self = .nothing
        case CodingKeys.never.rawValue:
            self = .never
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
            self = .stringLiteral(String(stringValue.dropFirst().dropLast()))
        case CodingKeys.boolLiteral.rawValue:
            guard let boolText = node.getString(in: source),
                  let boolValue = Bool(boolText) else { return nil }
            self = .boolLiteral(boolValue)
        case CodingKeys.unaryExpression:
            guard let operatorNode = node.child(byFieldName: "operator"),
                  let operatorValue = operatorNode.getString(in: source),
                  let operandNode = node.child(byFieldName: "operand"),
                  let operandExpression = Expression.Simple(from: operandNode, source: source) else {
                return nil
            }
            switch operatorValue {
            case "+":
                self = .positive(operandExpression)
            case "-":
                self = .negative(operandExpression)
            case "not":
                self = .not(operandExpression)
            default:
                return nil
            }
        case CodingKeys.binaryExpression:
            guard let leftNode = node.child(byFieldName: "left"),
                  let leftExpression = Expression.Simple(from: leftNode, source: source),
                  let operatorNode = node.child(byFieldName: "operator"),
                  let operatorValue = operatorNode.getString(in: source),
                  let rightNode = node.child(byFieldName: "right"),
                  let rightExpression = Expression.Simple(from: rightNode, source: source) else {
                return nil
            }
            switch operatorValue {
            case "+":
                self = .plus(left: leftExpression, right: rightExpression)
            case "-":
                self = .minus(left: leftExpression, right: rightExpression)
            case "*":
                self = .times(left: leftExpression, right: rightExpression)
            case "/":
                self = .by(left: leftExpression, right: rightExpression)
            case "%":
                self = .mod(left: leftExpression, right: rightExpression)
            case "=":
                self = .equal(left: leftExpression, right: rightExpression)
            case "!=":
                self = .different(left: leftExpression, right: rightExpression)
            case "<":
                self = .lessThan(left: leftExpression, right: rightExpression)
            case "<=":
                self = .lessThanEqual(left: leftExpression, right: rightExpression)
            case ">":
                self = .greaterThan(left: leftExpression, right: rightExpression)
            case ">=":
                self = .greaterThanEqual(left: leftExpression, right: rightExpression)
            case "or":
                self = .or(left: leftExpression, right: rightExpression)
            case "and":
                self = .and(left: leftExpression, right: rightExpression)
            default:
                return nil
            }
        case CodingKeys.tuple.rawValue:
            let expressions = node.compactMapChildren { node in
                Expression(from: node, source: source)
            }
            self = .tuple(expressions)
        case CodingKeys.parenthesized.rawValue:
            guard let expressionNode = node.child(at: 1),
                  let expression = Expression(from: expressionNode, source: source) else { return nil }
            self = .parenthesized(expression)
        case CodingKeys.lambda.rawValue:
            guard let expressionNode = node.child(at: 1),
                  let expression = Expression(from: expressionNode, source: source) else { return nil }
            self = .lambda(expression)
        case CodingKeys.field.rawValue:
            guard let fieldValue = node.getString(in: source) else { return nil }
            self = .field(fieldValue)
        case CodingKeys.access.rawValue:
            guard let containerNode = node.child(at: 0),
                  let container = Expression.Simple(from: containerNode, source: source),
                  let fieldNode = node.child(at: 2),
                  let fieldValue = fieldNode.getString(in: source) else { return nil }
            self = .access(Expression.Simple.Access(accessed: container, field: fieldValue))

        default:
            return nil
        }
    }
}

extension Expression.Call {
    init?(from node: Node, source: String) {
        guard let commandNode = node.child(at: 0),
              let command = Expression.Call.Command(from: commandNode, source: source) else { return nil }
        self.command = command

        if let paramListNode = node.child(at: 1) {
            self.arguments = paramListNode.compactMapChildren { child in
                Expression.Call.Argument(from: child, source: source) 
            }
        } else {
            self.arguments = []
        }
    }
}

extension Expression.Call.Command {
    enum CodingKeys: String, CodingKey {
        case field = "field_identifier"
        case type = "type_identifier"
    }

    init?(from node: Node, source: String) {
        switch node.nodeType {
        case CodingKeys.field.rawValue:
            guard let fieldValue = node.getString(in: source) else { return nil }
            self = .field(fieldValue)
        case CodingKeys.type.rawValue:
            guard let type = TypeIdentifier(from: node, source: source) else { return nil }
            self = .type(type)
        default:
            return nil
        }
    }
}

extension Expression.Call.Argument {
    init?(from node: Node, source: String) {
        guard let nameNode = node.child(byFieldName: "name"),
              let name = nameNode.getString(in: source) else { return nil }
        self.name = name

        guard let valueNode = node.child(byFieldName: "value"),
              let value = Expression.Simple(from: valueNode, source: source) else { return nil }
        self.value = value
    }
}

extension Expression.Branched {
    static let branch = "branch_expression"

    init?(from node: Node, source: String) {
        self.branches = node.compactMapChildren { child in
            if child.nodeType == Expression.Branched.branch {
                Expression.Branched.Branch(from: child, source: source)
            } else {
                nil
            }
        }
        self.lastBranch = if let lastChild = node.lastChild,
            lastChild.nodeType != Expression.Branched.branch {
            Expression(from: lastChild, source: source)
        } else {
            nil
        }
    }
}

extension Expression.Branched.Branch {
    init?(from node: Node, source: String) {
        guard let captureGroupNode = node.child(byFieldName: "capture_group") else { return nil }
        self.captureGroup = captureGroupNode.compactMapChildren { child in
            Expression(from: child, source: source)
        }

        guard let bodyNode = node.child(byFieldName: "body"),
              let body = Expression.Branched.Branch.Body(from: bodyNode, source: source) else { return nil }
        self.body = body
    }
}

extension Expression.Branched.Branch.Body {

    enum CodingKeys: String, CodingKey {
        case simple
        case call = "call_expression"
        case looped = "looped_expression"
    }

    init?(from node: Node, source: String) {
        switch node.nodeType {
        case CodingKeys.call.rawValue:
            guard let call = Expression.Call(from: node, source: source) else { return nil }
            self = .call(call)
        case CodingKeys.looped.rawValue:
            guard let loopedNode = node.child(at: 0),
                  let parenthisizedNode = loopedNode.child(at: 1),
                  let expression = Expression(from: parenthisizedNode, source: source) else { return nil }
            self = .looped(expression) 
        default:
            guard let simple = Expression.Simple(from: node, source: source) else { return nil }
            self = .simple(simple)
        }
    }
}

extension Expression.Piped {

    enum CodingKeys: String, CodingKey {
        case normal
        case unwrapping
    }

    init?(from node: Node, source: String) {
        guard let leftNode = node.child(byFieldName: "left"),
              let left = Expression(from: leftNode, source: source) else { return nil }
        guard let rightNode = node.child(byFieldName: "right"),
              let right = Expression(from: rightNode, source: source) else { return nil }

        if let pipeNode = node.child(byFieldName: "operator"),
           let pipeOperator = pipeNode.getString(in: source) {
            switch pipeOperator {
            case "?":
                self = .unwrapping(left: left, right: right)
            case ";":
                self = .normal(left: left, right: right)
            default:
                return nil
            }
        } else {
            return nil
        }
    }
}
