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
        guard
            let range = Swift.Range(
                self.range,
                in: source.content)
        else { return nil }
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
            let outputString = String(
                data: outputData, encoding: .utf8)
        else {
            throw SyntaxError.sourceUnreadable
        }
        try self.init(source: outputString, path: path)
    }
}

extension Syntax.Statement {
    enum CodingKeys: String, CodingKey {
        case typeDefinition = "type_definition"
        case valueField = "value_field"
    }

    init?(from node: Node, in source: Syntax.Source) {
        switch CodingKeys(rawValue: node.nodeType ?? "") {
        case .typeDefinition:
            guard
                let typeDefinition = Syntax.TypeDefinition(
                    from: node,
                    in: source)
            else { return nil }
            self = .typeDefinition(typeDefinition)
        case .valueField:
            return nil
        default:
            return nil
        }
    }
}

// MARK: - type definitions
// ------------------------

extension Syntax.TypeField {
    static let rawValue = "param_definition"

    init?(from node: Node, in source: Syntax.Source) {
        guard let identifierNode = node.child(byFieldName: "identifier"),
            let identifier = identifierNode.getString(in: source),
            let definitionNode = node.child(byFieldName: "definition"),
            let definition = Syntax.TypeSpecifier(
                from: definitionNode,
                in: source),
            let location = node.getLocation(in: source)
        else { return nil }

        self.type = definition
        self.identifier = identifier

        self.location = location
    }
}

extension Syntax.TypeDefinition {
    init?(from node: Node, in source: Syntax.Source) {
        guard let identifierNode = node.child(byFieldName: "identifier"),
            let identifier = identifierNode.getString(in: source),
            let definitionNode = node.child(byFieldName: "definition"),
            let definition = Syntax.TypeSpecifier(
                from: definitionNode,
                in: source),
            let location = node.getLocation(in: source)
        else { return nil }

        self.definition = definition
        self.identifier = identifier
        self.location = location
    }
}

// MARK: - function definitions
// ----------------------------

extension Syntax.ScopedIdentifier {
    static let scope = "scope"
    static let name = "name"

    init?(from node: Node, in source: Syntax.Source) {
        guard let location = node.getLocation(in: source) else {
            return nil
        }
        self.location = location

        if let scope = node.child(byFieldName: Self.scope) {
            self.scope = Syntax.NominalType(from: scope, in: source)
        } else {
            self.scope = nil
        }
        guard let identifier = node.child(byFieldName: Self.name),
            let identifierValue = identifier.getString(in: source)
        else { return nil }
        self.identifier = identifierValue
    }
}

extension Syntax.FunctionDefinition {

    enum CodingKeys: String, CodingKey {
        case inputType = "input_type"
        case name = "name"
        case params
        case outputType = "output_type"
        case body
    }

