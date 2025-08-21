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

/// A ``Syntax.ModuleParser`` implementation using TreeSitter.
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

		var definitions: [Syntax.Definition] = []

		rootNode.enumerateChildren { node in
			if node.nodeType == "definition" {
				do throws(Syntax.Error) {
					try definitions.append(
						.from(
							node: node, in: source
						)
					)
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
	func compactMapChildren<T, E>(
		block: (Node) throws(E) -> T?
	) throws(E) -> [T] where E: Error {
		let optionalMap: [T?] = try (0 ..< childCount).map {
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
		let optionalMap: [T?] = try (0 ..< childCount).map {
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
		let range = self.range.lowerBound ..< self.range.upperBound
		let pointRange =
			Syntax.NodeLocation.Point(
				line: Int(self.pointRange.lowerBound.row),
				column: Int(self.pointRange.lowerBound.column)
			) ..< Syntax.NodeLocation.Point(
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

extension Syntax.Definition: TreeSitterNode {
	static func from(
		node: Node,
		in source: Syntax.Source
	) throws(Syntax.Error) -> Self {
		guard
			let identifierNode = node.child(
				byFieldName: "identifier"
			),
			let definitionNode = node.child(
				byFieldName: "definition"
			)
		else {
			throw .errorParsing(
				element: "TypeDefinition",
				location: node.getLocation(in: source)
			)
		}

		let typeSpecifier: Syntax.TypeSpecifier?
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

		let arguments: [Syntax.TypeField]
		if let argumentsNode = node.child(byFieldName: "type_arguments") {
			arguments =
				try argumentsNode
					.compactMapChildren {
						child throws(Syntax.Error) in
						if child.nodeType == "type_field" {
							return try Syntax.TypeField
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

		return try .init(
			identifier: .from(node: identifierNode, in: source),
			typeSpecifier: typeSpecifier,
			typeArguments: arguments,
			definition: .from(node: definitionNode, in: source),
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
		case "nothing":
			return .nothing(location: location)
		case "never":
			return .never(location: location)
		case "record_type":
			return try .recordType(.from(node: node, in: source))
		case "choice_type":
			return try .choiceType(.from(node: node, in: source))
		case "nominal":
			return try .nominal(.from(node: node, in: source))
		case "function":
			return try .function(.from(node: node, in: source))
		default:
			throw .errorParsing(
				element: "TypeSpecifier \(node.nodeType ?? "")",
				location: location
			)
		}
	}
}

extension Syntax.TaggedTypeSpecifier: TreeSitterNode {
	static func from(
		node: Node,
		in source: Syntax.Source
	) throws(Syntax.Error) -> Self {
		guard let identifierNode = node.child(byFieldName: "identifier")
		else {
			throw .errorParsing(
				element: "TaggedTypeSpecifier",
				location: node.getLocation(in: source)
			)
		}

		let definitionNode = node.child(byFieldName: "type_specifier")
		let typeSpecifier: Syntax.TypeSpecifier?
		if let definitionNode {
			typeSpecifier = try .from(
				node: definitionNode, in: source
			)
		} else {
			typeSpecifier = nil
		}
		return try .init(
			tag: identifierNode.getString(in: source),
			typeSpecifier: typeSpecifier,
			location: node.getLocation(in: source)
		)
	}
}

extension Syntax.HomogeneousTypeProduct: TreeSitterNode {
	static func from(
		node: Node,
		in source: Syntax.Source
	) throws(Syntax.Error) -> Self {
		guard
			let typeSpecifierNode = node.child(
				byFieldName: "type_specifier"
			),
			let exponentNode = node.child(byFieldName: "exponent")
		else {
			throw .errorParsing(
				element: "HomogeneousTypeProduct",
				location: node.getLocation(in: source)
			)
		}

		let count: Exponent
		switch exponentNode.nodeType {
		case "int_literal":
			guard
				let intValue = try parseInteger(
					from: node.getString(in: source)
				)
			else {
				throw .errorParsing(
					element: "int_literal",
					location: node.getLocation(in: source)
				)
			}
			count = .literal(intValue)
		case "scoped_identifier":
			count = try .identifier(
				.from(node: exponentNode, in: source)
			)
		default:
			throw .errorParsing(
				element: "count",
				location: node.getLocation(in: source)
			)
		}

		return try .init(
			typeSpecifier: .from(
				node: typeSpecifierNode, in: source
			),
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
				location: node.getLocation(in: source)
			)
		}
		switch child.nodeType {
		case "tagged_type_specifier":
			return try .taggedTypeSpecifier(
				.from(node: child, in: source)
			)
		case "homogeneous_product":
			return try .homogeneousTypeProduct(
				.from(node: child, in: source)
			)
		default:
			return try .typeSpecifier(
				.from(node: child, in: source)
			)
		}
	}
}

// MARK: - Algebraic Data Types

// ----------------------------

extension [Syntax.TypeField] {
	static func from(
		node: Node,
		in source: Syntax.Source
	) throws(Syntax.Error) -> [Syntax.TypeField] {
		return try node.compactMapChildren {
			child throws(Syntax.Error) in
			if child.nodeType == "type_field" {
				try .from(node: child, in: source)
			} else {
				nil
			}
		}
	}
}

extension Syntax.RecordType: TreeSitterNode {
	static func from(
		node: Node,
		in source: Syntax.Source
	) throws(Syntax.Error) -> Self {
		guard
			let typeFieldsNode = node.child(
				byFieldName: "type_field_list"
			)
		else {
			throw .errorParsing(
				element: "RecordType",
				location: node.getLocation(in: source)
			)
		}

		let typeFields: [Syntax.TypeField] =
			try .from(node: typeFieldsNode, in: source)

		return .init(
			typeFields: typeFields,
			location: node.getLocation(in: source)
		)
	}
}

extension Syntax.ChoiceType: TreeSitterNode {
	static func from(
		node: Node,
		in source: Syntax.Source
	) throws(Syntax.Error) -> Self {
		guard
			let typeFieldsNode = node.child(
				byFieldName: "type_field_list"
			)
		else {
			throw .errorParsing(
				element: "ChoiceType",
				location: node.getLocation(in: source)
			)
		}

		let typeFields: [Syntax.TypeField] =
			try .from(node: typeFieldsNode, in: source)

		return .init(
			typeFields: typeFields,
			location: node.getLocation(in: source)
		)
	}
}

extension [Syntax.Expression] {
	static let expressionNodeTypes = Set([
		"literal",
		"unary_expression",
		"binary_expression",
		"parenthisized_expression",
		"binding",
		"function_value",
		"call_expression",
		"access_expression",
		"tagged_expression",
		"branched_expression",
		"piped_expression",
		// types
		"record_type",
		"choice_type",
		"nominal",
		"function_type",
		"nothing",
		"never",
	])
	static func from(
		node: Node,
		in source: Syntax.Source
	) throws(Syntax.Error) -> [Syntax.Expression] {
		return try node.compactMapChildren {
			child throws(Syntax.Error) in
			if expressionNodeTypes.contains(child.nodeType ?? "") {
				try Syntax.Expression.from(
					node: child, in: source
				)
			} else {
				nil
			}
		}
	}
}

extension Syntax.Nominal: TreeSitterNode {
	static func from(
		node: Node,
		in source: Syntax.Source
	) throws(Syntax.Error) -> Self {
		guard let identifierNode = node.child(byFieldName: "identifier")
		else {
			throw .errorParsing(
				element: "Nominal", location: .nowhere
			)
		}

		let typeArguments: [Syntax.Expression]
		if let typeArgumentsNode = node.child(
			byFieldName: "type_arguments"
		) {
			typeArguments = try .from(
				node: typeArgumentsNode, in: source
			)
		} else {
			typeArguments = []
		}

		return try .init(
			identifier: .from(node: identifierNode, in: source),
			typeArguments: typeArguments,
			location: node.getLocation(in: source)
		)
	}
}

extension Syntax.FunctionType: TreeSitterNode {
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
					.compactMapChildren {
						child throws(Syntax.Error) in
						if child.nodeType == "type_field" {
							return try Syntax.TypeField
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
			),
			let expressionNode = node.child(
				byFieldName: "expression"
			)
		else {
			throw .errorParsing(
				element: "TaggedExpression",
				location: node.getLocation(in: source)
			)
		}
		return try .init(
			identifier: identifierNode.getString(in: source),
			expression: .from(node: expressionNode, in: source),
			location: node.getLocation(in: source)
		)
	}
}

extension Syntax.Expression: TreeSitterNode {
	static func from(
		node: Node,
		in source: Syntax.Source
	) throws(Syntax.Error) -> Self {
		switch node.nodeType {
		case "literal":
			return try .literal(.from(node: node, in: source))
		case "unary_expression":
			return try .unary(.from(node: node, in: source))
		case "binary_expression":
			return try .binary(.from(node: node, in: source))
		case "parenthisized_expression":
			guard
				let parenthesizedExpressionNode = node.child(
					at: 1
				)
			else {
				throw .errorParsing(
					element: "parenthisized_expression",
					location: node.getLocation(in: source)
				)
			}
			return try .from(
				node: parenthesizedExpressionNode,
				in: source
			)
		case "binding":
			return try .binding(.from(node: node, in: source))
		case "function_value":
			return try .function(.from(node: node, in: source))
		case "call_expression":
			return try .call(.from(node: node, in: source))
		case "access_expression":
			return try .access(.from(node: node, in: source))
		case "tagged_expression":
			return try .taggedExpression(
				.from(node: node, in: source)
			)
		case "branched_expression":
			return try .branched(.from(node: node, in: source))
		case "piped_expression":
			return try .piped(.from(node: node, in: source))
		// types:
		case "record_type":
			return try .typeSpecifier(
				.recordType(.from(node: node, in: source))
			)
		case "choice_type":
			return try .typeSpecifier(
				.choiceType(.from(node: node, in: source))
			)
		case "nominal":
			return try .nominal(.from(node: node, in: source))
		case "function_type":
			return try .typeSpecifier(
				.function(.from(node: node, in: source))
			)
		case "nothing":
			return .literal(
				.init(
					value: .nothing,
					location: node.getLocation(in: source)
				)
			)
		case "never":
			return .literal(
				.init(
					value: .never,
					location: node.getLocation(in: source)
				)
			)
		default:
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
				element: "Literal",
				location: node.getLocation(in: source)
			)
		}
		let value: Syntax.Literal.Value
		switch child.nodeType {
		case "int_literal":
			guard
				let intValue = try parseInteger(
					from: node.getString(in: source)
				)
			else {
				throw .errorParsing(
					element: "Int_literal",
					location: node.getLocation(in: source)
				)
			}
			value = .intLiteral(intValue)
		case "float_literal":
			guard
				let floatValue = try Double(
					node.getString(in: source)
				)
			else {
				throw .errorParsing(
					element: "Float_literal",
					location: node.getLocation(in: source)
				)
			}
			value = .floatLiteral(floatValue)
		case "string_literal":
			let stringValue = try node.getString(in: source)
			value = .stringLiteral(
				String(stringValue.dropFirst().dropLast())
			)
		case "bool_literal":
			guard
				let boolValue = try Bool(
					node.getString(in: source)
				)
			else {
				throw .errorParsing(
					element: "Bool_literal",
					location: node.getLocation(in: source)
				)
			}
			value = .boolLiteral(boolValue)
		default:
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
			arguments = try .from(
				node: argumentListNode, in: source
			)
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

//
//     static func parseFunction(
//         from node: Node,
//         in source: Syntax.Source
//     ) throws(Syntax.Error) -> Self {
//
//
//
//
