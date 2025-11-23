// MARK: - Debug String Representations for AST

// MARK: - Operator

extension Operator: CustomDebugStringConvertible {
	public var debugDescription: String {
		rawValue
	}
}

// MARK: - Location

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

// MARK: - Qualified Identifier

extension Syntax.QualifiedIdentifier: CustomDebugStringConvertible {
	public var debugDescription: String {
		chain.joined(separator: "\\")
	}
}

// MARK: - Expression

extension Syntax.Expression: CustomDebugStringConvertible {
	public var debugDescription: String {
		var descriptions: [String] = []
		formatAST(
			depth: 0,
			isLast: true,
			prefix: "",
			descriptions: &descriptions)
		return descriptions.joined(separator: "\n")
	}

	func formatAST(
		depth: Int,
		isLast: Bool,
		prefix: String,
		descriptions: inout [String]
	) {
		let connector = isLast ? "└─ " : "├─ "
		let childPrefix = prefix + (isLast ? "   " : "│  ")

		switch self {
		case .literal(let literal):
			descriptions.append(
				"\(prefix)\(connector)Literal: \(literal.value)"
			)

		case .unary(let unary):
			descriptions.append("\(prefix)\(connector)\(unary.op)")
			unary.expression.formatAST(
				depth: depth + 1,
				isLast: true,
				prefix: childPrefix,
				descriptions: &descriptions
			)

		case .binary(let binary):
			descriptions.append("\(prefix)\(connector)\(binary.op)")
			binary.left.formatAST(
				depth: depth + 1, isLast: false, prefix: childPrefix,
				descriptions: &descriptions)
			binary.right.formatAST(
				depth: depth + 1, isLast: true, prefix: childPrefix,
				descriptions: &descriptions)

		case .nominal(let nominal):
			descriptions.append(
				"\(prefix)\(connector)Nominal: \(nominal)"
			)

		case .typeDefinition(let typeDef):
			descriptions.append("\(prefix)\(connector)TypeDefinition")
			for (index, expr) in typeDef.expressions.enumerated() {
				let isLastExpr = index == typeDef.expressions.count - 1
				expr.formatAST(
					depth: depth + 1,
					isLast: isLastExpr,
					prefix: childPrefix,
					descriptions: &descriptions
				)
			}

		case .function(let function):
			descriptions.append("\(prefix)\(connector)Function")
			function.formatAST(
				depth: depth + 1,
				prefix: childPrefix,
				descriptions: &descriptions)

		case .lambda(let lambda):
			descriptions.append("\(prefix)\(connector)Lambda")
			if let lambdaPrefix = lambda.prefix {
				descriptions.append("\(childPrefix)├─ Prefix")
				lambdaPrefix.formatAST(
					depth: depth + 2,
					isLast: false,
					prefix: childPrefix + "│  ",
					descriptions: &descriptions)
			}
			let bodyConnector = "└─"
			descriptions.append("\(childPrefix)\(bodyConnector) Body")
			lambda.body.formatAST(
				depth: depth + 2,
				isLast: true,
				prefix: childPrefix + "   ",
				descriptions: &descriptions
			)

		case .call(let call):
			descriptions.append("\(prefix)\(connector)Call")
			if let callPrefix = call.prefix {
				descriptions.append("\(childPrefix)├─ Prefix")
				callPrefix.formatAST(
					depth: depth + 2,
					isLast: call.arguments.isEmpty,
					prefix: childPrefix + (call.arguments.isEmpty ? "   " : "│  "),
					descriptions: &descriptions
				)
			}
			if !call.arguments.isEmpty {
				descriptions.append("\(childPrefix)└─ Arguments")
				for (index, arg) in call.arguments.enumerated() {
					let isLastArg = index == call.arguments.count - 1
					arg.formatAST(
						depth: depth + 2,
						isLast: isLastArg,
						prefix: childPrefix + "   ",
						descriptions: &descriptions)
				}
			}

		case .access(let access):
			descriptions.append("\(prefix)\(connector)Access: .\(access.field)")
			access.prefix.formatAST(
				depth: depth + 1,
				isLast: true,
				prefix: childPrefix,
				descriptions: &descriptions
			)
		case .binding(let binding):
			descriptions.append(
				"\(prefix)\(connector)Binding: @\(binding.identifier)")

		case .taggedExpression(let tagged):
			descriptions.append("\(prefix)\(connector)Tagged: \(tagged.tag)")
			if let typeSpec = tagged.typeSpecifier {
				descriptions.append("\(childPrefix)├─ TypeSpec")
				typeSpec.formatAST(
					depth: depth + 2,
					isLast: false,
					prefix: childPrefix + "│  ",
					descriptions: &descriptions)
				descriptions.append("\(childPrefix)└─ Expression")
				tagged.expression.formatAST(
					depth: depth + 2,
					isLast: true,
					prefix: childPrefix + "   ",
					descriptions: &descriptions)
			} else {
				tagged.expression.formatAST(
					depth: depth + 1,
					isLast: true,
					prefix: childPrefix,
					descriptions: &descriptions)
			}

		case .branched(let branched):
			descriptions.append("\(prefix)\(connector)Branched")
			for (index, branch) in branched.branches.enumerated() {
				let isLastBranch = index == branched.branches.count - 1
				branch.formatAST(
					depth: depth + 1,
					isLast: isLastBranch,
					prefix: childPrefix,
					branchIndex: index,
					descriptions: &descriptions
				)
			}

		case .piped(let pipe):
			descriptions.append("\(prefix)\(connector)Pipe")
			pipe.left.formatAST(
				depth: depth + 1,
				isLast: false,
				prefix: childPrefix + "│  ",
				descriptions: &descriptions
			)
			pipe.right.formatAST(
				depth: depth + 1,
				isLast: true,
				prefix: childPrefix + "   ",
				descriptions: &descriptions
			)
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

extension Syntax.Literal: CustomDebugStringConvertible {
	public var debugDescription: String {
		value.debugDescription
	}
}

// MARK: - Unary

extension Syntax.Unary: CustomDebugStringConvertible {
	public var debugDescription: String {
		"Unary(\(op.debugDescription), \(expression.debugDescription))"
	}
}

// MARK: - Binary

extension Syntax.Binary: CustomDebugStringConvertible {
	public var debugDescription: String {
		"Binary(\(op.debugDescription), \(left.debugDescription), \(right.debugDescription))"
	}
}

// MARK: - Type Definition

extension Syntax.TypeDefinition: CustomDebugStringConvertible {
	public var debugDescription: String {
		if expressions.isEmpty {
			return "TypeDefinition()"
		}
		return "TypeDefinition(\(expressions.count) fields)"
	}
}

// MARK: - Function

extension Syntax.Function: CustomDebugStringConvertible {
	public var debugDescription: String {
		var descriptions: [String] = []
		formatAST(
			depth: 0,
			prefix: "",
			descriptions: &descriptions)
		return descriptions.joined(separator: "\n")
	}

	func formatAST(
		depth: Int,
		prefix: String,
		descriptions: inout [String]
	) {
		let hasArgs = !arguments.isEmpty

		if let input {
			descriptions.append("\(prefix)├─ InputType")
			input.formatAST(
				depth: depth + 1,
				isLast: true,
				prefix: prefix + "│  ",
				descriptions: &descriptions
			)
		}

		if hasArgs {
			descriptions.append("\(prefix)├─ Arguments")
			for (index, arg) in arguments.enumerated() {
				let isLastArg = index == arguments.count - 1
				arg.formatAST(
					depth: depth + 1,
					isLast: isLastArg,
					prefix: prefix + "│  ",
					descriptions: &descriptions
				)
			}
		}

		descriptions.append("\(prefix)└─ OutputType")
		output.formatAST(
			depth: depth + 1,
			isLast: true,
			prefix: prefix + "   ",
			descriptions: &descriptions
		)
	}
}
//
//
// // MARK: - Lambda
//
// extension Syntax.Lambda: CustomDebugStringConvertible {
// 	public var debugDescription: String {
// 		"Lambda"
// 	}
// }
//
// // MARK: - Call
//
// extension Syntax.Call: CustomDebugStringConvertible {
// 	public var debugDescription: String {
// 		"Call(\(arguments.count) args)"
// 	}
// }
//
// // MARK: - Access
//
// extension Syntax.Access: CustomDebugStringConvertible {
// 	public var debugDescription: String {
// 		"Access(.\(field))"
// 	}
// }
//
// // MARK: - Binding
//
// extension Syntax.Binding: CustomDebugStringConvertible {
// 	public var debugDescription: String {
// 		"Binding(@\(identifier))"
// 	}
// }
//
// MARK: - Tagged Expression

extension Syntax.TaggedExpression: CustomDebugStringConvertible {
	// FIXME: this is not correct it should format the ast
	public var debugDescription: String {
		"Tagged(\(tag.debugDescription))"
	}
}
//
// // MARK: - Branch
//
extension Syntax.Branched.Branch: CustomDebugStringConvertible {
	public var debugDescription: String {
		"Branch"
	}

	func formatAST(
		depth: Int,
		isLast: Bool,
		prefix: String,
		branchIndex: Int,
		descriptions: inout [String]
	) {
		let connector = isLast ? "└─ " : "├─ "
		let childPrefix = prefix + (isLast ? "   " : "│  ")

		descriptions.append("\(prefix)\(connector)Branch[\(branchIndex)]")
		descriptions.append("\(childPrefix)├─ Match")
		matchExpression.formatAST(
			depth: depth + 1,
			isLast: true,
			prefix: childPrefix + "│  ",
			descriptions: &descriptions
		)

		if let guardExpression {
			descriptions.append("\(childPrefix)├─ Guard")
			guardExpression.formatAST(
				depth: depth + 1,
				isLast: true,
				prefix: childPrefix + "│  ",
				descriptions: &descriptions
			)
		}

		descriptions.append("\(childPrefix)└─ Body")
		body.formatAST(
			depth: depth + 1,
			isLast: true,
			prefix: childPrefix + "   ",
			descriptions: &descriptions
		)
	}
}
//
// MARK: - Branched

extension Syntax.Branched: CustomDebugStringConvertible {
	public var debugDescription: String {
		"Branched(\(branches.count) branches)"
	}
}

// MARK: - Pipe

extension Syntax.Pipe: CustomDebugStringConvertible {
	public var debugDescription: String {
		var descriptions = ["Pipe"]
		left.formatAST(
			depth: 1,
			isLast: false,
			prefix: "│  ",
			descriptions: &descriptions
		)
		right.formatAST(
			depth: 1,
			isLast: false,
			prefix: "│  ",
			descriptions: &descriptions
		)
		return descriptions.joined(separator: "\n")
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
					depth: 1,
					isLast: isLast,
					prefix: "   ",
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
