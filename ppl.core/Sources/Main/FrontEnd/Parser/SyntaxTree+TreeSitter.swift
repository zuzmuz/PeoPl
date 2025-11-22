#if TREE_SITTER_PARSER

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

/// A ``Syntax/ModuleParser`` implementation using TreeSitter.
struct TreeSitterModulParser: Syntax.ModuleParser {
	private static func collectErrors(
		from node: Node,
		in source: borrowing Syntax.Source,
		collectedErrors: inout [Syntax.Error]
	) {
		guard node.hasError else {
			return
		}

		if node.nodeType == "ERROR" {
			collectedErrors.append(
				.errorParsing(
					element: "ERROR",
					location: node.getLocation(in: source)
				)
			)
			return
		}
		if node.nodeType == "MISSING" {
			collectedErrors.append(
				.errorParsing(
					element: "MISSING",
					location: node.getLocation(in: source)
				)
			)
			return
		}
		if node.childCount == 0 {
			collectedErrors.append(
				.errorParsing(
					element:
						"MISSING \(node.nodeType ?? "unknown")",
					location: node.getLocation(in: source)
				)
			)
		}
		node.enumerateChildren { childNode in
			collectErrors(
				from: childNode,
				in: source,
				collectedErrors: &collectedErrors
			)
		}
	}

	static func parseModule(source: Syntax.Source) -> Syntax.Module {
		let language = Language(tree_sitter_peopl())
		let parser = Parser()
		do {
			try parser.setLanguage(language)
		} catch {
			return .init(
				sourceName: source.name,
				definitions: [],
				syntaxErrors: [.languageNotSupported]
			)
		}

		let tree = parser.parse(source.content)
		guard let rootNode = tree?.rootNode else {
			return .init(
				sourceName: source.name,
				definitions: [],
				syntaxErrors: [.sourceUnreadable]
			)
		}

		var errors: [Syntax.Error] = []
		Self.collectErrors(
			from: rootNode,
			in: source,
			collectedErrors: &errors
		)

		var definitions: [Syntax.Expression] = []
		var docString = ""

		for index in 0..<rootNode.childCount {
			guard let node = rootNode.child(at: index) else { break }
			if node.nodeType == "comment" {
				do {
					let comment = try node.getString(in: source)
					if comment.hasPrefix("///") {
						docString += comment.dropFirst(3)
					}
				} catch {
					errors.append(error)
				}
			}
			if node.expressionNodeType != nil {
				do throws(Syntax.Error) {
					try definitions.append(
						.from(
							node: node, in: source
						)
					)
					// print("this is the doc string: \(docString)")
					docString = ""
				} catch {
					errors.append(error)
				}
			}
		}

		return .init(
			sourceName: source.name,
			definitions: definitions,
			syntaxErrors: errors
		)
	}
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
	enum ExpressionNodeType: String, CaseIterable {
		case literal = "literal"
		case unaryExpression = "unary_expression"
		case binaryExpression = "binary_expression"
		case qualifiedIdentifier = "qualified_identifier"
		case accessExpression = "access_expression"
		case roundCallExpression = "round_call_expression"
		case squareCallExpression = "square_call_expression"
		case squareExpressionList = "square_expression_list"
		case binding = "binding"
		case functionDefinition = "function_definition"
		case taggedExpression = "tagged_expression"
		case branchedExpression = "branched_expression"
		case pipedExpression = "piped_expression"
		case parenthesisExpression = "parenthesis_expression"
	}

	enum LiteralNodeType: String, CaseIterable {
		case nothing = "nothing"
		case never = "never"
		case intLiteral = "int_literal"
		case floatLiteral = "float_literal"
		case stringLiteral = "string_literal"
		case boolLiteral = "bool_literal"
	}

	var expressionNodeType: ExpressionNodeType? {
		return ExpressionNodeType(rawValue: self.nodeType ?? "")
	}

	var literalNodeType: LiteralNodeType? {
		return LiteralNodeType(rawValue: self.nodeType ?? "")
	}

	func compactMapChildren<T, E>(
		block: (Node) throws(E) -> T?
	) throws(E) -> [T] where E: Error {
		let optionalMap: [T?] = try (0..<childCount).map {
			i throws(E) in
			guard let child = child(at: i) else { return nil }
			return try block(child)
		}
		// For some reason compact map doesn't rethrow typed throws
		return optionalMap.compactMap { $0 }
	}

	func compactMapChildrenEnumerated<T, E>(
		block: (Int, Node) throws(E) -> T?
	) throws(E) -> [T] where E: Error {
		let optionalMap: [T?] = try (0..<childCount).map {
			i throws(E) in
			guard let child = child(at: i) else { return nil }
			return try block(i, child)
		}
		return optionalMap.compactMap { $0 }
	}

