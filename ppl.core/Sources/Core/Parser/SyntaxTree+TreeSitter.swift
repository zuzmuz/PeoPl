import Foundation
import SwiftTreeSitter
import TreeSitterPeoPl

// MARK: TreeSitter node extension functions
// -----------------------------------------

/// Protocol for types that can be created from a TreeSitter node.
protocol TreeSitterNode {
    static func from(
        node: Node,
        in source: Syntax.Source
    ) throws(Syntax.Error) -> Self
}

/// Parses an integer from a string, supporting hex, octal, and binary formats.
private func parseInteger(from string: String) -> UInt64? {
    let cleanString = string.replacingOccurrences(of: "_", with: "")

    if cleanString.hasPrefix("0x") {
        let hexString = String(cleanString.dropFirst(2))
        return UInt64(hexString, radix: 16)
    } else if cleanString.hasPrefix("0o") {
        let octalString = String(cleanString.dropFirst(2))
        return UInt64(octalString, radix: 8)
    } else if cleanString.hasPrefix("0b") {
        let binaryString = String(cleanString.dropFirst(2))
        return UInt64(binaryString, radix: 2)
    } else {
        return UInt64(cleanString)
    }
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

    func getString(in source: Syntax.Source) throws(Syntax.Error) -> String {
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
            range: range)
    }
}

// MARK: - Project Structure
// -------------------------

extension Syntax.Module {
    public init(source: String, path: String) throws {
        let language = Language(tree_sitter_peopl())
        let parser = Parser()
        try parser.setLanguage(language)

        let tree = parser.parse(source)
        guard let rootNode = tree?.rootNode else {
            throw Syntax.Error.sourceUnreadable
        }

        let source = Syntax.Source(content: source, name: path)

        self.definitions =
            try rootNode.compactMapChildren { node throws(Syntax.Error) in
                if node.nodeType == "type_definition"
                    || node.nodeType == "value_definition"
                {
                    return try .from(node: node, in: source)
                } else {
                    return nil
                }
            }
        self.sourceName = path
    }

    public init(path: String) throws {

        let fileHandle = FileHandle(forReadingAtPath: path)

        guard let outputData = try fileHandle?.read(upToCount: Int.max),
            let outputString = String(
                data: outputData, encoding: .utf8)
        else {
            fatalError("File unreadable at path")
        }
        try self.init(source: outputString, path: path)
    }

    public init(url: URL) throws {
        let data = try Data.init(contentsOf: url)
        guard let source = String(data: data, encoding: .utf8) else {
            fatalError("File unreadable at url")
        }
        try self.init(source: source, path: url.path)
    }
}

extension Syntax.Definition: TreeSitterNode {
    static func from(
        node: Node,
        in source: Syntax.Source
    ) throws(Syntax.Error) -> Self {
        switch node.nodeType {
        case "type_definition":
            return .typeDefinition(
                try .from(
                    node: node,
                    in: source))
        case "value_definition":
            return .valueDefinition(
                try .from(
                    node: node,
                    in: source))
        default:
            throw .errorParsing(
                element: node.nodeType ?? "definition",
                location: node.getLocation(in: source))
        }
    }
}

extension Syntax.ScopedIdentifier: TreeSitterNode {
    static func getScopedIdentifier(
        node: Node,
        in source: Syntax.Source
    ) throws(Syntax.Error) -> [String] {
        guard let identifier = node.child(byFieldName: "identifier") else {
            throw .errorParsing(
                element: "ScopedIdentifier",
                location: node.getLocation(in: source))
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
    ) throws(Syntax.Error) -> Self {
        .init(
            chain: try Self.getScopedIdentifier(node: node, in: source),
            location: node.getLocation(in: source)
        )
    }
}

extension Syntax.TypeDefinition: TreeSitterNode {
    static func from(
        node: Node,
        in source: Syntax.Source
    ) throws(Syntax.Error) -> Self {
        guard let identifierNode = node.child(byFieldName: "identifier"),
            let definitionNode = node.child(byFieldName: "definition")
        else {
            throw .errorParsing(
                element: "TypeDefinition",
                location: node.getLocation(in: source))
        }

        let arguments: [Syntax.TypeField]
        if let argumentsNode = node.child(byFieldName: "type_arguments") {
            arguments =
                try argumentsNode
                .compactMapChildren { child throws(Syntax.Error) in
                    if child.nodeType == "type_field" {
                        return try Syntax.TypeField.from(
                            node: child, in: source)
                    } else {
                        return nil
                    }
                }
        } else {
            arguments = []
        }

        return .init(
            identifier: try .from(node: identifierNode, in: source),
            arguments: arguments,
            typeSpecifier: try .from(node: definitionNode, in: source),
            location: node.getLocation(in: source)
        )
    }
}

extension Syntax.ValueDefinition: TreeSitterNode {
    static func from(
        node: Node,
        in source: Syntax.Source
    ) throws(Syntax.Error) -> Self {
        guard let identifierNode = node.child(byFieldName: "identifier"),
            let expressionNode = node.child(byFieldName: "expression")
        else {
            throw .errorParsing(
                element: "TypeDefinition",
                location: node.getLocation(in: source))
        }

        let arguments: [Syntax.TypeField]
        if let argumentsNode = node.child(byFieldName: "type_arguments") {
            arguments =
                try argumentsNode
                .compactMapChildren { child throws(Syntax.Error) in
                    if child.nodeType == "type_field" {
                        return try Syntax.TypeField.from(
                            node: child, in: source)
                    } else {
                        return nil
                    }
                }
        } else {
            arguments = []
        }

        return .init(
            identifier: try .from(node: identifierNode, in: source),
            arguments: arguments,
            expression: try .from(node: expressionNode, in: source),
            location: node.getLocation(in: source)
        )
    }
}

// MARK: - Type System
// -------------------

extension Syntax.TypeSpecifier {
    // TODO: some types are not supported yet
    static func from(
        node: Node,
        in source: Syntax.Source
    ) throws(Syntax.Error) -> Self {
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
        case "nominal":
            return .nominal(try .from(node: node, in: source))
        case "function":
            return .function(try .from(node: node, in: source))
        default:
            throw .errorParsing(
                element: "TypeSpecifier \(node.nodeType ?? "")",
                location: location)
        }
    }
}

