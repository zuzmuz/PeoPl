import Foundation
import SwiftTreeSitter
import TreeSitterPeoPl

// MARK: TreeSitter node extension functions
// -----------------------------------------

protocol TreeSitterNode {
    static func from(
        node: Node,
        in source: Syntax.Source
    ) throws(SyntaxError) -> Self
}

extension Node {
    func compactMapChildren<T, E>(
        block: (Node) throws(E) -> T?
    ) throws(E) -> [T] where E: Error {
        let optionalMap: [T?] = try (0..<childCount).map { i throws(E) in
            guard let child = child(at: i) else { return nil }
            return try block(child)
        }
        // For some reason compact map doesn't rethrow typed throws
        return optionalMap.compactMap { $0 }
    }

    func compactMapChildrenEnumerated<T, E>(
        block: (Int, Node) throws(E) -> T?
    ) throws(E) -> [T] where E: Error {
        let optionalMap: [T?] = try (0..<childCount).map { i throws(E) in
            guard let child = child(at: i) else { return nil }
            return try block(i, child)
        }
        return optionalMap.compactMap { $0 }
    }

    func getString(in source: Syntax.Source) throws(SyntaxError) -> String {
        guard
            let range = Swift.Range.init(
                self.range,
                in: source.content)
        else { throw .rangeNotInContent }
        return String(source.content[range])
    }

