// MARK: - Debug String Representations for AST

import Utils

private enum Connector: String, CustomDebugStringConvertible {
	case last = "└─ "
	case notLast = "├─ "

	var childPrefix: String {
		switch self {
		case .last:
			return "   ".colored(.brightBlack)
		case .notLast:
			return "│  ".colored(.brightBlack)
		}
	}

	var debugDescription: String {
		return self.rawValue.colored(.brightBlack)
	}
}

private protocol ASTFormatableNode: CustomDebugStringConvertible {
	func formatAST(
		prefix: String,
		connector: Connector,
		extra: String,
		descriptions: inout [String]
	)

	func formatAST(
		prefix: String,
		connector: Connector,
		descriptions: inout [String]
	)
}

extension ASTFormatableNode {
	func formatAST(
		prefix: String,
		connector: Connector,
		descriptions: inout [String]
	) {
		formatAST(
			prefix: prefix,
			connector: connector,
			extra: "",
			descriptions: &descriptions)
	}
}

extension ASTFormatableNode {
	public var debugDescription: String {
		var descriptions: [String] = [""]
		formatAST(
			prefix: "",
			connector: .last,
			descriptions: &descriptions)
		return descriptions.joined(separator: "\n")
	}
}

extension Operator: CustomDebugStringConvertible {
	public var debugDescription: String {
		rawValue.colored(.magenta)
	}
}

extension Syntax.NodeLocation.Point: CustomDebugStringConvertible {
	public var debugDescription: String {
		"\(line):\(column)"
	}
}

extension Syntax.NodeLocation: CustomDebugStringConvertible {
	public var debugDescription: String {
		if self == .nowhere {
			return "<nowhere>"
		}
		return
			"[\(pointRange.lowerBound)-\(pointRange.upperBound)]".colored(.dim)
	}
}

extension Syntax.QualifiedIdentifier: CustomDebugStringConvertible {
	public var debugDescription: String {
		chain.joined(separator: "\\")
	}
}

extension Syntax.Expression: ASTFormatableNode {
	fileprivate func formatAST(
		prefix: String,
		connector: Connector,
		extra: String,
		descriptions: inout [String]
	) {
		switch self {
		case .literal(let literal):
			literal.formatAST(
				prefix: prefix,
				connector: connector,
				descriptions: &descriptions)

		case .unary(let unary):
			unary.formatAST(
				prefix: prefix,
				connector: connector,
				descriptions: &descriptions)

		case .binary(let binary):
			binary.formatAST(
				prefix: prefix,
				connector: connector,
				descriptions: &descriptions)

		case .nominal(let nominal):
			descriptions.append(
				"\(prefix)\(connector)\("Nominal".colored(.brightCyan)): \(nominal.debugDescription.colored(.yellow))"
			)

		case .typeDefinition(let typeDefinition):
			typeDefinition.formatAST(
				prefix: prefix,
				connector: connector,
				descriptions: &descriptions)

		case .function(let function):
			function.formatAST(
				prefix: prefix,
				connector: connector,
				descriptions: &descriptions)

		case .lambda(let lambda):
			lambda.formatAST(
				prefix: prefix,
				connector: connector,
				descriptions: &descriptions)

		case .call(let call):
			call.formatAST(
				prefix: prefix,
				connector: connector,
				descriptions: &descriptions)

		case .access(let access):
			access.formatAST(
				prefix: prefix,
				connector: connector,
				descriptions: &descriptions)

		case .binding(let binding):
			descriptions.append(
				"\(prefix)\(connector)\("Binding".colored(.cyan)): \(binding.identifier.colored(.yellow))"
			)

		case .positional(let positional):
			descriptions.append(
				"\(prefix)\(connector)\("Positional".colored(.cyan)): \(String(positional.index).colored(.yellow))"
			)

		case .taggedExpression(let tagged):
			tagged.formatAST(
				prefix: prefix,
				connector: connector,
				descriptions: &descriptions)

		case .branched(let branched):
			branched.formatAST(
				prefix: prefix,
				connector: connector,
				descriptions: &descriptions)

		case .piped(let pipe):
			pipe.formatAST(
				prefix: prefix,
				connector: connector,
				descriptions: &descriptions)
		}
	}
}

