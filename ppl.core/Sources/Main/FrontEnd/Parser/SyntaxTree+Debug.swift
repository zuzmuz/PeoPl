// MARK: - Debug String Representations for AST

extension Operator: CustomDebugStringConvertible {
	public var debugDescription: String {
		rawValue
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
			"[\(pointRange.lowerBound.debugDescription)-\(pointRange.upperBound.debugDescription)]"
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
			return "   "
		case .notLast:
			return "│  "
		}
	}

	var debugDescription: String {
		return self.rawValue
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
		var descriptions: [String] = []
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
				"\(prefix)\(connector)Nominal: \(nominal)"
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
				"\(prefix)\(connector)\(binding)")

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
			"\(prefix)\(connector)Literal: \(value.debugDescription)")
	}
}

extension Syntax.Unary: ASTFormatableNode {
	fileprivate func formatAST(
		prefix: String,
		connector: Connector,
		descriptions: inout [String]
	) {
		descriptions.append("\(prefix)\(connector)\(self.op)")
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
		descriptions.append("\(prefix)\(connector)\(self.op)")
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
		descriptions.append("\(prefix)\(connector)TypeDefinition")
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

		descriptions.append("\(prefix)\(connector)Function")
		let hasArgs = !arguments.isEmpty
		let prefix = prefix + connector.childPrefix

		if let input {
			descriptions.append("\(prefix)\(Connector.notLast)InputType")
			input.formatAST(
				prefix: prefix + Connector.notLast.childPrefix,
				connector: .last,
				descriptions: &descriptions
			)
		}

		if hasArgs {
			descriptions.append("\(prefix)\(Connector.notLast)Arguments")
			for (index, arg) in arguments.enumerated() {
				let isLastArg = index == arguments.count - 1
				arg.formatAST(
					prefix: prefix + Connector.notLast.childPrefix,
					connector: isLastArg ? .last : .notLast,
					descriptions: &descriptions
				)
			}
		}

		descriptions.append("\(prefix)\(Connector.last)OutputType")
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
		descriptions.append("\(prefix)\(connector)Lambda")
		if let lambdaPrefix = self.prefix {
			descriptions.append("\(childPrefix)\(Connector.notLast)Prefix")
			lambdaPrefix.formatAST(
				prefix: childPrefix + Connector.notLast.childPrefix,
				connector: .last,
				descriptions: &descriptions)
		}
		descriptions.append("\(childPrefix)\(Connector.last)Body")
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
		descriptions.append("\(prefix)\(connector)Call")
		let childPrefix = prefix + connector.childPrefix
		if let callPrefix = self.prefix {
			let isLastNodeConnector =
				self.arguments.isEmpty ? Connector.last : Connector.notLast
			descriptions.append("\(childPrefix)\(isLastNodeConnector)Prefix")
			callPrefix.formatAST(
				prefix: childPrefix + isLastNodeConnector.childPrefix,
				connector: .last,
				descriptions: &descriptions
			)
		}
		if !self.arguments.isEmpty {
			descriptions.append("\(childPrefix)\(Connector.last)Arguments")
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
		descriptions.append("\(prefix)\(connector)Access: .\(self.field)")
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
		descriptions.append("\(prefix)\(connector)Tagged: \(self.tag)")
		if let typeSpec = self.typeSpecifier {
			descriptions.append("\(childPrefix)\(Connector.notLast)TypeSpec")
			typeSpec.formatAST(
				prefix: childPrefix + Connector.notLast.childPrefix,
				connector: .last,
				descriptions: &descriptions)
			descriptions.append("\(childPrefix)\(Connector.last)Expression")
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
		descriptions.append("\(prefix)\(connector)Branched")
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

		descriptions.append("\(prefix)\(connector)Branch")
		descriptions.append("\(childPrefix)\(Connector.notLast)Match")
		matchExpression.formatAST(
			prefix: childPrefix + Connector.notLast.childPrefix,
			connector: .last,
			descriptions: &descriptions
		)

		if let guardExpression {
			descriptions.append("\(childPrefix)\(Connector.notLast)Guard")
			guardExpression.formatAST(
				prefix: childPrefix + Connector.notLast.childPrefix,
				connector: .last,
				descriptions: &descriptions
			)
		}

		descriptions.append("\(childPrefix)\(Connector.last)Body")
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
		descriptions.append("\(prefix)\(connector)Pipe")
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

extension Syntax.Module: CustomDebugStringConvertible {
	public var debugDescription: String {
		var result = "Module: \(sourceName)\n"

		if !syntaxErrors.isEmpty {
			result +=
				"\(definitions.isEmpty ? "└─": "├─") Errors: \(syntaxErrors.count)\n"
			for (index, error) in syntaxErrors.enumerated() {
				let isLast = index == syntaxErrors.count - 1 && definitions.isEmpty
				result += "│  \(isLast ? "└─" : "├─") \(error)\n"
			}
		}

		if !definitions.isEmpty {
			result += "└─ Definitions: \(definitions.count)\n"
			var descriptions: [String] = []
			for (index, def) in definitions.enumerated() {
				let isLast = index == definitions.count - 1
				def.formatAST(
					prefix: "   ",
					connector: isLast ? .last : .notLast,
					descriptions: &descriptions)
			}
			result += descriptions.joined(separator: "\n")
		}

		return result
	}
}

// MARK: - Project

// extension Syntax.Project: CustomDebugStringConvertible {
// 	public var debugDescription: String {
// 		var result = "Project\n"
// 		let sortedModules = modules.sorted { $0.key < $1.key }
//
// 		for (index, (name, module)) in sortedModules.enumerated() {
// 			let isLast = index == sortedModules.count - 1
// 			let connector = isLast ? "└─ " : "├─ "
// 			let childPrefix = isLast ? "   " : "│  "
//
// 			result += "\(connector)\(name)\n"
// 			let moduleLines = module.debugDescription.split(separator: "\n")
// 			for (lineIndex, line) in moduleLines.enumerated() {
// 				let isLastLine = lineIndex == moduleLines.count - 1
// 				if lineIndex == 0 {
// 					result += "\(childPrefix)\(line)\n"
// 				} else {
// 					result += "\(childPrefix)\(line)\(isLastLine ? "" : "\n")"
// 				}
// 			}
// 			if !isLast {
// 				result += "\n"
// 			}
// 		}
//
// 		return result
// 	}
// }

// MARK: - DocString

extension Syntax.DocString: CustomDebugStringConvertible {
	public var debugDescription: String {
		"DocString: \"\(content)\""
	}
}