    func getLocation(in source: Syntax.Source) -> Syntax.NodeLocation {
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

        self.definitions =
            try rootNode.compactMapChildren { node throws(SyntaxError) in
                try .from(node: node, in: source)
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

extension Syntax.Definition: TreeSitterNode {
    static func from(
        node: Node,
        in source: Syntax.Source
    ) throws(SyntaxError) -> Self {
        switch node.nodeType {
        case "type_definition":
            return .typeDefinition(
                try .from(
                    node: node,
                    in: source))
        default:
            throw .sourceUnreadable
        }
    }
}

extension Syntax.ScopedIdentifier: TreeSitterNode {
    static func getScopedIdentifier(
        node: Node,
        in source: Syntax.Source
    ) throws(SyntaxError) -> [String] {
        guard let identifier = node.child(byFieldName: "identifier") else {
            throw .errorParsing(
                element: "ScopedIdentifier",
                location: .nowhere)
        }

        let nameValue = try identifier.getString(in: source)

        if let scope = node.child(byFieldName: "scope") {
            let scopeValue = try getScopedIdentifier(
                node: scope, in: source)
            return scopeValue + [nameValue]
        }

        return [nameValue]
    }

    static func from(
        node: Node,
        in source: Syntax.Source
    ) throws(SyntaxError) -> Self {
        .init(
            chain: try Self.getScopedIdentifier(node: node, in: source),
            location: node.getLocation(in: source)
        )
    }
}

// MARK: - type definitions
// ------------------------

extension Syntax.TypeDefinition: TreeSitterNode {
    static func from(
        node: Node,
        in source: Syntax.Source
    ) throws(SyntaxError) -> Self {
        guard let identifierNode = node.child(byFieldName: "identifier"),
            let definitionNode = node.child(byFieldName: "definition")
        else {
            throw .errorParsing(element: "TypeDefinition", location: .nowhere)
        }
        // TODO: parse type list
        // if let argumentsNode = node.child(byFieldName: "type_arguments") {
        //     argumentsNode.compactMapChildren { node in
        //     }
        // }

        return .init(
            identifier: try .from(node: identifierNode, in: source),
            arguments: [],
            definition: try .from(node: definitionNode, in: source),
            location: node.getLocation(in: source)
        )
    }
}

extension Syntax.TypeSpecifier {

    // TODO: some types are not supported yet

    static func from(
        node: Node,
        in source: Syntax.Source
    ) throws(SyntaxError) -> Self {
        let location = node.getLocation(in: source)
        switch node.nodeType {
        case "nothing_type":
            return .nothing(location: location)
        case "never_type":
            return .never(location: location)
        case "product":
            return .product(try .from(node: node, in: source))
        case "sum":
            return .sum(try .from(node: node, in: source))
        default:
            throw .errorParsing(element: "TypeSpecifier", location: location)
        }
    }
}

extension Syntax.TaggedTypeSpecifier: TreeSitterNode {
    static func from(
        node: Node,
        in source: Syntax.Source
    ) throws(SyntaxError) -> Self {
        guard let identifierNode = node.child(byFieldName: "identifier"),
            let definitionNode = node.child(byFieldName: "type")
        else { throw .errorParsing(element: "TypeField", location: .nowhere) }

        return .init(
            identifier: try .from(node: identifierNode, in: source),
            type: try .from(node: definitionNode, in: source),
            location: node.getLocation(in: source)
        )
    }
}

extension Syntax.HomogeneousTypeProduct: TreeSitterNode {
    static func from(
        node: Node,
        in source: Syntax.Source
    ) throws(SyntaxError) -> Self {
        guard let typeSpecifierNode = node.child(byFieldName: "type_specifier"),
            let exponentNode = node.child(byFieldName: "exponent")
        else {
            throw .errorParsing(
                element: "HomogeneousTypeProduct",
                location: node.getLocation(in: source))
        }

        let count: Exponent
        switch exponentNode.nodeType {
        case "int_literal":
            guard let intValue = Int64(try node.getString(in: source)) else {
                throw .errorParsing(
                    element: "int_literal",
                    location: node.getLocation(in: source))
            }
            count = .literal(intValue)
        case "scoped_identifier":
            count = .identifier(try .from(node: exponentNode, in: source))
        default:
            throw .errorParsing(
                element: "count",
                location: node.getLocation(in: source))
        }

        return .init(
            typeSpecifier: try .from(node: typeSpecifierNode, in: source),
            count: count,
            location: node.getLocation(in: source)
        )
    }
}

extension Syntax.TypeField: TreeSitterNode {
    static func from(
        node: Node,
        in source: Syntax.Source
    ) throws(SyntaxError) -> Self {
        switch node.nodeType {
        case "tagged_type_specifier":
            return .taggedTypeSpecifier(try .from(node: node, in: source))
        case "homogeneous_product":
            return .homogeneousTypeProduct(try .from(node: node, in: source))
        default:
            return .typeSpecifier(try .from(node: node, in: source))
        }
    }
}

extension Syntax.Product: TreeSitterNode {
    static func from(
        node: Node,
        in source: Syntax.Source
    ) throws(SyntaxError) -> Self {
        guard let typeFieldList = node.child(at: 0) else {
            throw .errorParsing(element: "Product", location: .nowhere)
        }

        let typeFields: [Syntax.TypeField] =
            try typeFieldList.compactMapChildren { child throws(SyntaxError) in
                try .from(node: child, in: source)
            }
        return .init(
            typeFields: typeFields,
            location: node.getLocation(in: source)
        )
    }
}

extension Syntax.Sum: TreeSitterNode {
    static func from(
        node: Node,
        in source: Syntax.Source
    ) throws(SyntaxError) -> Self {
        // first child is the 'choice' keyword
        guard let typeFieldList = node.child(at: 1) else {
            throw .errorParsing(element: "Sum", location: .nowhere)
        }

        let typeFields: [Syntax.TypeField] =
            try typeFieldList.compactMapChildren { child throws(SyntaxError) in
                try .from(node: child, in: source)
            }
        return .init(
            typeFields: typeFields,
            location: node.getLocation(in: source)
        )
    }
}

// MARK: - Expressions
// -------------------

extension Syntax.Expression: TreeSitterNode {
    static func from(
        node: Node,
        in source: Syntax.Source
    ) throws(SyntaxError) -> Self {
        if node.nodeType == "parenthisized_expression" {
            guard let child = node.child(at: 1) else {
                throw .errorParsing(
                    element: "parenthisized_expression",
                    location: node.getLocation(in: source))
            }
            return try .init(
                expressionType: .from(node: child, in: source),
                location: node.getLocation(in: source))
        } else {
            return try .init(
                expressionType: .from(node: node, in: source),
                location: node.getLocation(in: source))
        }
    }
}

extension Syntax.TaggedExpression: TreeSitterNode {
    static func from(
        node: Node,
        in source: Syntax.Source
    ) throws(SyntaxError) -> Self {
        guard let identifierNode = node.child(byFieldName: "identifier"),
            let expressionNode = node.child(byFieldName: "expression")
        else {
            throw .errorParsing(
                element: "TaggedExpression",
                location: node.getLocation(in: source))
        }
        return .init(
            identifier: try identifierNode.getString(in: source),
            expression: try .from(node: expressionNode, in: source),
            location: node.getLocation(in: source)
        )
    }
}

extension Syntax.Expression.Literal {
    static func from(
        node: Node,
        in source: Syntax.Source
    ) throws(SyntaxError) -> Self {
        guard let child = node.child(at: 0) else {
            throw .errorParsing(
                element: "Literal",
                location: node.getLocation(in: source))
        }
        switch child.nodeType {
        case "nothing_value":
            return .nothing
        case "never_value":
            return .never
        case "int_literal":
            guard let intValue = UInt64(try node.getString(in: source))
            else {
                throw .errorParsing(
                    element: "Int_literal",
                    location: node.getLocation(in: source))
            }
            return .intLiteral(intValue)
        case "float_literal":
            guard let floatValue = Double(try node.getString(in: source))
            else {
                throw .errorParsing(
                    element: "Float_literal",
                    location: node.getLocation(in: source))
            }
            return .floatLiteral(floatValue)
        case "string_literal":
            let stringValue = try node.getString(in: source)
            return .stringLiteral(String(stringValue.dropFirst().dropLast()))
        case "bool_literal":
            guard let boolValue = Bool(try node.getString(in: source))
            else {
                throw .errorParsing(
                    element: "Bool_literal",
                    location: node.getLocation(in: source))
            }
            return .boolLiteral(boolValue)
        default:
            throw .sourceUnreadable
        }
    }
}

extension Syntax.Expression.ExpressionType: TreeSitterNode {

    static func parseUnary(
        from node: Node,
        in source: Syntax.Source
    ) throws(SyntaxError) -> Self {
        guard let operatorNode = node.child(byFieldName: "operator"),
            let operandNode = node.child(byFieldName: "operand")
        else {
            throw .errorParsing(
                element: "UnaryExpression",
                location: node.getLocation(in: source))
        }
        let operatorText = try operatorNode.getString(in: source)
        guard let operatorValue = Operator(rawValue: operatorText) else {
            throw .errorParsing(
                element: "UnaryOperator",
                location: operatorNode.getLocation(in: source))
        }
        return .unary(
            operatorValue,
            expression: try .from(node: operandNode, in: source)
        )
    }
    static func parseBinary(
        from node: Node,
        in source: Syntax.Source
    ) throws(SyntaxError) -> Self {
        guard let leftNode = node.child(byFieldName: "left"),
            let operatorNode = node.child(byFieldName: "operator"),
            let rightNode = node.child(byFieldName: "right")
        else {
            throw .errorParsing(
                element: "BinaryExpression",
                location: node.getLocation(in: source))
        }
        // let leftExpression = Syntax.Expression(
        //     from: leftNode,
        //     in: source),
        let operatorText = try operatorNode.getString(in: source)
        guard let operatorValue = Operator(rawValue: operatorText) else {
            throw .errorParsing(
                element: "BinaryOperator",
                location: operatorNode.getLocation(in: source))
        }

        return .binary(
            operatorValue,
            left: try .from(node: leftNode, in: source),
            right: try .from(node: rightNode, in: source)
        )
    }

    static func parseCallExpression(
        from node: Node,
        in source: Syntax.Source
    ) throws(SyntaxError) -> Self {
        guard let prefixNode = node.child(byFieldName: "prefix")
        else {
            throw .errorParsing(
                element: "CallExpression",
                location: node.getLocation(in: source))
        }

        guard let argumentListNode = node.child(byFieldName: "arguments") else {
            throw .errorParsing(
                element: "CallExpression",
                location: node.getLocation(in: source))
        }

        let arguments =
            try argumentListNode
            .compactMapChildren { child throws(SyntaxError) in
                try Syntax.TaggedExpression.from(node: child, in: source)
            }

        return .call(
            prefix: try .from(node: prefixNode, in: source),
            arguments: arguments
        )
    }


    //     static func parseUnnamedTuple(
    //         from node: Node,
    //         in source: Syntax.Source
    //     ) -> Self? {
    //         let expressions = node.compactMapChildren { node in
    //             Syntax.Expression(from: node, in: source)
    //         }
    //         return .unnamedTuple(expressions)
    //     }
    //
    //     static func parseNamedTuple(
    //         from node: Node,
    //         in source: Syntax.Source
    //     ) -> Self? {
    //         let arguments = node.compactMapChildren { node in
    //             Syntax.Expression.Argument(from: node, in: source)
    //         }
    //         return .namedTuple(arguments)
    //     }
    //
    //     static func parseFunctionCall(
    //         from node: Node,
    //         in source: Syntax.Source
    //     ) -> Self? {
    //         guard let prefixNode = node.child(byFieldName: "prefix"),
    //             let prefix = Syntax.Expression(
    //                 from: prefixNode, in: source)
    //         else { return nil }
    //
    //         let arguments: [Syntax.Expression.Argument] =
    //             if let argumentList = node.child(
    //                 byFieldName: "arguments")
    //             {
    //                 argumentList.compactMapChildren { child in
    //                     Syntax.Expression.Argument(
    //                         from: child, in: source)
    //                 }
    //             } else {
    //                 []
    //             }
    //         return .functionCall(prefix: prefix, arguments: arguments)
    //     }
    //
    //     static func parseTypeInitializer(
    //         from node: Node,
    //         in source: Syntax.Source
    //     ) -> Self? {
    //         guard let prefixNode = node.child(byFieldName: "prefix"),
    //             let prefix = Syntax.NominalType(
    //                 from: prefixNode, in: source)
    //         else { return nil }
    //
    //         let arguments: [Syntax.Expression.Argument] =
    //             if let argumentList = node.child(
    //                 byFieldName: "arguments")
    //             {
    //                 argumentList.compactMapChildren { child in
    //                     Syntax.Expression.Argument(
    //                         from: child, in: source)
    //                 }
    //             } else {
    //                 []
    //             }
    //         return .typeInitializer(prefix: prefix, arguments: arguments)
    //     }
    //
    //     static func parseAccess(
    //         from node: Node,
    //         in source: Syntax.Source
    //     ) -> Self? {
    //         guard let prefixNode = node.child(byFieldName: "prefix"),
    //             let prefix = Syntax.Expression(
    //                 from: prefixNode, in: source),
    //             let fieldNode = node.child(byFieldName: "field"),
    //             let field = fieldNode.getString(in: source)
    //         else { return nil }
    //         return .access(prefix: prefix, field: field)
    //     }
    //
    //     static func parseField(
    //         from node: Node,
    //         in source: Syntax.Source
    //     ) -> Self? {
    //         guard
    //             let scopedIdenfier = Syntax.ScopedIdentifier(
    //                 from: node,
    //                 in: source)
    //         else { return nil }
    //         return .field(scopedIdenfier)
    //     }
    //
    //     static func parseBranched(
    //         from node: Node,
    //         in source: Syntax.Source
    //     ) -> Self? {
    //         guard
    //             let branched = Syntax.Expression.Branched(
    //                 from: node,
    //                 in: source)
    //         else { return nil }
    //         return .branched(branched)
    //     }
    //
    //     static func parsePiped(
    //         from node: Node,
    //         in source: Syntax.Source
    //     ) -> Self? {
    //         guard let leftNode = node.child(byFieldName: "left"),
    //             let left = Syntax.Expression(from: leftNode, in: source)
    //         else { return nil }
    //         guard let rightNode = node.child(byFieldName: "right"),
    //             let right = Syntax.Expression(
    //                 from: rightNode, in: source)
    //         else { return nil }
    //         return .piped(left: left, right: right)
    //     }
    //
    static func from(
        node: Node,
        in source: Syntax.Source
    ) throws(SyntaxError) -> Self {
        switch node.nodeType {
        case "literal":
            return .literal(try .from(node: node, in: source))
        // case "unary_expression":
        //     return parseUnary(from: node, in: source)
        // case "binary_expression":
        //     return parseBinary(from: node, in: source)
        default:
            throw .sourceUnreadable
        }
    }
}
//
// extension Syntax.Expression.Argument {
//     init?(from node: Node, in source: Syntax.Source) {
//         guard let location = node.getLocation(in: source) else {
//             return nil
//         }
//         self.location = location
//
//         guard let nameNode = node.child(byFieldName: "name"),
//             let name = nameNode.getString(in: source)
//         else { return nil }
//         self.name = name
//
//         guard let valueNode = node.child(byFieldName: "value"),
//             let value = Syntax.Expression(
//                 from: valueNode, in: source)
//         else { return nil }
//         self.value = value
//     }
// }
//
// extension Syntax.Expression.Branched {
//     static let branch = "branch_expression"
//
//     init?(from node: Node, in source: Syntax.Source) {
//         guard let location = node.getLocation(in: source) else {
//             return nil
//         }
//         self.location = location
//
//         self.branches = node.compactMapChildren { child in
//             if child.nodeType == Syntax.Expression.Branched.branch {
//                 Syntax.Expression.Branched.Branch(
//                     from: child, in: source)
//             } else {
//                 nil
//             }
//         }
//     }
// }
//
// extension Syntax.Expression.Branched.Branch {
//
//     init?(from node: Node, in source: Syntax.Source) {
//         guard let location = node.getLocation(in: source) else {
//             return nil
//         }
//         self.location = location
//
//         guard
//             let matchExpressionNode = node.child(
//                 byFieldName: "match_expression"),
//             let matchExpression = MatchExpression(
//                 from: matchExpressionNode,
//                 in: source)
//         else { return nil }
//         self.matchExpression = matchExpression
//
//         if let guardNode = node.child(byFieldName: "guard_expression") {
//             self.guardExpression = Syntax.Expression(
//                 from: guardNode,
//                 in: source)
//         } else {
//             self.guardExpression = nil
//         }
//
//         guard let bodyNode = node.child(byFieldName: "body"),
//             let body = Body(from: bodyNode, in: source)
//         else { return nil }
//         self.body = body
//     }
// }
//
// extension Syntax.Expression.Branched.Branch.MatchExpression {
//
//     enum CodingKeys: String, CodingKey {
//         case literal = "literal"
//         case field = "scoped_identifier"
//         case binding = "binding_name"
//         case tupleBinding = "tuple_binding_literal"
//         case typeBinding = "type_binding"
//     }
//
//     init?(from node: Node, in source: Syntax.Source) {
//         switch CodingKeys(rawValue: node.nodeType ?? "") {
//         case .literal:
//             guard
//                 let literal = Syntax.Expression.Literal(
//                     from: node,
//                     in: source)
//             else { return nil }
//             self = .literal(literal)
//         case .field:
//             guard
//                 let scopedIdentifier = Syntax.ScopedIdentifier(
//                     from: node,
//                     in: source)
//             else { return nil }
//             self = .field(scopedIdentifier)
//         case .binding:
//             guard let bindingValue = node.getString(in: source)
//             else {
//                 return nil
//             }
//             self = .binding(String(bindingValue.dropFirst()))
//         case .tupleBinding:
//             let matchExpressions = node.compactMapChildren { child in
//                 Syntax.Expression.Branched.Branch.MatchExpression(
//                     from: child,
//                     in: source)
//             }
//             self = .tupleBinding(matchExpressions)
//         case .typeBinding:
//             guard
//                 let prefixNode = node.child(
//                     byFieldName: "prefix"),
//                 let prefix = Syntax.NominalType(
//                     from: prefixNode,
//                     in: source)
//             else { return nil }
//
//             let arguments: [Syntax.Expression.Branched.Branch.BindingArgument] =
//                 if let argumentList = node.child(
//                     byFieldName: "arguments")
//                 {
//                     argumentList.compactMapChildren { child in
//                         Syntax.Expression.Branched.Branch.BindingArgument(
//                             from: child,
//                             in: source)
//                     }
//                 } else {
//                     []
//                 }
//             self = .typeBinding(
//                 prefix: prefix, arguments: arguments)
//         default:
//             return nil
//         }
//     }
// }
//
// extension Syntax.Expression.Branched.Branch.BindingArgument {
//     static let name = "name"
//     static let value = "value"
//
//     init?(from node: Node, in source: Syntax.Source) {
//         guard let location = node.getLocation(in: source) else {
//             return nil
//         }
//         self.location = location
//
//         guard let nameNode = node.child(byFieldName: Self.name),
//             let name = nameNode.getString(in: source)
//         else { return nil }
//         self.name = name
//
//         guard let valueNode = node.child(byFieldName: Self.value),
//             let value = Syntax.Expression.Branched.Branch
//                 .MatchExpression(
//                     from: valueNode,
//                     in: source)
//         else { return nil }
//         self.value = value
//     }
// }
//
// extension Syntax.Expression.Branched.Branch.Body {
//
//     enum CodingKeys: String, CodingKey {
//         case simple
//         case looped = "looped_expression"
//     }
//
//     init?(from node: Node, in source: Syntax.Source) {
//         switch node.nodeType {
//         case CodingKeys.looped.rawValue:
//             guard let loopedNode = node.child(at: 0),
//                 let parenthisizedNode = loopedNode.child(at: 1),
//                 let expression = Syntax.Expression(
//                     from: parenthisizedNode,
//                     in: source)
//             else { return nil }
//             self = .looped(expression)
//         default:
//             guard
//                 let simple = Syntax.Expression(
//                     from: node,
//                     in: source)
//             else { return nil }
//             self = .simple(simple)
//         }
//     }
// }