extension Syntax.TaggedTypeSpecifier: TreeSitterNode {
    static func from(
        node: Node,
        in source: Syntax.Source
    ) throws(Syntax.Error) -> Self {
        guard let identifierNode = node.child(byFieldName: "identifier"),
            let definitionNode = node.child(byFieldName: "type")
        else {
            throw .errorParsing(
                element: "TaggedTypeSpecifier",
                location: node.getLocation(in: source))
        }

        return .init(
            tag: try identifierNode.getString(in: source),
            typeSpecifier: try .from(node: definitionNode, in: source),
            location: node.getLocation(in: source)
        )
    }
}

extension Syntax.HomogeneousTypeProduct: TreeSitterNode {
    static func from(
        node: Node,
        in source: Syntax.Source
    ) throws(Syntax.Error) -> Self {
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
            guard
                let intValue = parseInteger(
                    from: try node.getString(in: source))
            else {
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
    ) throws(Syntax.Error) -> Self {
        guard let child = node.child(at: 0) else {
            throw .errorParsing(
                element: "TypeField",
                location: node.getLocation(in: source))
        }
        switch child.nodeType {
        case "tagged_type_specifier":
            return .taggedTypeSpecifier(try .from(node: child, in: source))
        case "homogeneous_product":
            return .homogeneousTypeProduct(try .from(node: child, in: source))
        default:
            return .typeSpecifier(try .from(node: child, in: source))
        }
    }
}

// MARK: - Algebraic Data Types
// ----------------------------

extension Syntax.Product: TreeSitterNode {
    static func from(
        node: Node,
        in source: Syntax.Source
    ) throws(Syntax.Error) -> Self {
        guard let typeFieldsNode = node.child(at: 0) else {
            throw .errorParsing(element: "Product", location: .nowhere)
        }

        let typeFields: [Syntax.TypeField] =
            try typeFieldsNode
            .compactMapChildren { child throws(Syntax.Error) in
                if child.nodeType == "type_field" {
                    try .from(node: child, in: source)
                } else {
                    nil
                }
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
    ) throws(Syntax.Error) -> Self {
        // first child is the 'choice' keyword
        guard let typeFieldList = node.child(at: 1) else {
            throw .errorParsing(
                element: "Sum",
                location: node.getLocation(in: source))
        }

        let typeFields: [Syntax.TypeField] =
            try typeFieldList.compactMapChildren { child throws(Syntax.Error) in
                if child.nodeType == "type_field" {
                    return try .from(node: child, in: source)
                } else if child.nodeType == "small_identifier" {
                    // handling enums
                    let smallIdentifier = try child.getString(in: source)
                    return .taggedTypeSpecifier(
                        .init(
                            tag: smallIdentifier,
                            typeSpecifier: .nothing(location: .nowhere),
                            location: child.getLocation(in: source)))
                } else {
                    return nil
                }
            }
        return .init(
            typeFields: typeFields,
            location: node.getLocation(in: source)
        )
    }
}

extension Syntax.Nominal: TreeSitterNode {
    static func from(
        node: Node,
        in source: Syntax.Source
    ) throws(Syntax.Error) -> Self {
        guard let identifierNode = node.child(byFieldName: "identifier") else {
            throw .errorParsing(element: "Nominal", location: .nowhere)
        }

        let typeArguments: [Syntax.TypeSpecifier]
        if let typeArgumentsNode = node.child(byFieldName: "type_arguments") {
            typeArguments =
                try typeArgumentsNode
                .compactMapChildren { child throws(Syntax.Error) in
                    if child.nodeType == "type_specifier" {
                        try Syntax.TypeSpecifier.from(node: child, in: source)
                    } else {
                        nil
                    }
                }
        } else {
            typeArguments = []
        }

        return .init(
            identifier: try .from(node: identifierNode, in: source),
            typeArguments: typeArguments,
            location: node.getLocation(in: source)
        )
    }
}

extension Syntax.Function: TreeSitterNode {
    static func from(
        node: Node,
        in source: Syntax.Source
    ) throws(Syntax.Error) -> Self {
        let inputType: Syntax.TypeField?
        if let inputTypeNode = node.child(byFieldName: "input_type") {
            inputType = try .from(node: inputTypeNode, in: source)
        } else {
            inputType = nil
        }

        let arguments: [Syntax.TypeField]
        if let argumentsNode = node.child(byFieldName: "arguments") {
            arguments =
                try argumentsNode
                .compactMapChildren { child throws(Syntax.Error) in
                    if child.nodeType == "type_field" {
                        return try Syntax.TypeField.from(
                            node: child, in: source)
                    } else {
                        return nil
                    }
                }
        } else {
            arguments = []
        }

        guard let outputTypeNode = node.child(byFieldName: "output_type")
        else {
            throw .errorParsing(
                element: "FunctionDefinition",
                location: node.getLocation(in: source))
        }

        return .init(
            inputType: inputType,
            arguments: arguments,
            outputType: try .from(node: outputTypeNode, in: source),
            location: node.getLocation(in: source)
        )
    }
}

// MARK: - Expressions
// -------------------

extension Syntax.TaggedExpression: TreeSitterNode {
    static func from(
        node: Node,
        in source: Syntax.Source
    ) throws(Syntax.Error) -> Self {
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

extension Syntax.Expression: TreeSitterNode {
    static func from(
        node: Node,
        in source: Syntax.Source
    ) throws(Syntax.Error) -> Self {
        if node.nodeType == "parenthisized_expression" {
            guard let parenthesizedExpressionNode = node.child(at: 1) else {
                throw .errorParsing(
                    element: "parenthisized_expression",
                    location: node.getLocation(in: source))
            }
            return try .init(
                expressionType: .from(
                    node: parenthesizedExpressionNode,
                    in: source),
                location: node.getLocation(in: source))
        } else {
            return try .init(
                expressionType: .from(node: node, in: source),
                location: node.getLocation(in: source))
        }
    }
}
extension Syntax.Expression.Literal {
    static func from(
        node: Node,
        in source: Syntax.Source
    ) throws(Syntax.Error) -> Self {
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
            guard
                let intValue = parseInteger(
                    from: try node.getString(in: source))
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
            throw .errorParsing(
                element: "literal",
                location: node.getLocation(in: source))
        }
    }
}

extension Syntax.Expression.ExpressionType: TreeSitterNode {

