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

    func getString(in source: Syntax.Source) -> String? {
        guard let range = Swift.Range(self.range, in: source.content) else { return nil }
        return String(source.content[range])
    }

    func getLocation(in source: Syntax.Source) -> Syntax.NodeLocation? {
        let range = self.range.lowerBound..<self.range.upperBound
        let pointRange =
            Syntax.NodeLocation.Point(
                line: Int(self.pointRange.lowerBound.row),
                column: Int(self.pointRange.lowerBound.column)
            )..<Syntax.NodeLocation.Point(
                line: Int(self.pointRange.upperBound.row),
                column: Int(self.pointRange.upperBound.column)
            )
        return Syntax.NodeLocation(
            pointRange: pointRange,
            range: range, sourceName: source.name)
    }
}

// MARK: - the syntax tree source
// ------------------------------

extension Syntax.Module {
    init(source: String, path: String) throws {
        let language = Language(tree_sitter_peopl())
        let parser = Parser()
        try parser.setLanguage(language)

        let tree = parser.parse(source)
        guard let rootNode = tree?.rootNode else {
            throw SyntaxError.sourceUnreadable
        }

        let source = Syntax.Source(content: source, name: path)

        self.statements = rootNode.compactMapChildren { node in
            Syntax.Statement(from: node, in: source)
        }
    }

    init(path: String) throws {

        let fileHandle = FileHandle(forReadingAtPath: path)

        guard let outputData = try fileHandle?.read(upToCount: Int.max),
            let outputString = String(data: outputData, encoding: .utf8)
        else {
            throw SyntaxError.sourceUnreadable
        }
        try self.init(source: outputString, path: path)
    }
}

extension Syntax.Statement {
    enum CodingKeys: String, CodingKey {
        case typeDefinition = "type_definition"
        case normalfunctionDefinition = "normal_function_definition"
        case operatorOverloadDefinition = "operator_overload_definition"
        // case implementationStatement
        // case constantsStatement
        static let functionDefinition = "function_definition"
    }

