//
// extension Semantic.Context {
//     public func display() -> String {
//         self.definitions.display()
//     }
// }
//
// extension Semantic.DefinitionsContext {
//     func display() -> String {
//         self.valueDefinitions.map { signature, expression in
//             "sign: \(signature.display()) -> exp: \(expression.display())"
//         }.joined(separator: "\n---\n")
//
//     }
// }
//
// extension Semantic.ExpressionSignature {
//     func display() -> String {
//         switch self {
//         case let .function(function):
//             function.display()
//         case let .value(value):
//             value.display()
//         }
//     }
// }
//
extension Semantic.FunctionSignature {
	func display() -> String {
		"\(inputType.type.display()).\(identifier.display())(\(arguments.map { "\($0.key.display()):_" }.joined(separator: ", "))"
	}
}

extension Semantic.QualifiedIdentifier {
	func display() -> String {
		chain.joined(separator: "\\")
	}
}

extension Semantic.Tag {
	func display() -> String {
		switch self {
		case .input:
			"#input#"
		case let .named(name):
			name
		case let .unnamed(value):
			"_\(value)"
		}
	}
}

extension Semantic.TypeSpecifier {
	func display() -> String {
		switch self {
		case let .nominal(nominal):
			nominal.display()
		case let .raw(raw):
			raw.display()
		}
	}
}

extension Semantic.RawTypeSpecifier {
	func display() -> String {
		switch self {
		case let .record(fields):
			"record(\(fields.map { "\($0.key.display()): \($0.value.display())" }.joined(separator: ", ")))"
		case let .function(function):
			"funcion not implemented yet"
		case let .choice(fields):
			"choice not implemented yet"
		case .intrinsic:
			"intrinsic not implemented yet"
		}
	}
}

extension Semantic.Expression {
	func display() -> String {
		switch self {
		case let .intLiteral(value):
			return "\(value)"
		case let .floatLiteral(value):
			return "\(value)"
		case let .boolLiteral(value):
			return "\(value)"
		case let .input:
			return "\(type.display())(in)"
		case let .fieldInScope(tag, _):
			return "\(tag.display())"
		case let .unary(op, expression, _):
			return
				"\(type.display())(\(op.rawValue) \(expression.display()))"
		case let .binary(op, left, right, _):
			return
				"\(type.display())(\(left.display()) \(op.rawValue) \(right.display()))"
		case let .call(signature, input, arguments, _):
			return "\(signature.display())(in: \(input.display()), )"
		case let .branched(matrix, _):
			return matrix.rows.map { row in
				"\(row.pattern.display()) -> \(row.body.display())"
			}.joined(separator: "\n")
		default:
			print(self)
			return ""
		}
	}
}

extension Semantic.Pattern {
	func display() -> String {
		switch self {
		case let .value(value):
			return value.display()
		case let .constructor(tag, pattern):
			return "\(tag.display())(\(pattern.display()))"
		case let .destructor(fields):
			return "{" + fields.map { "\($0.key.display()): \($0.value.display())" }
				.joined(separator: ", ") + "}"
		case let .binding(name):
			return "$\(name.display())"
		case .wildcard:
			return "_"
		}
	}
}
