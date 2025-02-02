import Foundation
import SwiftTreeSitter
import TreeSitterPeoPl

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

    func getString(in source: Source) -> String? {
        guard let range = Swift.Range(self.range, in: source.content) else { return nil }
        return String(source.content[range])
    }

    func getLocation(in source: Source) -> NodeLocation? {
        let range = self.range.lowerBound..<self.range.upperBound
        let pointRange =
            NodeLocation.Point(
                line: Int(self.pointRange.lowerBound.row),
                column: Int(self.pointRange.lowerBound.column)
            )..<NodeLocation.Point(
                line: Int(self.pointRange.upperBound.row),
                column: Int(self.pointRange.upperBound.column)
            )
        return NodeLocation(
            pointRange: pointRange,
            range: range, sourceName: source.name)
    }
}

// MARK: - the syntax tree source
// ------------------------------

extension Module {
    init(source: String, path: String) throws {
        let language = Language(tree_sitter_peopl())
        let parser = Parser()
        try parser.setLanguage(language)

        let tree = parser.parse(source)
        guard let rootNode = tree?.rootNode else {
            throw SemanticError.sourceUnreadable
        }

        let source = Source(content: source, name: path)

        self.statements = rootNode.compactMapChildren { node in
            Statement(from: node, in: source)
        }
    }

    init(path: String) throws {

        let fileHandle = FileHandle(forReadingAtPath: path)

        guard let outputData = try fileHandle?.read(upToCount: Int.max),
            let outputString = String(data: outputData, encoding: .utf8)
        else {
            throw SemanticError.sourceUnreadable
        }
        try self.init(source: outputString, path: path)
    }
}

extension Statement {
    enum CodingKeys: String, CodingKey {
        case typeDefinition = "type_definition"
        case functionDefinition = "function_definition"
        // case implementationStatement
        // case constantsStatement
    }