    init?(from node: Node, in source: Syntax.Source) {
        switch node.nodeType {
        case CodingKeys.typeDefinition.rawValue:
            guard let typeDefinition = Syntax.TypeDefinition(from: node, in: source) else { return nil }
            self = .typeDefinition(typeDefinition)
        case CodingKeys.functionDefinition:
            guard let child = node.child(at: 1) else { return nil }
            switch child.nodeType {
            case CodingKeys.normalfunctionDefinition.rawValue:
                guard let functionDefinition = Syntax.FunctionDefinition(from: child, in: source) else {
                    return nil
                }
                self = .functionDefinition(functionDefinition)
            case CodingKeys.operatorOverloadDefinition.rawValue:
                guard let operatorOverloadDefinition = Syntax.OperatorOverloadDefinition(from: child, in: source) else {
                    return nil
                }
                self = .operatorOverloadDefinition(operatorOverloadDefinition)
            default:
                return nil
            }
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

extension Syntax.ParamDefinition {
    static let rawValue = "param_definition"

    init?(from node: Node, in source: Syntax.Source) {
        guard let paramNameNode = node.child(byFieldName: "name"),
            let paramName = paramNameNode.getString(in: source),
            let paramTypeNode = node.child(byFieldName: "type"),
            let paramType = Syntax.TypeIdentifier(from: paramTypeNode, in: source),
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

extension Syntax.TypeDefinition {
    init?(from node: Node, in source: Syntax.Source) {
        guard let child = node.child(at: 1) else { return nil }
        switch child.nodeType {
        case CodingKeys.sum.rawValue:
            guard let sum = Sum(from: child, in: source) else { return nil }
            self = .sum(sum)
        case CodingKeys.simple.rawValue:
            guard let simple = Simple(from: child, in: source) else { return nil }
            self = .simple(simple)
        default:
            return nil
        }
    }

    enum CodingKeys: String, CodingKey {
        case simple = "simple_type_definition"
        case sum = "meta_type_definition"
    }
}

extension Syntax.TypeDefinition.Simple {

    init?(from node: Node, in source: Syntax.Source) {
        guard let identifierNode = node.child(at: 0),
            let identifier = Syntax.NominalType(from: identifierNode, in: source),
            let location = node.getLocation(in: source)
        else { return nil }
        self.identifier = identifier

        if let paramListNode = node.child(at: 1) {
            self.params = paramListNode.compactMapChildren { paramNode in
                if paramNode.nodeType == Syntax.ParamDefinition.rawValue {
                    return Syntax.ParamDefinition(from: paramNode, in: source)
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

extension Syntax.TypeDefinition.Sum {

    init?(from node: Node, in source: Syntax.Source) {
        guard let identifierNode = node.child(at: 0),
            let identifier = Syntax.NominalType(from: identifierNode, in: source),
            let location = node.getLocation(in: source)
        else { return nil }
        self.identifier = identifier
        self.cases = node.compactMapChildren { childNode in
            if childNode.nodeType == Syntax.TypeDefinition.CodingKeys.simple.rawValue {
                return Syntax.TypeDefinition.Simple(from: childNode, in: source)
            }
            return nil
        }
        self.location = location
    }
}

// MARK: - function definitions
// ----------------------------

extension Syntax.FunctionDefinition {

    enum CodingKeys: String, CodingKey {
        case inputType = "input_type"
        case functionIdentifier = "function_identifier"
        case params
        case outputType = "output_type"
        case body

        static let scope = "scope"
        static let name = "name"
    }

    init?(from node: Node, in source: Syntax.Source) {
        guard let location = node.getLocation(in: source) else { return nil }
        self.location = location

        if let child = node.child(byFieldName: CodingKeys.inputType.rawValue) {
            guard let typeIdentifier = Syntax.TypeIdentifier(from: child, in: source) else { return nil }
            self.inputType = typeIdentifier
        } else {
            self.inputType = nil
        }
        let scope: Syntax.NominalType?
        if let child = node.child(byFieldName: CodingKeys.scope) {
            scope = Syntax.NominalType(from: child, in: source)
        } else {
            scope = nil
        }

        guard let child = node.child(byFieldName: CodingKeys.name),
            let name = child.getString(in: source)
        else {
            return nil
        }
        self.functionIdentifier = Syntax.FunctionIdentifier(scope: scope, name: name)

        self.params =
            if let child = node.child(byFieldName: CodingKeys.params.rawValue) {
                child.compactMapChildren { paramNode in
                    if paramNode.nodeType == Syntax.ParamDefinition.rawValue {
                        return Syntax.ParamDefinition(from: paramNode, in: source)
                    } else {
                        return nil
                    }
                }
            } else {
                []
            }
        guard let child = node.child(byFieldName: CodingKeys.outputType.rawValue),
            let outputType = Syntax.TypeIdentifier(from: child, in: source)
        else {
            return nil
        }
        self.outputType = outputType
        if let child = node.child(byFieldName: CodingKeys.body.rawValue),
            let body = Syntax.Expression(from: child, in: source)
        {
            self.body = body
        } else {
            self.body = nil
        }
    }
}

extension Syntax.OperatorOverloadDefinition {
    enum CodingKeys: String, CodingKey {
        case left = "left_type"
        case right = "right_type"
        case op = "operator"
        case outputType = "output_type"
        case body
    }

    init?(from node: Node, in source: Syntax.Source) {
        guard let location = node.getLocation(in: source) else { return nil }
        self.location = location

        guard let child = node.child(byFieldName: CodingKeys.left.rawValue),
            let leftParamDefinition = Syntax.ParamDefinition(from: child, in: source) else { return nil }
        self.left = leftParamDefinition.type
        

        guard let child = node.child(byFieldName: CodingKeys.op.rawValue),
            let name = child.getString(in: source),
            let op = Operator(rawValue: name) else { return nil }
        self.op = op

        guard let child = node.child(byFieldName: CodingKeys.right.rawValue),
            let rightParamDefinition = Syntax.ParamDefinition(from: child, in: source) else { return nil }
        self.right = rightParamDefinition.type
        
        guard let child = node.child(byFieldName: CodingKeys.outputType.rawValue),
            let outputType = Syntax.TypeIdentifier(from: child, in: source)
        else {
            return nil
        }
        self.outputType = outputType
        if let child = node.child(byFieldName: CodingKeys.body.rawValue),
            let body = Syntax.Expression(from: child, in: source)
        {
            self.body = body
        } else {
            self.body = nil
        }
    }
}

// MARK: - types
// -------------

extension Syntax.TypeIdentifier {
    static let typeIdentifier = "type_identifier"

    enum CodingKeys: String, CodingKey {
        case unkown = "unkown"
        case nothing = "nothing"
        case never = "never"
        case nominal = "nominal_type"
        case lambda = "lambda_structural_type"
        case namedTuple = "named_tuple_structural_type"
        case unnamedTuple = "unnamed_tuple_structural_type"
        case union = "Union"
    }

    init?(from node: Node, in source: Syntax.Source) {
        guard let child = node.child(at: 0),
            let location = child.getLocation(in: source) else { return nil }


        switch child.nodeType {
        case CodingKeys.nothing.rawValue:
            self = .nothing(location: location)
        case CodingKeys.never.rawValue:
            self = .never(location: location)
        case CodingKeys.nominal.rawValue:
            guard let nominal = Syntax.NominalType(from: child, in: source) else { return nil }
            if nominal.chain.count == 1, 
                let union = nominal.chain.first, 
                union.typeName == CodingKeys.union.rawValue && union.typeArguments.count > 0
            {
                self = .union(Syntax.UnionType(types: union.typeArguments, location: location))
            } else {
                self = .nominal(nominal)
            }
        case CodingKeys.lambda.rawValue:
            guard let lambda = Syntax.StructuralType.Lambda(from: child, in: source) else { return nil }
            self = .lambda(lambda)
        case CodingKeys.namedTuple.rawValue:
            guard let tuple = Syntax.StructuralType.NamedTuple(from: child, in: source) else { return nil }
            self = .namedTuple(tuple)
        case CodingKeys.unnamedTuple.rawValue:
            guard let tuple = Syntax.StructuralType.UnnamedTuple(from: child, in: source) else { return nil }
            self = .unnamedTuple(tuple)
        default:
            return nil
        }
    }
}

extension Syntax.NominalType {
    init?(from node: Node, in source: Syntax.Source) {
        guard let location = node.getLocation(in: source) else { return nil }
        self.location = location
        self.chain = node.compactMapChildren { child in
            if child.nodeType == Syntax.NominalType.flatNominalType {
                return Syntax.FlatNominalType(from: child, in: source)
            } else {
                return nil
            }
        }
    }
}

extension Syntax.FlatNominalType {
    init?(from node: Node, in source: Syntax.Source) {
        guard let typeNameNode = node.child(byFieldName: Syntax.FlatNominalType.typeName),
            let typeName = typeNameNode.getString(in: source),
            let location = node.getLocation(in: source) else { return nil }
        self.location = location
        self.typeName = typeName

        if let typeArgumentsNode = node.child(byFieldName: Syntax.FlatNominalType.typeArguments) {
            self.typeArguments = typeArgumentsNode.compactMapChildren { typeArgumentChild in
                if typeArgumentChild.nodeType == Syntax.TypeIdentifier.typeIdentifier {
                    Syntax.TypeIdentifier(from: typeArgumentChild, in: source)
                } else {
                    nil
                }
            }
        } else {
            self.typeArguments = []
        }
    }
}

extension Syntax.StructuralType.UnnamedTuple {
    init?(from node: Node, in source: Syntax.Source) {
        guard let location = node.getLocation(in: source) else { return nil }
        self.location = location
        self.types = node.compactMapChildren { child in
            if child.nodeType == Syntax.TypeIdentifier.typeIdentifier {
                return Syntax.TypeIdentifier(from: child, in: source)
            }
            return nil
        }
    }
}

extension Syntax.StructuralType.NamedTuple {
    init?(from node: Node, in source: Syntax.Source) {
        guard let location = node.getLocation(in: source) else { return nil }
        self.location = location
        self.types = node.compactMapChildren { child in
            if child.nodeType == Syntax.ParamDefinition.rawValue {
                return Syntax.ParamDefinition(from: child, in: source)
            }
            return nil
        }
    }
}

extension Syntax.StructuralType.Lambda {

    init?(from node: Node, in source: Syntax.Source) {
        guard let location = node.getLocation(in: source) else { return nil }
        self.location = location
        self.input = node.compactMapChildrenEnumerated { (index, child) in
            if child.nodeType == Syntax.TypeIdentifier.typeIdentifier && index < node.childCount - 1 {
                return Syntax.TypeIdentifier(from: child, in: source)
            }
            return nil
        }
        guard let outputNode = node.child(at: node.childCount - 1),
            let output = Syntax.TypeIdentifier(from: outputNode, in: source)
        else { return nil }
        self.output = [output]
    }
}

// MARK: - Expressions
// -------------------
extension Syntax.Expression {
    static let parenthesized = "parenthisized_expression"

    init?(from node: Node, in source: Syntax.Source) {
        guard let location = node.getLocation(in: source) else { return nil }
        self.location = location
        if node.nodeType == Syntax.Expression.parenthesized {
            guard let child = node.child(at: 1),
                  let expressionType = Syntax.Expression.ExpressionType(from: child, in: source) else { return nil }
            self.expressionType = expressionType
        } else {
            guard let expressionType = Syntax.Expression.ExpressionType(from: node, in: source) else { return nil }
            self.expressionType = expressionType
        }
    }
}

extension Syntax.Expression.ExpressionType {

    enum CodingKeys: String, CodingKey {
        case nothing
        case never

        case intLiteral = "int_literal"
        case floatLiteral = "float_literal"
        case stringLiteral = "string_literal"
        case boolLiteral = "bool_literal"

        case unary = "unary_expression"
        case binary = "binary_expression"

        case unnamedTuple = "unnamed_tuple_literal"
        case namedTuple = "named_tuple_literal"
        case lambda = "lambda_expression"


        case call = "call_expression"
        case access = "access_expression"
        case field = "argument_name"

        case branched = "branched_expression"
        case piped = "piped_expression"

    }

    init?(from node: Node, in source: Syntax.Source) {
        switch node.nodeType {
        case CodingKeys.nothing.rawValue:
            self = .nothing
        case CodingKeys.never.rawValue:
            self = .never
        case CodingKeys.intLiteral.rawValue:
            guard let intText = node.getString(in: source),
                  let intValue = UInt64(intText) else { return nil } // WARN: check for hex strings
            self = .intLiteral(intValue)
        case CodingKeys.floatLiteral.rawValue:
            guard let floatText = node.getString(in: source),
                  let floatValue = Double(floatText) else { return nil }
            self = .floatLiteral(floatValue)
        case CodingKeys.stringLiteral.rawValue:
            guard let stringValue = node.getString(in: source) else { return nil }
            self = .stringLiteral(String(stringValue.dropFirst().dropLast()))
        case CodingKeys.boolLiteral.rawValue:
            guard let boolText = node.getString(in: source),
                  let boolValue = Bool(boolText) else { return nil }
            self = .boolLiteral(boolValue)
        case CodingKeys.unary.rawValue:
            guard let operatorNode = node.child(byFieldName: "operator"),
                  let operatorValue = operatorNode.getString(in: source),
                  let operandNode = node.child(byFieldName: "operand"),
                  let operandExpression = Syntax.Expression(from: operandNode, in: source) else {
                return nil
            }
            switch operatorValue {
            case "+":
                self = .unary(.plus, expression: operandExpression)
            case "-":
                self = .unary(.minus, expression: operandExpression)
            case "*":
                self = .unary(.times, expression: operandExpression)
            case "/":
                self = .unary(.by, expression: operandExpression)
            case "%":
                self = .unary(.modulo, expression: operandExpression)
            case "and":
                self = .unary(.and, expression: operandExpression)
            case "or":
                self = .unary(.or, expression: operandExpression)
            case "not":
                self = .unary(.not, expression: operandExpression)
            default:
                return nil
            }
        case CodingKeys.binary.rawValue:
            guard let leftNode = node.child(byFieldName: "left"),
                  let leftExpression = Syntax.Expression(from: leftNode, in: source),
                  let operatorNode = node.child(byFieldName: "operator"),
                  let operatorValue = operatorNode.getString(in: source),
                  let rightNode = node.child(byFieldName: "right"),
                  let rightExpression = Syntax.Expression(from: rightNode, in: source) else {
                return nil
            }
            switch operatorValue {
            case "+":
                self = .binary(.plus, left: leftExpression, right: rightExpression)
            case "-":
                self = .binary(.minus, left: leftExpression, right: rightExpression)
            case "*":
                self = .binary(.times, left: leftExpression, right: rightExpression)
            case "/":
                self = .binary(.by, left: leftExpression, right: rightExpression)
            case "%":
                self = .binary(.modulo, left: leftExpression, right: rightExpression)
            case "=":
                self = .binary(.equal, left: leftExpression, right: rightExpression)
            case "!=":
                self = .binary(.different, left: leftExpression, right: rightExpression)
            case "<":
                self = .binary(.lessThan, left: leftExpression, right: rightExpression)
            case "<=":
                self = .binary(.lessThanOrEqual, left: leftExpression, right: rightExpression)
            case ">":
                self = .binary(.greaterThan, left: leftExpression, right: rightExpression)
            case ">=":
                self = .binary(.greaterThanOrEqual, left: leftExpression, right: rightExpression)
            case "or":
                self = .binary(.or, left: leftExpression, right: rightExpression)
            case "and":
                self = .binary(.and, left: leftExpression, right: rightExpression)
            default:
                return nil
            }
        case CodingKeys.unnamedTuple.rawValue:
            let expressions = node.compactMapChildren { node in
                Syntax.Expression(from: node, in: source)
            }
            self = .unnamedTuple(expressions)
        case CodingKeys.namedTuple.rawValue:
            let arguments = node.compactMapChildren { node in
                Syntax.Expression.Argument(from: node, in: source)
            }
            self = .namedTuple(arguments)
        case CodingKeys.lambda.rawValue:
            guard let expressionNode = node.child(at: 1),
                  let expression = Syntax.Expression(from: expressionNode, in: source) else { return nil }
            self = .lambda(expression)
        case CodingKeys.call.rawValue:
            guard let call = Syntax.Expression.Call(from: node, in: source) else { return nil }
            self = .call(call)
        case CodingKeys.access.rawValue:
            guard let accessedNode = node.child(at: 0),
                  let accessed = Syntax.Expression.Prefix(from: accessedNode, in: source),
                  let argumentNode = node.child(at: 2),
                  let argumentName = argumentNode.getString(in: source),
                  let location = node.getLocation(in: source) else { return nil }
            self = .access(Syntax.Expression.Access(accessed: accessed, field: argumentName, location: location))
        case CodingKeys.field.rawValue:
            guard let fieldValue = node.getString(in: source) else { return nil }
            self = .field(fieldValue)
        case CodingKeys.branched.rawValue:
            guard let branched = Syntax.Expression.Branched(from: node, in: source) else { return nil }
            self = .branched(branched)
        case CodingKeys.piped.rawValue:
            guard let leftNode = node.child(byFieldName: "left"),
                  let left = Syntax.Expression(from: leftNode, in: source) else { return nil }
            guard let rightNode = node.child(byFieldName: "right"),
                  let right = Syntax.Expression(from: rightNode, in: source) else { return nil }
            self = .piped(left: left, right: right)
        default:
            return nil
        }
    }
}

extension Syntax.Expression.Call {
    init?(from node: Node, in source: Syntax.Source) {
        guard let location = node.getLocation(in: source) else { return nil }
        self.location = location
        guard let commandNode = node.child(byFieldName: "command"),
              let command = Syntax.Expression.Prefix(from: commandNode, in: source) else { return nil }
        self.command = command

        if let paramListNode = node.child(byFieldName: "params") {
            self.arguments = paramListNode.compactMapChildren { child in
                Syntax.Expression.Argument(from: child, in: source)
            }
        } else {
            self.arguments = []
        }
    }
}

extension Syntax.Expression.Prefix {

    enum CodingKeys: String, CodingKey {
        case simple
        case type = "nominal_type"
    }

    init?(from node: Node, in source: Syntax.Source) {
        switch node.nodeType {
        case CodingKeys.type.rawValue:
            guard let type = Syntax.NominalType(from: node, in: source) else { return nil }
            self = .type(type)
        default:
            guard let expression = Syntax.Expression(from: node, in: source) else { return nil }
            self = .simple(expression)
        }
    }
}

extension Syntax.Expression.Argument {
    init?(from node: Node, in source: Syntax.Source) {
        guard let location = node.getLocation(in: source) else { return nil }
        self.location = location

        guard let nameNode = node.child(byFieldName: "name"),
              let name = nameNode.getString(in: source) else { return nil }
        self.name = name

        guard let valueNode = node.child(byFieldName: "value"),
              let value = Syntax.Expression(from: valueNode, in: source) else { return nil }
        self.value = value
    }
}

extension Syntax.Expression.Branched {
    static let branch = "branch_expression"

    init?(from node: Node, in source: Syntax.Source) {
        guard let location = node.getLocation(in: source) else { return nil }
        self.location = location

        self.branches = node.compactMapChildren { child in
            if child.nodeType == Syntax.Expression.Branched.branch {
                Syntax.Expression.Branched.Branch(from: child, in: source)
            } else {
                nil
            }
        }
        self.lastBranch = if let lastChild = node.lastChild,
            lastChild.nodeType != Syntax.Expression.Branched.branch {
            Syntax.Expression(from: lastChild, in: source)
        } else {
            nil
        }
    }
}

extension Syntax.Expression.Branched.Branch {

    init?(from node: Node, in source: Syntax.Source) {
        guard let location = node.getLocation(in: source) else { return nil }
        self.location = location

        guard let captureGroupNode = node.child(byFieldName: "capture_group") else { return nil }
        self.captureGroup = captureGroupNode.compactMapChildren { child in
            CaptureGroup(from: child, in: source)
        }

        guard let bodyNode = node.child(byFieldName: "body"),
              let body = Body(from: bodyNode, in: source) else { return nil }
        self.body = body
    }
}

extension Syntax.Expression.Branched.Branch.CaptureGroup {
    
    enum CodingKeys: String, CodingKey {
        case type = "nominal_type"
        case paramDefinition = "param_definition"
        case argument = "call_param"
        case simple
    }
    
    init?(from node: Node, in source: Syntax.Source) {
        switch node.nodeType {
        case CodingKeys.type.rawValue:
            guard let nominalType = Syntax.NominalType(from: node, in: source) else { return nil }
            self = .type(nominalType)
        case CodingKeys.paramDefinition.rawValue:
            guard let paramDefinition = Syntax.ParamDefinition(from: node, in: source) else { return nil }
            self = .paramDefinition(paramDefinition)
        case CodingKeys.argument.rawValue:
            guard let argument = Syntax.Expression.Argument(from: node, in: source) else { return nil }
            self = .argument(argument)
        default:
            guard let expression = Syntax.Expression(from: node, in: source) else { return nil }
            self = .simple(expression)
        }
    }
}

extension Syntax.Expression.Branched.Branch.Body {

    enum CodingKeys: String, CodingKey {
        case simple
        case looped = "looped_expression"
    }

    init?(from node: Node, in source: Syntax.Source) {
        switch node.nodeType {
        case CodingKeys.looped.rawValue:
            guard let loopedNode = node.child(at: 0),
                  let parenthisizedNode = loopedNode.child(at: 1),
                  let expression = Syntax.Expression(from: parenthisizedNode, in: source) else { return nil }
            self = .looped(expression)
        default:
            guard let simple = Syntax.Expression(from: node, in: source) else { return nil }
            self = .simple(simple)
        }
    }
}