    static let expressionNodeTypes = Set([
        "literal",
        "unary_expression",
        "binary_expression",
        "scoped_identifier",
        "parenthisized_expression",
        "function_definition",
        "call_expression",
        "initializer_expression",
        "access_expression",
        "binding",
        "tagged_expression",
        "branched_expression",
        "piped_expressio",
    ])

    static func parseUnary(
        from node: Node,
        in source: Syntax.Source
    ) throws(Syntax.Error) -> Self {
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
    ) throws(Syntax.Error) -> Self {
        guard let leftNode = node.child(byFieldName: "left"),
            let operatorNode = node.child(byFieldName: "operator"),
            let rightNode = node.child(byFieldName: "right")
        else {
            throw .errorParsing(
                element: "BinaryExpression",
                location: node.getLocation(in: source))
        }

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

    static func parseFunction(
        from node: Node,
        in source: Syntax.Source
    ) throws(Syntax.Error) -> Self {

        guard let bodyNode = node.child(byFieldName: "body"),
            let bodyExpressionNode = bodyNode.child(at: 1)
        else {
            throw .errorParsing(
                element: "FunctionDefinition",
                location: node.getLocation(in: source))
        }

        let signature: Syntax.Function?
        if let signatureNode = node.child(byFieldName: "signature") {
            signature = try .from(node: signatureNode, in: source)
        } else {
            signature = nil
        }

        return .function(
            signature: signature,
            expression: try .from(node: bodyExpressionNode, in: source)
        )
    }

    static func parseCallExpression(
        from node: Node,
        in source: Syntax.Source
    ) throws(Syntax.Error) -> Self {
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
            .compactMapChildren { child throws(Syntax.Error) in
                if expressionNodeTypes.contains(child.nodeType ?? "") {
                    try Syntax.Expression.from(node: child, in: source)
                } else {
                    nil
                }
            }

        return .call(
            prefix: try .from(node: prefixNode, in: source),
            arguments: arguments
        )
    }

    static func parseInitializerExpression(
        from node: Node,
        in source: Syntax.Source
    ) throws(Syntax.Error) -> Self {

        let prefix: Syntax.Nominal?
        if let prefixNode = node.child(byFieldName: "prefix") {
            prefix = try .from(node: prefixNode, in: source)
        } else {
            prefix = nil
        }

        guard let argumentListNode = node.child(byFieldName: "arguments") else {
            throw .errorParsing(
                element: "InitializerExpression",
                location: node.getLocation(in: source))
        }

        let arguments =
            try argumentListNode
            .compactMapChildren { child throws(Syntax.Error) in
                if child.nodeType == "expression" {
                    try Syntax.Expression.from(node: child, in: source)
                } else {
                    nil
                }
            }

        return .initializer(
            prefix: prefix,
            arguments: arguments
        )
    }

    static func parseAccess(
        from node: Node,
        in source: Syntax.Source
    ) throws(Syntax.Error) -> Self {
        guard let prefixNode = node.child(byFieldName: "prefix"),
            let fieldNode = node.child(byFieldName: "field")
        else {
            throw .errorParsing(
                element: "AccessExpression",
                location: node.getLocation(in: source))
        }
        return .access(
            prefix: try .from(node: prefixNode, in: source),
            field: try fieldNode.getString(in: source)
        )
    }

    static func parsePiped(
        from node: Node,
        in source: Syntax.Source
    ) throws(Syntax.Error) -> Self {
        guard let leftNode = node.child(byFieldName: "left"),
            let rightNode = node.child(byFieldName: "right")
        else {
            throw .errorParsing(
                element: "PipedExpression",
                location: node.getLocation(in: source))
        }
        return .piped(
            left: try .from(node: leftNode, in: source),
            right: try .from(node: rightNode, in: source)
        )
    }

    static func from(
        node: Node,
        in source: Syntax.Source
    ) throws(Syntax.Error) -> Self {
        switch node.nodeType {
        case "literal":
            return .literal(try .from(node: node, in: source))
        case "unary_expression":
            return try parseUnary(from: node, in: source)
        case "binary_expression":
            return try parseBinary(from: node, in: source)
        case "scoped_identifier":
            return .field(try .from(node: node, in: source))
        case "function_definition":
            return try parseFunction(from: node, in: source)
        case "call_expression":
            return try parseCallExpression(from: node, in: source)
        case "initializer_expression":
            return try parseInitializerExpression(from: node, in: source)
        case "access_expression":
            return try parseAccess(from: node, in: source)
        case "binding":
            return .binding(String(try node.getString(in: source).dropFirst()))
        case "tagged_expression":
            return .taggedExpression(try .from(node: node, in: source))
        case "branched_expression":
            return .branched(try .from(node: node, in: source))
        case "piped_expression":
            return try parsePiped(from: node, in: source)
        default:
            throw .notImplemented(
                element: node.nodeType ?? "nil",
                location: node.getLocation(in: source))
        }
    }
}

extension Syntax.Expression.Branched {
    static func from(
        node: Node,
        in source: Syntax.Source
    ) throws(Syntax.Error) -> Self {
        return .init(
            branches:
                try node
                .compactMapChildren { child throws(Syntax.Error) in
                    if child.nodeType == "branch" {
                        try .from(
                            node: child,
                            in: source)
                    } else {
                        nil
                    }
                },
            location: node.getLocation(in: source)
        )
    }
}

extension Syntax.Expression.Branched.Branch {
    static func from(
        node: Node,
        in source: Syntax.Source
    ) throws(Syntax.Error) -> Self {

        guard
            let bodyNode = node.child(byFieldName: "body")
        else {
            throw .errorParsing(
                element: "Branch",
                location: node.getLocation(in: source))
        }

        let matchExpression: Syntax.Expression
        if let matchExpressionNode =
            node.child(byFieldName: "match_expression")
        {
            matchExpression = try .from(
                node: matchExpressionNode, in: source)
        } else {
            matchExpression = .init(
                expressionType: .literal(.nothing),
                location: node.getLocation(in: source))
        }

        let guardExpression: Syntax.Expression?
        if let guardExpressionNode =
            node.child(byFieldName: "guard_expression")
        {
            guardExpression = try .from(
                node: guardExpressionNode, in: source)
        } else {
            guardExpression = nil
        }

        return .init(
            matchExpression: matchExpression,
            guardExpression: guardExpression,
            body: try .from(node: bodyNode, in: source),
            location: node.getLocation(in: source)
        )
    }
}