// MARK: - Literal Value

extension Syntax.Literal.Value: CustomDebugStringConvertible {
	public var debugDescription: String {
		switch self {
		case .special:
			return "_"
		case .nothing:
			return "nothing"
		case .never:
			return "never"
		case .intLiteral(let value):
			return "\(value)"
		case .floatLiteral(let value):
			return "\(value)"
		case .stringLiteral(let value):
			return "\"\(value)\""
		case .boolLiteral(let value):
			return "\(value)"
		}
	}
}

extension Syntax.Literal: ASTFormatableNode {
	fileprivate func formatAST(
		prefix: String,
		connector: Connector,
		extra: String,
		descriptions: inout [String]
	) {
		descriptions.append(
			"\(prefix)\(connector)\(extra)\("Literal".colored(.cyan)) \(self.location): \(value.debugDescription.colored(.green))"
		)
	}
}

extension Syntax.Unary: ASTFormatableNode {
	fileprivate func formatAST(
		prefix: String,
		connector: Connector,
		extra: String,
		descriptions: inout [String]
	) {
		descriptions.append("\(prefix)\(connector)\(extra)\(self.op) \(self.location)")
		self.expression.formatAST(
			prefix: prefix + connector.childPrefix,
			connector: .last,
			extra: "expr: ",
			descriptions: &descriptions
		)
	}
}

extension Syntax.Binary: ASTFormatableNode {
	fileprivate func formatAST(
		prefix: String,
		connector: Connector,
		extra: String,
		descriptions: inout [String]
	) {
		descriptions.append("\(prefix)\(connector)\(extra)\(self.op) \(self.location)")
		left.formatAST(
			prefix: prefix + connector.childPrefix,
			connector: .notLast,
			extra: "lhs: ",
			descriptions: &descriptions)
		right.formatAST(
			prefix: prefix + connector.childPrefix,
			connector: .last,
			extra: "rhs: ",
			descriptions: &descriptions)
	}
}

extension Syntax.TypeDefinition: ASTFormatableNode {
	fileprivate func formatAST(
		prefix: String,
		connector: Connector,
		extra: String,
		descriptions: inout [String]
	) {
		descriptions.append(
			"\(prefix)\(connector)\(extra)\("TypeDefinition".colored(.cyan)) \(self.location)"
		)
		for (index, expr) in self.expressions.enumerated() {
			let isLastArg = index == self.expressions.count - 1
			expr.formatAST(
				prefix: prefix + connector.childPrefix,
				connector: isLastArg ? .last : .notLast,
				extra: "#\(index): ",
				descriptions: &descriptions
			)
		}
	}
}

extension Syntax.Function: ASTFormatableNode {
	fileprivate func formatAST(
		prefix: String,
		connector: Connector,
		extra: String,
		descriptions: inout [String]
	) {

		descriptions.append(
			"\(prefix)\(connector)\(extra)\("Function".colored(.cyan)) \(self.location)")
		let hasArgs = !arguments.isEmpty
		let prefix = prefix + connector.childPrefix

		if let input {
			input.formatAST(
				prefix: prefix + Connector.notLast.childPrefix,
				connector: .last,
				extra: "input: ",
				descriptions: &descriptions
			)
		}

		if hasArgs {
			descriptions.append(
				"\(prefix)\(Connector.notLast)\("Arguments".colored(.cyan))")
			for (index, arg) in arguments.enumerated() {
				let isLastArg = index == arguments.count - 1
				arg.formatAST(
					prefix: prefix + Connector.notLast.childPrefix,
					connector: isLastArg ? .last : .notLast,
					extra: "#\(index): ",
					descriptions: &descriptions
				)
			}
		}

		output.formatAST(
			prefix: prefix + Connector.last.childPrefix,
			connector: .last,
			extra: "output: ",
			descriptions: &descriptions
		)
	}
}

