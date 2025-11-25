// MARK: - Debug String Representations for AST

import Utils

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
		descriptions: inout [String]
	)
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

extension Syntax.Expression: ASTFormatableNode {

	fileprivate func formatAST(
		prefix: String,
		connector: Connector,
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
		descriptions: inout [String]
	) {
		descriptions.append(
			"\(prefix)\(connector)\("Literal".colored(.cyan)) \(self.location): \(value.debugDescription.colored(.green))"
		)
	}
}

extension Syntax.Unary: ASTFormatableNode {
	fileprivate func formatAST(
		prefix: String,
		connector: Connector,
		descriptions: inout [String]
	) {
		descriptions.append("\(prefix)\(connector)\(self.op) \(self.location)")
		self.expression.formatAST(
			prefix: prefix + connector.childPrefix,
			connector: .last,
			descriptions: &descriptions
		)
	}
}

extension Syntax.Binary: ASTFormatableNode {
	fileprivate func formatAST(
		prefix: String,
		connector: Connector,
		descriptions: inout [String]
	) {
		descriptions.append("\(prefix)\(connector)\(self.op) \(self.location)")
		left.formatAST(
			prefix: prefix + connector.childPrefix,
			connector: .notLast,
			descriptions: &descriptions)
		right.formatAST(
			prefix: prefix + connector.childPrefix,
			connector: .last,
			descriptions: &descriptions)
	}
}

extension Syntax.TypeDefinition: ASTFormatableNode {
	fileprivate func formatAST(
		prefix: String,
		connector: Connector,
		descriptions: inout [String]
	) {
		descriptions.append(
			"\(prefix)\(connector)\("TypeDefinition".colored(.cyan)) \(self.location)")
		for (index, expr) in self.expressions.enumerated() {
			let isLastArg = index == self.expressions.count - 1
			expr.formatAST(
				prefix: prefix + connector.childPrefix,
				connector: isLastArg ? .last : .notLast,
				descriptions: &descriptions
			)
		}
	}
}

extension Syntax.Function: ASTFormatableNode {
	fileprivate func formatAST(
		prefix: String,
		connector: Connector,
		descriptions: inout [String]
	) {

		descriptions.append("\(prefix)\(connector)\("Function".colored(.cyan)) \(self.location)")
		let hasArgs = !arguments.isEmpty
		let prefix = prefix + connector.childPrefix

		if let input {
			descriptions.append(
				"\(prefix)\(Connector.notLast)\("InputType".colored(.cyan))")
			input.formatAST(
				prefix: prefix + Connector.notLast.childPrefix,
				connector: .last,
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
					descriptions: &descriptions
				)
			}
		}

		descriptions.append(
			"\(prefix)\(Connector.last)\("OutputType".colored(.cyan)) \(self.location)")
		output.formatAST(
			prefix: prefix + Connector.last.childPrefix,
			connector: .last,
			descriptions: &descriptions
		)
	}
}

extension Syntax.Lambda: ASTFormatableNode {
	fileprivate func formatAST(
		prefix: String,
		connector: Connector,
		descriptions: inout [String]
	) {
		let childPrefix = prefix + connector.childPrefix
		descriptions.append("\(prefix)\(connector)\("Lambda".colored(.cyan)) \(self.location)")
		if let lambdaPrefix = self.prefix {
			descriptions.append(
				"\(childPrefix)\(Connector.notLast)\("Prefix".colored(.cyan))")
			lambdaPrefix.formatAST(
				prefix: childPrefix + Connector.notLast.childPrefix,
				connector: .last,
				descriptions: &descriptions)
		}
		descriptions.append(
			"\(childPrefix)\(Connector.last)\("Body".colored(.cyan))")
		self.body.formatAST(
			prefix: childPrefix + Connector.last.childPrefix,
			connector: .last,
			descriptions: &descriptions
		)
	}
}

extension Syntax.Call: ASTFormatableNode {
	fileprivate func formatAST(
		prefix: String,
		connector: Connector,
		descriptions: inout [String]
	) {
		descriptions.append("\(prefix)\(connector)\("Call".colored(.cyan)) \(self.location)")
		let childPrefix = prefix + connector.childPrefix
		if let callPrefix = self.prefix {
			let isLastNodeConnector =
				self.arguments.isEmpty ? Connector.last : Connector.notLast
			descriptions.append(
				"\(childPrefix)\(isLastNodeConnector)\("Prefix".colored(.cyan))")
			callPrefix.formatAST(
				prefix: childPrefix + isLastNodeConnector.childPrefix,
				connector: .last,
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
					descriptions: &descriptions)
			}
		}
	}
}

extension Syntax.Access: ASTFormatableNode {
	fileprivate func formatAST(
		prefix: String,
		connector: Connector,
		descriptions: inout [String]
	) {
		let childPrefix = prefix + connector.childPrefix
		descriptions.append(
			"\(prefix)\(connector)\("Access".colored(.cyan)): .\(self.field.colored(.yellow)) \(self.location)"
		)
		self.prefix.formatAST(
			prefix: childPrefix,
			connector: .last,
			descriptions: &descriptions
		)
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
		descriptions: inout [String]
	) {
		let childPrefix = prefix + connector.childPrefix
		descriptions.append(
			"\(prefix)\(connector)\("Tagged".colored(.cyan)): \(self.tag.debugDescription.colored(.yellow)) \(self.location)"
		)
		if let typeSpec = self.typeSpecifier {
			descriptions.append(
				"\(childPrefix)\(Connector.notLast)\("TypeSpec".colored(.cyan))")
			typeSpec.formatAST(
				prefix: childPrefix + Connector.notLast.childPrefix,
				connector: .last,
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
				descriptions: &descriptions)
		}
	}
}

extension Syntax.Branched: ASTFormatableNode {
	fileprivate func formatAST(
		prefix: String,
		connector: Connector,
		descriptions: inout [String]
	) {
		let childPrefix = prefix + connector.childPrefix
		descriptions.append("\(prefix)\(connector)\("Branched".colored(.cyan)) \(self.location)")
		for (index, branch) in branches.enumerated() {
			let isLastBranch = index == branches.count - 1
			branch.formatAST(
				prefix: childPrefix,
				connector: isLastBranch ? .last : .notLast,
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
		descriptions: inout [String]
	) {
		let childPrefix = prefix + connector.childPrefix

		descriptions.append("\(prefix)\(connector)\("Branch".colored(.cyan)) \(self.location)")
		descriptions.append(
			"\(childPrefix)\(Connector.notLast)\("Match".colored(.cyan))")
		matchExpression.formatAST(
			prefix: childPrefix + Connector.notLast.childPrefix,
			connector: .last,
			descriptions: &descriptions
		)

		if let guardExpression {
			descriptions.append(
				"\(childPrefix)\(Connector.notLast)\("Guard".colored(.cyan))")
			guardExpression.formatAST(
				prefix: childPrefix + Connector.notLast.childPrefix,
				connector: .last,
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
		descriptions: inout [String]
	) {
		descriptions.append("\(prefix)\(connector)\("Pipe".colored(.cyan)) \(self.location)")
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
		descriptions: inout [String]
	) {
		descriptions.append(
			"\(prefix)\(connector)\("Module".colored(.brightBlue)): \(sourceName.colored(.yellow))"
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
					"\(errorPrefix)\(errorConnector)\(error.errorDescription?.colored(.red) ?? "")"
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
					descriptions: &descriptions)
			}
		}
	}
}

extension Syntax.Project: ASTFormatableNode {
    fileprivate func formatAST(
        prefix: String,
        connector: Connector,
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