	func getString(in source: Syntax.Source) throws(Syntax.Error) -> String {
		guard
			let range = Swift.Range(
				range,
				in: source.content
			)
		else { throw .rangeNotInContent }
		return String(source.content[range])
	}

	func getLocation(in _: Syntax.Source) -> Syntax.NodeLocation {
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
			range: range
		)
	}
}

// MARK: - Project Structure

// -------------------------


extension Syntax.QualifiedIdentifier: TreeSitterNode {
	static func getScopedIdentifier(
		node: Node,
		in source: Syntax.Source
	) throws(Syntax.Error) -> [String] {
		guard let identifier = node.child(byFieldName: "identifier")
		else {
			throw .errorParsing(
				element: "ScopedIdentifier",
				location: node.getLocation(in: source)
			)
		}

		let nameValue = try identifier.getString(in: source)

		if let scope = node.child(byFieldName: "scope") {
			let scopeValue = try getScopedIdentifier(
				node: scope, in: source
			)
			return scopeValue + [nameValue]
		}

		return [nameValue]
	}

	static func from(
		node: Node,
		in source: Syntax.Source
	) throws(Syntax.Error) -> Self {
		try .init(
			chain: getScopedIdentifier(
				node: node, in: source
			),
			location: node.getLocation(in: source)
		)
	}
}

extension Syntax.FunctionType: TreeSitterNode {
	static func from(
		node: Node,
		in source: Syntax.Source
	) throws(Syntax.Error) -> Self {
		let inputType: Syntax.Expression?
		if let inputTypeNode = node.child(byFieldName: "input_type") {
			inputType = try .from(node: inputTypeNode, in: source)
		} else {
			inputType = nil
		}

		let arguments: [Syntax.Expression]
		if let argumentsNode = node.child(byFieldName: "arguments") {
			arguments =
				try argumentsNode
				.compactMapChildren {
					child throws(Syntax.Error) in
					if child.expressionNodeType != nil {
						return try Syntax.Expression
							.from(
								node: child,
								in: source
							)
					} else {
						return nil
					}
				}
		} else {
			arguments = []
		}

		guard
			let outputTypeNode = node.child(
				byFieldName: "output_type"
			)
		else {
			throw .errorParsing(
				element: "FunctionDefinition",
				location: node.getLocation(in: source)
			)
		}

		return try .init(
			inputType: inputType,
			arguments: arguments,
			outputType: .from(node: outputTypeNode, in: source),
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
		guard
			let identifierNode = node.child(
				byFieldName: "identifier"
			)
		else {
			throw .errorParsing(
				element: "TaggedExpression",
				location: node.getLocation(in: source)
			)
		}

		let expression: Syntax.Expression

		if let expressionNode = node.child(
			byFieldName: "expression"
		) {
			expression = try .from(
				node: expressionNode,
				in: source)
		} else {
			expression = .literal(
				.init(
					value: .nothing,
					location: node.getLocation(in: source)
				)
			)
		}

		let typeSpecifier: Syntax.Expression?
		if let typeSpecifierNode = node.child(
			byFieldName: "type_specifier"
		) {
			typeSpecifier = try .from(
				node: typeSpecifierNode,
				in: source
			)
		} else {
			typeSpecifier = nil
		}

		return try .init(
			tag: .from(node: identifierNode, in: source),
			typeSpecifier: typeSpecifier,
			expression: expression,
			location: node.getLocation(in: source)
		)
	}
}

extension Syntax.Expression: TreeSitterNode {