extension Syntax.Lambda: ASTFormatableNode {
	fileprivate func formatAST(
		prefix: String,
		connector: Connector,
		extra: String,
		descriptions: inout [String]
	) {
		let childPrefix = prefix + connector.childPrefix
		descriptions.append(
			"\(prefix)\(connector)\(extra)\("Lambda".colored(.cyan)) \(self.location)")
		if let lambdaPrefix = self.prefix {
			lambdaPrefix.formatAST(
				prefix: childPrefix + Connector.notLast.childPrefix,
				connector: .last,
				extra: "prefix: ",
				descriptions: &descriptions)
		}
		descriptions.append(
			"\(childPrefix)\(Connector.last)\("Body".colored(.cyan))")
		if let lambdaBody = self.body {
			lambdaBody.formatAST(
				prefix: childPrefix + Connector.last.childPrefix,
				connector: .last,
				descriptions: &descriptions
			)
		}
	}
}

extension Syntax.Call: ASTFormatableNode {
	fileprivate func formatAST(
		prefix: String,
		connector: Connector,
		extra: String,
		descriptions: inout [String]
	) {
		descriptions.append(
			"\(prefix)\(connector)\(extra)\("Call".colored(.cyan)) \(self.location)")
		let childPrefix = prefix + connector.childPrefix
		if let callPrefix = self.prefix {
			let isLastNodeConnector =
				self.arguments.isEmpty ? Connector.last : Connector.notLast
			callPrefix.formatAST(
				prefix: childPrefix + isLastNodeConnector.childPrefix,
				connector: .last,
				extra: "prefix: ",
				descriptions: &descriptions
			)
		}
		if !self.arguments.isEmpty {
			descriptions.append(
				"\(childPrefix)\(Connector.last)\("Arguments".colored(.cyan))")
			for (index, arg) in self.arguments.enumerated() {
				let isLastArg = index == self.arguments.count - 1
				arg.formatAST(
					prefix: childPrefix + Connector.last.childPrefix,
					connector: isLastArg ? .last : .notLast,
					extra: "#\(index): ",
					descriptions: &descriptions)
			}
		}
	}
}

extension Syntax.Access: ASTFormatableNode {
	fileprivate func formatAST(
		prefix: String,
		connector: Connector,
		extra: String,
		descriptions: inout [String]
	) {
		let childPrefix = prefix + connector.childPrefix
		descriptions.append(
			"\(prefix)\(connector)\(extra)\("Access".colored(.cyan)): .\(self.field.debugDescription.colored(.yellow)) \(self.location)"
		)
		self.prefix.formatAST(
			prefix: childPrefix,
			connector: .last,
			descriptions: &descriptions
		)
	}
}

extension Syntax.Access.Field: CustomDebugStringConvertible {
	public var debugDescription: String {
		switch self {
		case .named(let value):
			return value
		case .positional(let value):
			return "\(value)"
		}
	}
}

extension Syntax.Binding: CustomDebugStringConvertible {
	public var debugDescription: String {
		"Binding: \(self.identifier)"
	}
}

extension Syntax.TaggedExpression: ASTFormatableNode {
	fileprivate func formatAST(
		prefix: String,
		connector: Connector,
		extra: String,
		descriptions: inout [String]
	) {
		let childPrefix = prefix + connector.childPrefix
		descriptions.append(
			"\(prefix)\(connector)\(extra)\("Tagged".colored(.cyan)): \(self.tag.debugDescription.colored(.yellow)) \(self.location)"
		)
		if let typeSpec = self.typeSpecifier {
			typeSpec.formatAST(
				prefix: childPrefix + Connector.notLast.childPrefix,
				connector: .last,
				extra: "typeSpec: ",
				descriptions: &descriptions)
			descriptions.append(
				"\(childPrefix)\(Connector.last)\("Expression".colored(.cyan))")
			self.expression.formatAST(
				prefix: childPrefix + Connector.last.childPrefix,
				connector: .last,
				descriptions: &descriptions)
		} else {
			self.expression.formatAST(
				prefix: childPrefix,
				connector: .last,
				extra: "expr: ",
				descriptions: &descriptions)
		}
	}
}