    init?(from node: Node, in source: Source) {
        switch node.nodeType {
        case CodingKeys.typeDefinition.rawValue:
            guard let typeDefinition = TypeDefinition(from: node, in: source) else { return nil }
            self = .typeDefinition(typeDefinition)
        case CodingKeys.functionDefinition.rawValue:
            guard let functionDefinition = FunctionDefinition(from: node, in: source) else {
                return nil
            }
            self = .functionDefinition(functionDefinition)
        // case "implementation_statement":
        //     self = .implementationStatement(.init(from: node, in: source))
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

    init?(from node: Node, in source: Source) {
        guard let paramNameNode = node.child(byFieldName: "name"),
            let paramName = paramNameNode.getString(in: source),
            let paramTypeNode = node.child(byFieldName: "type"),
            let paramType = TypeIdentifier(from: paramTypeNode, in: source),
            let location = node.getLocation(in: source)
        else { return nil }

        self.type = paramType
        self.name = paramName

        // self.defaultValue = if let defaultValueNode = node.child(byFieldName: "default_value"),
        //                        let value = Expression.Simple(from: defaultValueNode, in: source) {
        // value
        // } else { nil }

        self.location = location
    }
}

extension TypeDefinition {
    init?(from node: Node, in source: Source) {
        guard let child = node.child(at: 1) else { return nil }
        switch child.nodeType {
        case CodingKeys.meta.rawValue:
            guard let meta = Meta(from: child, in: source) else { return nil }
            self = .meta(meta)
        case CodingKeys.simple.rawValue:
            guard let simple = Simple(from: child, in: source) else { return nil }
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

    init?(from node: Node, in source: Source) {
        guard let identifierNode = node.child(at: 0),
            let identifier = NominalType(from: identifierNode, in: source),
            let location = node.getLocation(in: source)
        else { return nil }
        self.identifier = identifier

        if let paramListNode = node.child(at: 1) {
            self.params = paramListNode.compactMapChildren { paramNode in
                if paramNode.nodeType == ParamDefinition.rawValue {
                    return ParamDefinition(from: paramNode, in: source)
                } else {
                    return nil
                }
            }
        } else {
            self.params = []
        }

        self.location = location
    }
}

extension TypeDefinition.Meta {

    init?(from node: Node, in source: Source) {
        guard let identifierNode = node.child(at: 0),
            let identifier = NominalType(from: identifierNode, in: source),
            let location = node.getLocation(in: source)
        else { return nil }
        self.identifier = identifier
        self.cases = node.compactMapChildren { childNode in
            if childNode.nodeType == TypeDefinition.CodingKeys.simple.rawValue {
                return TypeDefinition.Simple(from: childNode, in: source)
            }
            return nil
        }
        self.location = location
    }
}

// MARK: - function definitions
// ----------------------------

extension FunctionDefinition {

    enum CodingKeys: String, CodingKey {
        case inputType = "input_type"
        case scope
        case name
        case params
        case outputType = "output_type"
        case body
    }

    init?(from node: Node, in source: Source) {
        guard let location = node.getLocation(in: source) else { return nil }
        self.location = location

        if let child = node.child(byFieldName: CodingKeys.inputType.rawValue) {
            guard let typeIdentifier = TypeIdentifier(from: child, in: source) else { return nil }
            self.inputType = typeIdentifier
        } else {
            self.inputType = TypeIdentifier.nothing
        }

        if let child = node.child(byFieldName: CodingKeys.scope.rawValue) {
            guard let scope = NominalType(from: child, in: source) else { return nil }
            self.scope = scope
        } else {
            self.scope = nil
        }

        guard let child = node.child(byFieldName: CodingKeys.name.rawValue),
            let name = child.getString(in: source)
        else {
            return nil
        }
        self.name = name

        self.params =
            if let child = node.child(byFieldName: CodingKeys.params.rawValue) {
                child.compactMapChildren { paramNode in
                    if paramNode.nodeType == ParamDefinition.rawValue {
                        return ParamDefinition(from: paramNode, in: source)
                    } else {
                        return nil
                    }
                }
            } else {
                []
            }
        guard let child = node.child(byFieldName: CodingKeys.outputType.rawValue),
            let outputType = TypeIdentifier(from: child, in: source)
        else {
            return nil
        }
        self.outputType = outputType
        guard let child = node.child(byFieldName: CodingKeys.body.rawValue),
              let body = Expression(from: child, in: source) else { return nil }
        
        self.body = body
    }
}

// MARK: - types
// -------------

extension TypeIdentifier {
    static let typeIdentifier = "type_identifier"

    enum CodingKeys: String, CodingKey {
        case nothing = "nothing"
        case never = "never"
        case nominal = "nominal_type"
        case lambda = "lambda_structural_type"
        case tuple = "tuple_structural_type"
    }

    init?(from node: Node, in source: Source) {
        guard let child = node.child(at: 0) else { return nil }
        switch child.nodeType {
        case CodingKeys.nothing.rawValue:
            self = .nothing
        case CodingKeys.never.rawValue:
            self = .never
        case CodingKeys.nominal.rawValue:
            guard let nominal = NominalType(from: child, in: source) else { return nil }
            self = .nominal(nominal)
        case CodingKeys.lambda.rawValue:
            guard let lambda = StructuralType.Lambda(from: child, in: source) else { return nil }
            self = .lambda(lambda)
        case CodingKeys.tuple.rawValue:
            guard let tuple = StructuralType.Tuple(from: child, in: source) else { return nil }
            self = .tuple(tuple)
        default:
            return nil
        }
    }
}

extension NominalType {
    init?(from node: Node, in source: Source) {
        guard let location = node.getLocation(in: source) else { return nil }
        self.location = location

        self.chain = node.compactMapChildren { child in
            if child.nodeType == NominalType.flatNominalType {
                return FlatNominalType(from: child, in: source)
            } else {
                return nil
            }
        }
    }
}

extension FlatNominalType {
    init?(from node: Node, in source: Source) {
        guard let location = node.getLocation(in: source) else { return nil }
        self.location = location
        
        guard let typeNameNode = node.child(byFieldName: FlatNominalType.typeName),
            let typeName = typeNameNode.getString(in: source)
        else { return nil }
        self.typeName = typeName

        if let typeArgumentsNode = node.child(byFieldName: FlatNominalType.typeArguments) {
            self.typeArguments = typeArgumentsNode.compactMapChildren { typeArgumentChild in
                if typeArgumentChild.nodeType == TypeIdentifier.typeIdentifier {
                    TypeIdentifier(from: typeArgumentChild, in: source)
                } else {
                    nil
                }
            }
        } else {
            self.typeArguments = []
        }
    }
}

extension StructuralType.Tuple {
    init?(from node: Node, in source: Source) {
        guard let location = node.getLocation(in: source) else { return nil }
        self.location = location

        self.types = node.compactMapChildren { child in
            if child.nodeType == TypeIdentifier.typeIdentifier {
                return TypeIdentifier(from: child, in: source)
            }
            return nil
        }
    }
}

extension StructuralType.Lambda {

    init?(from node: Node, in source: Source) {
        self.input = node.compactMapChildrenEnumerated { (index, child) in
            if child.nodeType == TypeIdentifier.typeIdentifier && index < node.childCount - 1 {
                return TypeIdentifier(from: child, in: source)
            }
            return nil
        }
        guard let outputNode = node.child(at: node.childCount - 1),
            let output = TypeIdentifier(from: outputNode, in: source)
        else { return nil }
        self.output = [output]

        guard let location = node.getLocation(in: source) else { return nil }
        self.location = location
    }
}

// MARK: - Expressions
// -------------------
extension Expression {
    static let parenthesized = "parenthisized_expression"

    init?(from node: Node, in source: Source) {
        guard let location = node.getLocation(in: source) else { return nil }
        self.location = location
        if node.nodeType == Expression.parenthesized {
            guard let child = node.child(at: 1),
                  let expressionType = Expression.ExpressionType(from: child, in: source) else { return nil }
            self.expressionType = expressionType
        } else {
            guard let expressionType = Expression.ExpressionType(from: node, in: source) else { return nil }
            self.expressionType = expressionType
        }
    }
}

extension Expression.ExpressionType {

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
        case lambda = "lambda_expression"


        case call = "call_expression"
        case access = "access_expression"
        case field = "argument_name"

        case branched = "branched_expression"
        case piped = "piped_expression"

        static let unaryExpression = "unary_expression"
        static let binaryExpression = "binary_expression"
    }

    init?(from node: Node, in source: Source) {
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
                  let operandExpression = Expression(from: operandNode, in: source) else {
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
                  let leftExpression = Expression(from: leftNode, in: source),
                  let operatorNode = node.child(byFieldName: "operator"),
                  let operatorValue = operatorNode.getString(in: source),
                  let rightNode = node.child(byFieldName: "right"),
                  let rightExpression = Expression(from: rightNode, in: source) else {
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
                Expression(from: node, in: source)
            }
            self = .tuple(expressions)
        case CodingKeys.lambda.rawValue:
            guard let expressionNode = node.child(at: 1),
                  let expression = Expression(from: expressionNode, in: source) else { return nil }
            self = .lambda(expression)
        case CodingKeys.call.rawValue:
            guard let call = Expression.Call(from: node, in: source) else { return nil }
            self = .call(call)
        case CodingKeys.access.rawValue:
            guard let accessedNode = node.child(at: 0),
                  let accessed = Expression(from: accessedNode, in: source),
                  let argumentNode = node.child(at: 2),
                  let argumentName = argumentNode.getString(in: source) else { return nil }
            self = .access(Expression.Access(accessed: accessed, field: argumentName))
        case CodingKeys.field.rawValue:
            guard let fieldValue = node.getString(in: source) else { return nil }
            self = .field(fieldValue)
        case CodingKeys.branched.rawValue:
            guard let branched = Expression.Branched(from: node, in: source) else { return nil }
            self = .branched(branched)
        case CodingKeys.piped.rawValue:
            guard let leftNode = node.child(byFieldName: "left"),
                  let left = Expression(from: leftNode, in: source) else { return nil }
            guard let rightNode = node.child(byFieldName: "right"),
                  let right = Expression(from: rightNode, in: source) else { return nil }
            self = .piped(left: left, right: right)
        default:
            return nil
        }
    }
}

extension Expression.Call {
    init?(from node: Node, in source: Source) {
        guard let commandNode = node.child(byFieldName: "command"),
              let command = Expression.Call.Command(from: commandNode, in: source) else { return nil }
        self.command = command

        if let paramListNode = node.child(byFieldName: "params") {
            self.arguments = paramListNode.compactMapChildren { child in
                Expression.Call.Argument(from: child, in: source)
            }
        } else {
            self.arguments = []
        }
    }
}

extension Expression.Call.Command {
    enum CodingKeys: String, CodingKey {
        case simple
        case type = "nominal_type"
    }

    init?(from node: Node, in source: Source) {
        switch node.nodeType {
        case CodingKeys.type.rawValue:
            guard let type = TypeIdentifier(from: node, in: source) else { return nil }
            self = .type(type)
        default:
            guard let expression = Expression(from: node, in: source) else { return nil }
            self = .simple(expression)
        }
    }
}

extension Expression.Call.Argument {
    init?(from node: Node, in source: Source) {
        guard let nameNode = node.child(byFieldName: "name"),
              let name = nameNode.getString(in: source) else { return nil }
        self.name = name

        guard let valueNode = node.child(byFieldName: "value"),
              let value = Expression(from: valueNode, in: source) else { return nil }
        self.value = value
    }
}

extension Expression.Branched {
    static let branch = "branch_expression"

    init?(from node: Node, in source: Source) {
        self.branches = node.compactMapChildren { child in
            if child.nodeType == Expression.Branched.branch {
                Expression.Branched.Branch(from: child, in: source)
            } else {
                nil
            }
        }
        self.lastBranch = if let lastChild = node.lastChild,
            lastChild.nodeType != Expression.Branched.branch {
            Expression(from: lastChild, in: source)
        } else {
            nil
        }
    }
}

extension Expression.Branched.Branch {
    init?(from node: Node, in source: Source) {
        guard let captureGroupNode = node.child(byFieldName: "capture_group") else { return nil }
        self.captureGroup = captureGroupNode.compactMapChildren { child in
            Expression(from: child, in: source)
        }

        guard let bodyNode = node.child(byFieldName: "body"),
              let body = Expression.Branched.Branch.Body(from: bodyNode, in: source) else { return nil }
        self.body = body
    }
}

extension Expression.Branched.Branch.Body {

    enum CodingKeys: String, CodingKey {
        case simple
        case looped = "looped_expression"
    }

    init?(from node: Node, in source: Source) {
        switch node.nodeType {
        case CodingKeys.looped.rawValue:
            guard let loopedNode = node.child(at: 0),
                  let parenthisizedNode = loopedNode.child(at: 1),
                  let expression = Expression(from: parenthisizedNode, in: source) else { return nil }
            self = .looped(expression)
        default:
            guard let simple = Expression(from: node, in: source) else { return nil }
            self = .simple(simple)
        }
    }
}