	static func from(
		node: Node,
		in source: Syntax.Source
	) throws(Syntax.Error) -> Self {
		switch node.expressionNodeType {
		case .literal:
			return try .literal(.from(node: node, in: source))
		case .unaryExpression:
			return try .unary(.from(node: node, in: source))
		case .binaryExpression:
			return try .binary(.from(node: node, in: source))
		case .qualifiedIdentifier:
			return try .nominal(.from(node: node, in: source))
		case .accessExpression:
			return try .access(.from(node: node, in: source))
		case .roundCallExpression, .squareCallExpression:
			return try .call(.from(node: node, in: source))
		case .squareExpressionList:
			return try .typeDefinition(.from(node: node, in: source))
		case .binding:
			return try .binding(.from(node: node, in: source))
		case .functionDefinition:
			return try .function(.from(node: node, in: source))
		case .taggedExpression:
			return try .taggedExpression(
				.from(node: node, in: source)
			)
		case .branchedExpression:
			return try .branched(.from(node: node, in: source))
		case .pipedExpression:
			return try .piped(.from(node: node, in: source))
		case .parenthesisExpression:
			guard let child = node.child(byFieldName: "expression") else {
				throw .errorParsing(
					element: "parenthesisExpression",
					location: node.getLocation(in: source)
				)
			}
			return try .from(node: child, in: source)
		case .none:
			throw .notImplemented(
				element: node.nodeType ?? "nil",
				location: node.getLocation(in: source)
			)
		}
	}
}

extension Syntax.Literal {
	static func from(
		node: Node,
		in source: Syntax.Source
	) throws(Syntax.Error) -> Self {
		guard let child = node.child(at: 0) else {
			throw .errorParsing(
				element: "literal no child",
				location: node.getLocation(in: source)
			)
		}
		let value: Syntax.Literal.Value
		switch child.literalNodeType {
		case .nothing:
			value = .nothing
		case .never:
			value = .never
		case .intLiteral:
			guard
				let intValue = try parseInteger(
					from: child.getString(in: source)
				)
			else {
				throw .errorParsing(
					element: "int literal failed to parse",
					location: node.getLocation(in: source)
				)
			}
			value = .intLiteral(intValue)
		case .floatLiteral:
			guard
				let floatValue = try Double(
					node.getString(in: source)
				)
			else {
				throw .errorParsing(
					element: "float literal failed to parse",
					location: node.getLocation(in: source)
				)
			}
			value = .floatLiteral(floatValue)
		case .stringLiteral:
			let stringValue = try node.getString(in: source)
			value = .stringLiteral(
				String(stringValue.dropFirst().dropLast())
			)
		case .boolLiteral:
			guard
				let boolValue = try Bool(
					node.getString(in: source)
				)
			else {
				throw .errorParsing(
					element: "bool literal failed to parse",
					location: node.getLocation(in: source)
				)
			}
			value = .boolLiteral(boolValue)
		case .none:
			throw .errorParsing(
				element: "literal",
				location: node.getLocation(in: source)
			)
		}

		return .init(
			value: value,
			location: node.getLocation(in: source)
		)
	}
}

extension Syntax.Unary: TreeSitterNode {
	static func from(
		node: Node,
		in source: Syntax.Source
	) throws(Syntax.Error) -> Self {
		guard let operatorNode = node.child(byFieldName: "operator"),
			let operandNode = node.child(byFieldName: "operand")
		else {
			throw .errorParsing(
				element: "UnaryExpression",
				location: node.getLocation(in: source)
			)
		}
		let operatorText = try operatorNode.getString(in: source)
		guard let operatorValue = Operator(rawValue: operatorText)
		else {
			throw .errorParsing(
				element: "UnaryOperator",
				location: operatorNode.getLocation(in: source)
			)
		}
		return try .init(
			op: operatorValue,
			expression: .from(node: operandNode, in: source),
			location: node.getLocation(in: source)
		)
	}
}

extension Syntax.Binary: TreeSitterNode {
	static func from(
		node: Node,
		in source: Syntax.Source
	) throws(Syntax.Error) -> Self {
		guard let leftNode = node.child(byFieldName: "left"),
			let operatorNode = node.child(byFieldName: "operator"),
			let rightNode = node.child(byFieldName: "right")
		else {
			throw .errorParsing(
				element: "BinaryExpression",
				location: node.getLocation(in: source)
			)
		}

		let operatorText = try operatorNode.getString(in: source)
		guard let operatorValue = Operator(rawValue: operatorText)
		else {
			throw .errorParsing(
				element: "BinaryOperator",
				location: operatorNode.getLocation(in: source)
			)
		}

		return try .init(
			op: operatorValue,
			left: .from(node: leftNode, in: source),
			right: .from(node: rightNode, in: source),
			location: node.getLocation(in: source)
		)
	}
}

extension Syntax.TypeDefinition: TreeSitterNode {
	static func from(
		node: Node,
		in source: Syntax.Source
	) throws(Syntax.Error) -> Self {
		return .init(
			expressions: try .from(node: node, in: source),
			location: node.getLocation(in: source)
		)
	}
}

extension [Syntax.Expression] {
	static func from(
		node: Node,
		in source: Syntax.Source
	) throws(Syntax.Error) -> [Syntax.Expression] {
		return try node.compactMapChildren {
			child throws(Syntax.Error) in
			if child.expressionNodeType != nil {
				try Syntax.Expression.from(
					node: child, in: source
				)
			} else {
				nil
			}
		}
	}
}

extension Syntax.Call: TreeSitterNode {
	static func from(
		node: Node,
		in source: Syntax.Source
	) throws(Syntax.Error) -> Self {
		let prefix: Syntax.Expression?
		if let prefixNode = node.child(byFieldName: "prefix") {
			prefix = try .from(node: prefixNode, in: source)
		} else {
			prefix = nil
		}

		let arguments: [Syntax.Expression]
		if let argumentListNode = node.child(byFieldName: "arguments") {
			if argumentListNode.nodeType == "round_expression_list" {
				arguments = try .from(
					node: argumentListNode, in: source
				)
			} else if argumentListNode.nodeType == "square_expression_list" {
				arguments = [
					try .typeDefinition(
						Syntax.TypeDefinition.from(
							node: argumentListNode, in: source
						))
				]
			} else {
				throw .errorParsing(
					element: "CallExpressionArguments",
					location: argumentListNode.getLocation(in: source)
				)
			}
		} else {
			arguments = []
		}

		// TODO: trailling closures

		return .init(
			prefix: prefix,
			arguments: arguments,
			location: node.getLocation(in: source)
		)
	}
}

extension Syntax.Access: TreeSitterNode {
	static func from(
		node: Node,
		in source: Syntax.Source
	) throws(Syntax.Error) -> Self {
		guard let prefixNode = node.child(byFieldName: "prefix"),
			let fieldNode = node.child(byFieldName: "field")
		else {
			throw .errorParsing(
				element: "AccessExpression",
				location: node.getLocation(in: source)
			)
		}
		return try .init(
			prefix: .from(node: prefixNode, in: source),
			field: fieldNode.getString(in: source),
			location: node.getLocation(in: source)
		)
	}
}

extension Syntax.Binding: TreeSitterNode {
	static func from(
		node: Node,
		in source: Syntax.Source
	) throws(Syntax.Error) -> Self {
		return try .init(
			// removing the $ character
			identifier: String(
				node.getString(in: source).dropFirst()
			),
			location: node.getLocation(in: source)
		)
	}
}

extension Syntax.Function: TreeSitterNode {
	static func from(
		node: Node,
		in source: Syntax.Source
	) throws(Syntax.Error) -> Self {
		guard let bodyNode = node.child(byFieldName: "body"),
			let bodyExpressionNode = bodyNode.child(at: 1)
		else {
			throw .errorParsing(
				element: "FunctionDefinition",
				location: node.getLocation(in: source)
			)
		}

		let signature: Syntax.FunctionType?
		if let signatureNode = node.child(byFieldName: "signature") {
			signature = try .from(node: signatureNode, in: source)
		} else {
			signature = nil
		}

		return try .init(
			signature: signature,
			body: .from(node: bodyExpressionNode, in: source)
		)
	}
}

extension Syntax.Pipe: TreeSitterNode {
	static func from(
		node: Node,
		in source: Syntax.Source
	) throws(Syntax.Error) -> Self {
		guard let leftNode = node.child(byFieldName: "left"),
			let rightNode = node.child(byFieldName: "right")
		else {
			throw .errorParsing(
				element: "PipedExpression",
				location: node.getLocation(in: source)
			)
		}
		return try .init(
			left: .from(node: leftNode, in: source),
			right: .from(node: rightNode, in: source),
			location: node.getLocation(in: source)
		)
	}
}

extension Syntax.Branched: TreeSitterNode {
	static func from(
		node: Node,
		in source: Syntax.Source
	) throws(Syntax.Error) -> Self {
		return try .init(
			branches:
				node
				.compactMapChildren {
					child throws(Syntax.Error) in
					if child.nodeType == "branch" {
						try .from(
							node: child,
							in: source
						)
					} else {
						nil
					}
				},
			location: node.getLocation(in: source)
		)
	}
}

extension Syntax.Branched.Branch {
	static func from(
		node: Node,
		in source: Syntax.Source
	) throws(Syntax.Error) -> Self {
		guard
			let bodyNode = node.child(byFieldName: "body")
		else {
			throw .errorParsing(
				element: "Branch",
				location: node.getLocation(in: source)
			)
		}

		let matchExpression: Syntax.Expression
		if let matchExpressionNode =
			node.child(byFieldName: "match_expression")
		{
			matchExpression = try .from(
				node: matchExpressionNode, in: source
			)
		} else {
			matchExpression = .literal(.init(value: .nothing))
		}

		let guardExpression: Syntax.Expression?
		if let guardExpressionNode =
			node.child(byFieldName: "guard_expression")
		{
			guardExpression = try .from(
				node: guardExpressionNode, in: source
			)
		} else {
			guardExpression = nil
		}

		return try .init(
			matchExpression: matchExpression,
			guardExpression: guardExpression,
			body: .from(node: bodyNode, in: source),
			location: node.getLocation(in: source)
		)
	}
}

#endif