extension Syntax.Branched: ASTFormatableNode {
	fileprivate func formatAST(
		prefix: String,
		connector: Connector,
		extra: String,
		descriptions: inout [String]
	) {
		let childPrefix = prefix + connector.childPrefix
		descriptions.append(
			"\(prefix)\(connector)\(extra)\("Branched".colored(.cyan)) \(self.location)")
		for (index, branch) in branches.enumerated() {
			let isLastBranch = index == branches.count - 1
			branch.formatAST(
				prefix: childPrefix,
				connector: isLastBranch ? .last : .notLast,
				extra: "branch #\(index): ",
				descriptions: &descriptions
			)
		}
	}
}

extension Syntax.Branched.Branch: ASTFormatableNode {
	// TODO: branch index
	fileprivate func formatAST(
		prefix: String,
		connector: Connector,
		extra: String,
		descriptions: inout [String]
	) {
		let childPrefix = prefix + connector.childPrefix

		descriptions.append(
			"\(prefix)\(connector)\(extra)\("Branch".colored(.cyan)) \(self.location)")
		matchExpression.formatAST(
			prefix: childPrefix + Connector.notLast.childPrefix,
			connector: .last,
			extra: "match: ",
			descriptions: &descriptions
		)

		if let guardExpression {
			guardExpression.formatAST(
				prefix: childPrefix + Connector.notLast.childPrefix,
				connector: .last,
				extra: "guard: ",
				descriptions: &descriptions
			)
		}

		descriptions.append(
			"\(childPrefix)\(Connector.last)\("Body".colored(.cyan))")
		body.formatAST(
			prefix: childPrefix + Connector.last.childPrefix,
			connector: .last,
			descriptions: &descriptions
		)
	}
}

extension Syntax.Pipe: ASTFormatableNode {
	fileprivate func formatAST(
		prefix: String,
		connector: Connector,
		extra: String,
		descriptions: inout [String]
	) {
		descriptions.append(
			"\(prefix)\(connector)\(extra)\("Pipe".colored(.cyan)) \(self.location)")
		let childPrefix = prefix + connector.childPrefix
		left.formatAST(
			prefix: childPrefix,
			connector: .notLast,
			descriptions: &descriptions
		)
		right.formatAST(
			prefix: childPrefix,
			connector: .last,
			descriptions: &descriptions
		)
	}
}

// MARK: - Module

extension Syntax.Module: ASTFormatableNode {
	fileprivate func formatAST(
		prefix: String,
		connector: Connector,
		extra: String,
		descriptions: inout [String]
	) {
		descriptions.append(
			"\(prefix)\(connector)\(extra)\("Module".colored(.brightBlue)): \(sourceName.colored(.yellow))"
		)
		let childPrefix = prefix + connector.childPrefix
		if !syntaxErrors.isEmpty {
			let connector =
				definitions.isEmpty ? Connector.last : Connector.notLast
			descriptions.append(
				"\(childPrefix)\(connector)\("Errors".colored(.red)): \(syntaxErrors.count)"
			)
			let errorPrefix =
				childPrefix
				+ (descriptions.isEmpty
					? Connector.last.childPrefix : Connector.notLast.childPrefix)
			for (index, error) in syntaxErrors.enumerated() {
				let errorConnector =
					index == syntaxErrors.count - 1
					? Connector.last : Connector.notLast
				descriptions.append(
					"\(errorPrefix)\(errorConnector)#\(index): \(error.errorDescription?.colored(.red) ?? "")"
				)
			}
		}

		if !definitions.isEmpty {
			descriptions.append(
				"\(childPrefix)\(Connector.last)\("Definitions".colored(.brightGreen)): \(definitions.count)"
			)
			for (index, definition) in definitions.enumerated() {
				let isLast = index == definitions.count - 1
				definition.formatAST(
					prefix: childPrefix + Connector.last.childPrefix,
					connector: isLast ? .last : .notLast,
					extra: "#\(index): ",
					descriptions: &descriptions)
			}
		}
	}
}

extension Syntax.Project: ASTFormatableNode {
	fileprivate func formatAST(
		prefix: String,
		connector: Connector,
		extra: String,
		descriptions: inout [String]
	) {
		// TODO: Implement project AST formatting
	}
}