    init?(from node: Node, in source: Syntax.Source) {
        guard let location = node.getLocation(in: source) else {
            return nil
        }
        self.location = location

        if let child = node.child(
            byFieldName: CodingKeys.inputType.rawValue)
        {
            guard
                let typeIdentifier = Syntax.TypeSpecifier(
                    from: child,
                    in: source)
            else { return nil }
            self.inputType = typeIdentifier
        } else {
            self.inputType = nil
        }

        guard
            let child = node.child(
                byFieldName: CodingKeys.name.rawValue),
            let name = Syntax.ScopedIdentifier(
                from: child, in: source)
        else { return nil }

        self.identifier = name

        self.params =
            if let child = node.child(
                byFieldName: CodingKeys.params.rawValue)
            {
                child.compactMapChildren { paramNode in
                    if paramNode.nodeType
                        == Syntax.ParamDefinition
                        .rawValue
                    {
                        return Syntax.ParamDefinition(
                            from: paramNode,
                            in: source)
                    } else {
                        return nil
                    }
                }
            } else {
                []
            }
        guard
            let child = node.child(
                byFieldName: CodingKeys.outputType.rawValue),
            let outputType = Syntax.TypeSpecifier(
                from: child, in: source)
        else {
            return nil
        }
        self.outputType = outputType
        if let child = node.child(
            byFieldName: CodingKeys.body.rawValue),
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
        guard let location = node.getLocation(in: source) else {
            return nil
        }
        self.location = location

        guard
            let child = node.child(
                byFieldName: CodingKeys.left.rawValue),
            let leftParamDefinition = Syntax.ParamDefinition(
                from: child,
                in: source)
        else { return nil }
        self.left = leftParamDefinition.type

        guard
            let child = node.child(
                byFieldName: CodingKeys.op.rawValue),
            let name = child.getString(in: source),
            let op = Operator(rawValue: name)
        else { return nil }
        self.op = op

        guard
            let child = node.child(
                byFieldName: CodingKeys.right.rawValue),
            let rightParamDefinition = Syntax.ParamDefinition(
                from: child,
                in: source)
        else { return nil }
        self.right = rightParamDefinition.type

        guard
            let child = node.child(
                byFieldName: CodingKeys.outputType.rawValue),
            let outputType = Syntax.TypeSpecifier(
                from: child,
                in: source)
        else { return nil }
        self.outputType = outputType

        if let child = node.child(
            byFieldName: CodingKeys.body.rawValue),
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

extension Syntax.TypeSpecifier {

    enum CodingKeys: String, CodingKey {
        case nothing = "nothing_type"
        case never = "never_type"
        case product = "product"
        case sum = "sum"
        case subset = "subset"
        case existential = "some"
        case universal = "any"
        case nominal = "nominal"
        case function = "function"
    }

    init?(from node: Node, in source: Syntax.Source) {
        guard let location = node.getLocation(in: source) else {
            return nil
        }

        switch CodingKeys(rawValue: node.nodeType ?? "") {
        case .nothing:
            self = .nothing(location: location)
        case .never:
            self = .never(location: location)
        case .product:
            guard let typeFieldList = node.child(at: 0),
            
        default:
            return nil
        }
    }
}

extension Syntax.NominalType {
    static let typeIdentifier = "name"
    static let typeScope = "scope"

    static func getNominalTypeName(
        node: Node,
        in source: Syntax.Source
    ) -> [String]? {
        guard let name = node.child(byFieldName: Self.typeIdentifier),
            let nameValue = name.getString(in: source)
        else { return nil }

        if let scope = node.child(byFieldName: Self.typeScope),
            let scopeValue = getNominalTypeName(
                node: scope, in: source)
        {
            return scopeValue + [nameValue]
        }

        return [nameValue]
    }

    init?(from node: Node, in source: Syntax.Source) {
        guard let location = node.getLocation(in: source) else {
            return nil
        }
        self.location = location
        guard
            let chain = Self.getNominalTypeName(
                node: node,
                in: source)
        else { return nil }
        self.chain = chain
    }
}

extension Syntax.StructuralType.UnnamedTuple {
    init?(from node: Node, in source: Syntax.Source) {
        guard let location = node.getLocation(in: source) else {
            return nil
        }
        self.location = location
        self.types = node.compactMapChildren { child in
            return Syntax.TypeSpecifier(from: child, in: source)
        }
    }
}

extension Syntax.StructuralType.NamedTuple {
    init?(from node: Node, in source: Syntax.Source) {
        guard let location = node.getLocation(in: source) else {
            return nil
        }
        self.location = location
        self.types = node.compactMapChildren { child in
            if child.nodeType == Syntax.ParamDefinition.rawValue {
                return Syntax.ParamDefinition(
                    from: child, in: source)
            }
            return nil
        }
    }
}

// MARK: - Expressions
// -------------------
extension Syntax.Expression {
    static let parenthesized = "parenthisized_expression"

    init?(from node: Node, in source: Syntax.Source) {
        guard let location = node.getLocation(in: source) else {
            return nil
        }
        self.location = location
        if node.nodeType == Syntax.Expression.parenthesized {
            guard let child = node.child(at: 1),
                let expressionType = Syntax.Expression
                    .ExpressionType(
                        from: child,
                        in: source)
            else { return nil }
            self.expressionType = expressionType
        } else {
            guard
                let expressionType = Syntax.Expression
                    .ExpressionType(
                        from: node,
                        in: source)
            else { return nil }
            self.expressionType = expressionType
        }
    }
}

extension Syntax.Expression.Literal {
    enum CodingKeys: String, CodingKey {
        case nothing
        case never

        case intLiteral = "int_literal"
        case floatLiteral = "float_literal"
        case stringLiteral = "string_literal"
        case boolLiteral = "bool_literal"
    }

    init?(from node: Node, in source: Syntax.Source) {
        switch CodingKeys(rawValue: node.child(at: 0)?.nodeType ?? "") {
        case .nothing:
            self = .nothing
        case .never:
            self = .never
        case .intLiteral:
            guard let intText = node.getString(in: source),
                let intValue = UInt64(intText)
            else { return nil }
            self = .intLiteral(intValue)
        case .floatLiteral:
            guard let floatText = node.getString(in: source),
                let floatValue = Double(floatText)
            else { return nil }
            self = .floatLiteral(floatValue)
        case .stringLiteral:
            guard
                let stringValue = node.getString(
                    in: source)
            else { return nil }
            self = .stringLiteral(
                String(stringValue.dropFirst().dropLast()))
        case .boolLiteral:
            guard let boolText = node.getString(in: source),
                let boolValue = Bool(boolText)
            else { return nil }
            self = .boolLiteral(boolValue)
        case .none:
            return nil
        }
    }
}

extension Syntax.Expression.ExpressionType {

    enum CodingKeys: String, CodingKey {
        case literal

        case unary = "unary_expression"
        case binary = "binary_expression"

        case unnamedTuple = "unnamed_tuple_literal"
        case namedTuple = "named_tuple_literal"

        case functionCall = "function_call_expression"
        case typeInitializer = "type_initializer_expression"
        case access = "access_expression"
        case field = "scoped_identifier"

        case branched = "branched_expression"
        case piped = "piped_expression"

    }

    static func parseLiteral(
        from node: Node,
        in source: Syntax.Source
    ) -> Self? {
        guard
            let literal = Syntax.Expression.Literal(
                from: node,
                in: source)
        else { return nil }
        return .literal(literal)
    }

    static func parseUnary(
        from node: Node,
        in source: Syntax.Source
    ) -> Self? {
        guard let operatorNode = node.child(byFieldName: "operator"),
            let operatorText = operatorNode.getString(in: source),
            let operandNode = node.child(byFieldName: "operand"),
            let operandExpression = Syntax.Expression(
                from: operandNode,
                in: source),
            let operatorValue = Operator(rawValue: operatorText)
        else {
            return nil
        }
        return .unary(operatorValue, expression: operandExpression)
    }

    static func parseBinary(
        from node: Node,
        in source: Syntax.Source
    ) -> Self? {
        guard let leftNode = node.child(byFieldName: "left"),
            let leftExpression = Syntax.Expression(
                from: leftNode,
                in: source),
            let operatorNode = node.child(byFieldName: "operator"),
            let operatorText = operatorNode.getString(in: source),
            let rightNode = node.child(byFieldName: "right"),
            let rightExpression = Syntax.Expression(
                from: rightNode,
                in: source),
            let operatorValue = Operator(rawValue: operatorText)
        else {
            return nil
        }
        return .binary(
            operatorValue,
            left: leftExpression,
            right: rightExpression)
    }

    static func parseUnnamedTuple(
        from node: Node,
        in source: Syntax.Source
    ) -> Self? {
        let expressions = node.compactMapChildren { node in
            Syntax.Expression(from: node, in: source)
        }
        return .unnamedTuple(expressions)
    }

    static func parseNamedTuple(
        from node: Node,
        in source: Syntax.Source
    ) -> Self? {
        let arguments = node.compactMapChildren { node in
            Syntax.Expression.Argument(from: node, in: source)
        }
        return .namedTuple(arguments)
    }

    static func parseFunctionCall(
        from node: Node,
        in source: Syntax.Source
    ) -> Self? {
        guard let prefixNode = node.child(byFieldName: "prefix"),
            let prefix = Syntax.Expression(
                from: prefixNode, in: source)
        else { return nil }

        let arguments: [Syntax.Expression.Argument] =
            if let argumentList = node.child(
                byFieldName: "arguments")
            {
                argumentList.compactMapChildren { child in
                    Syntax.Expression.Argument(
                        from: child, in: source)
                }
            } else {
                []
            }
        return .functionCall(prefix: prefix, arguments: arguments)
    }

    static func parseTypeInitializer(
        from node: Node,
        in source: Syntax.Source
    ) -> Self? {
        guard let prefixNode = node.child(byFieldName: "prefix"),
            let prefix = Syntax.NominalType(
                from: prefixNode, in: source)
        else { return nil }

        let arguments: [Syntax.Expression.Argument] =
            if let argumentList = node.child(
                byFieldName: "arguments")
            {
                argumentList.compactMapChildren { child in
                    Syntax.Expression.Argument(
                        from: child, in: source)
                }
            } else {
                []
            }
        return .typeInitializer(prefix: prefix, arguments: arguments)
    }

    static func parseAccess(
        from node: Node,
        in source: Syntax.Source
    ) -> Self? {
        guard let prefixNode = node.child(byFieldName: "prefix"),
            let prefix = Syntax.Expression(
                from: prefixNode, in: source),
            let fieldNode = node.child(byFieldName: "field"),
            let field = fieldNode.getString(in: source)
        else { return nil }
        return .access(prefix: prefix, field: field)
    }

    static func parseField(
        from node: Node,
        in source: Syntax.Source
    ) -> Self? {
        guard
            let scopedIdenfier = Syntax.ScopedIdentifier(
                from: node,
                in: source)
        else { return nil }
        return .field(scopedIdenfier)
    }

    static func parseBranched(
        from node: Node,
        in source: Syntax.Source
    ) -> Self? {
        guard
            let branched = Syntax.Expression.Branched(
                from: node,
                in: source)
        else { return nil }
        return .branched(branched)
    }

    static func parsePiped(
        from node: Node,
        in source: Syntax.Source
    ) -> Self? {
        guard let leftNode = node.child(byFieldName: "left"),
            let left = Syntax.Expression(from: leftNode, in: source)
        else { return nil }
        guard let rightNode = node.child(byFieldName: "right"),
            let right = Syntax.Expression(
                from: rightNode, in: source)
        else { return nil }
        return .piped(left: left, right: right)
    }

    init?(from node: Node, in source: Syntax.Source) {
        guard
            let expressionType =
                switch CodingKeys(rawValue: node.nodeType ?? "") {
                case .literal:
                    Self.parseLiteral(from: node, in: source)
                case .unary:
                    Self.parseUnary(from: node, in: source)
                case .binary:
                    Self.parseBinary(from: node, in: source)
                case .unnamedTuple:
                    Self.parseUnnamedTuple(from: node, in: source)
                case .namedTuple:
                    Self.parseNamedTuple(from: node, in: source)
                case .functionCall:
                    Self.parseFunctionCall(from: node, in: source)
                case .typeInitializer:
                    Self.parseTypeInitializer(from: node, in: source)
                case .access:
                    Self.parseAccess(from: node, in: source)
                case .field:
                    Self.parseField(from: node, in: source)
                case .branched:
                    Self.parseBranched(from: node, in: source)
                case .piped:
                    Self.parsePiped(from: node, in: source)
                default:
                    nil
                } else { return nil }
        self = expressionType
    }
}

extension Syntax.Expression.Argument {
    init?(from node: Node, in source: Syntax.Source) {
        guard let location = node.getLocation(in: source) else {
            return nil
        }
        self.location = location

        guard let nameNode = node.child(byFieldName: "name"),
            let name = nameNode.getString(in: source)
        else { return nil }
        self.name = name

        guard let valueNode = node.child(byFieldName: "value"),
            let value = Syntax.Expression(
                from: valueNode, in: source)
        else { return nil }
        self.value = value
    }
}

extension Syntax.Expression.Branched {
    static let branch = "branch_expression"

    init?(from node: Node, in source: Syntax.Source) {
        guard let location = node.getLocation(in: source) else {
            return nil
        }
        self.location = location

        self.branches = node.compactMapChildren { child in
            if child.nodeType == Syntax.Expression.Branched.branch {
                Syntax.Expression.Branched.Branch(
                    from: child, in: source)
            } else {
                nil
            }
        }
    }
}

extension Syntax.Expression.Branched.Branch {

    init?(from node: Node, in source: Syntax.Source) {
        guard let location = node.getLocation(in: source) else {
            return nil
        }
        self.location = location

        guard
            let matchExpressionNode = node.child(
                byFieldName: "match_expression"),
            let matchExpression = MatchExpression(
                from: matchExpressionNode,
                in: source)
        else { return nil }
        self.matchExpression = matchExpression

        if let guardNode = node.child(byFieldName: "guard_expression") {
            self.guardExpression = Syntax.Expression(
                from: guardNode,
                in: source)
        } else {
            self.guardExpression = nil
        }

        guard let bodyNode = node.child(byFieldName: "body"),
            let body = Body(from: bodyNode, in: source)
        else { return nil }
        self.body = body
    }
}

extension Syntax.Expression.Branched.Branch.MatchExpression {

    enum CodingKeys: String, CodingKey {
        case literal = "literal"
        case field = "scoped_identifier"
        case binding = "binding_name"
        case tupleBinding = "tuple_binding_literal"
        case typeBinding = "type_binding"
    }

    init?(from node: Node, in source: Syntax.Source) {
        switch CodingKeys(rawValue: node.nodeType ?? "") {
        case .literal:
            guard
                let literal = Syntax.Expression.Literal(
                    from: node,
                    in: source)
            else { return nil }
            self = .literal(literal)
        case .field:
            guard
                let scopedIdentifier = Syntax.ScopedIdentifier(
                    from: node,
                    in: source)
            else { return nil }
            self = .field(scopedIdentifier)
        case .binding:
            guard let bindingValue = node.getString(in: source)
            else {
                return nil
            }
            self = .binding(String(bindingValue.dropFirst()))
        case .tupleBinding:
            let matchExpressions = node.compactMapChildren { child in
                Syntax.Expression.Branched.Branch.MatchExpression(
                    from: child,
                    in: source)
            }
            self = .tupleBinding(matchExpressions)
        case .typeBinding:
            guard
                let prefixNode = node.child(
                    byFieldName: "prefix"),
                let prefix = Syntax.NominalType(
                    from: prefixNode,
                    in: source)
            else { return nil }

            let arguments: [Syntax.Expression.Branched.Branch.BindingArgument] =
                if let argumentList = node.child(
                    byFieldName: "arguments")
                {
                    argumentList.compactMapChildren { child in
                        Syntax.Expression.Branched.Branch.BindingArgument(
                            from: child,
                            in: source)
                    }
                } else {
                    []
                }
            self = .typeBinding(
                prefix: prefix, arguments: arguments)
        default:
            return nil
        }
    }
}

extension Syntax.Expression.Branched.Branch.BindingArgument {
    static let name = "name"
    static let value = "value"

    init?(from node: Node, in source: Syntax.Source) {
        guard let location = node.getLocation(in: source) else {
            return nil
        }
        self.location = location

        guard let nameNode = node.child(byFieldName: Self.name),
            let name = nameNode.getString(in: source)
        else { return nil }
        self.name = name

        guard let valueNode = node.child(byFieldName: Self.value),
            let value = Syntax.Expression.Branched.Branch
                .MatchExpression(
                    from: valueNode,
                    in: source)
        else { return nil }
        self.value = value
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
                let expression = Syntax.Expression(
                    from: parenthisizedNode,
                    in: source)
            else { return nil }
            self = .looped(expression)
        default:
            guard
                let simple = Syntax.Expression(
                    from: node,
                    in: source)
            else { return nil }
            self = .simple(simple)
        }
    }
}