extension Syntax.DocString: CustomDebugStringConvertible {
	public var debugDescription: String {
		"\("DocString".colored(.cyan)): \"\(content.colored(.green))\""
	}
}

// MARK: - Semantic

extension Semantic.QualifiedIdentifier: CustomDebugStringConvertible {
	public var debugDescription: String {
		chain.map { $0.description }.joined(separator: "\\")
	}
}

extension Semantic.Expression: ASTFormatableNode {
	fileprivate func formatAST(
		prefix: String,
		connector: Connector,
		extra: String,
		descriptions: inout [String]
	) {
		let firstPrefix = prefix + connector.rawValue + extra
		switch self {
		case .literal(let literal):
			descriptions.append(
				"\(firstPrefix)\("Literal".colored(.cyan)) value \(literal.debugDescription.colored(.green))")

			literal.type.formatAST(
				prefix: prefix + connector.childPrefix,
				connector: .last,
				extra: "type: ",
				descriptions: &descriptions)
		case .unary(let op, let expression, let type, let kind):
			descriptions.append(
				"\(firstPrefix)\("Unary".colored(.cyan)) operator \(op.debugDescription), Kind: \(kind)")
			expression.formatAST(
				prefix: prefix + connector.childPrefix,
				connector: .notLast,
				extra: "expr: ",
				descriptions: &descriptions)
			type.formatAST(
				prefix: prefix + connector.childPrefix,
				connector: .last,
				extra: "type: ",
				descriptions: &descriptions)
		case .binary(let op, let lhs, let rhs, let type, let kind):
			descriptions.append(
				"\(firstPrefix)\("Binary".colored(.cyan)) operator \(op.debugDescription), Kind: \(kind)")
			lhs.formatAST(
				prefix: prefix + connector.childPrefix,
				connector: .notLast,
				extra: "lhs: ",
				descriptions: &descriptions)
			rhs.formatAST(
				prefix: prefix + connector.childPrefix,
				connector: .notLast,
				extra: "rhs: ",
				descriptions: &descriptions)
			type.formatAST(
				prefix: prefix + connector.childPrefix,
				connector: .last,
				extra: "type: ",
				descriptions: &descriptions)
		case .type:
			descriptions.append(
				"\(firstPrefix)\("Type".colored(.cyan))")
		case .nominal(let nominal, let type, let kind):
			descriptions.append(
				"\(firstPrefix)\("Nominal".colored(.cyan)), value: \(nominal.debugDescription.colored(.yellow)), kind: \(kind)")
			type.formatAST(
				prefix: prefix + connector.childPrefix,
				connector: .last,
				extra: "type: ",
				descriptions: &descriptions)
		case .operation(let lhs, let rhs, let output):
			descriptions.append(
				"\(firstPrefix)Operation".colored(.cyan))
			lhs.formatAST(
				prefix: prefix + connector.childPrefix,
				connector: .notLast,
				extra: "lhs: ",
				descriptions: &descriptions)
			rhs.formatAST(
				prefix: prefix + connector.childPrefix,
				connector: .notLast,
				extra: "rhs: ",
				descriptions: &descriptions)
			output.formatAST(
				prefix: prefix + connector.childPrefix,
				connector: .last,
				extra: "output: ",
				descriptions: &descriptions)
		case .invalid:
			descriptions.append(
				"\(firstPrefix)\("Invalid".colored(.red))")
		default:
			descriptions.append(
				"\(firstPrefix)\("Unsupported Semantic Expression".colored(.red))")
		}
	}
}

extension Semantic.Literal: CustomDebugStringConvertible {
	public var debugDescription: String {
		switch self {
		case .int(let int):
			"\(int)"
		case .float(let float):
			"\(float)"
		case .bool(let bool):
			"\(bool)"
		}
	}
}

extension Semantic.Context {
	var debugDisplay: String {
		var descriptions: [String] = []
		for (key, value) in self {
			descriptions.append(
				"\(key.debugDescription.colored(.yellow))"
			)
			value.formatAST(
				prefix: " ",
				connector: .last,
				descriptions: &descriptions)
		}
		return descriptions.joined(separator: "\n")
	}
}
