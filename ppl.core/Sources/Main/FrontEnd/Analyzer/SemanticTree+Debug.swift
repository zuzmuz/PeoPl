#if ANALYZER

extension Semantic.Context {
    public func display() -> String {
        self.definitions.display()
    }
}

extension Semantic.DefinitionsContext {
    func display() -> String {
        self.valueDefinitions.map { signature, expression in
            "sign: \(signature.display()) -> exp: \(expression.display())"
        }.joined(separator: "\n---\n")

    }
}

extension Semantic.ExpressionSignature {
    func display() -> String {
        switch self {
        case let .function(function):
            function.display()
        case let .value(value):
            value.display()
        }
    }
}


#if !RELEASE
	import ArgumentParser
	import Utils

	extension Semantic {
		struct AnalyzeCommand: ParsableCommand {
			static let configuration = CommandConfiguration(
				commandName: "analyze",
				abstract: "Analyze the semantic tree")
			// TODO: add argument for parsing single file
			func run() throws {
				let logger = Utils.ConsoleLogger(level: .debug)
				logger.debug(tag: "Analyzer", message: "starting analysis")
				let project = try SourceManager.readCurrentDirectory()
				let result = project.semanticCheck()
				switch result {
				case let .failure(error):
					print("there was an error")
				case let .success(context):
					print(context.display(indent: 0))
				}
			}
		}
	}

	extension Int {
		fileprivate func indentString() -> String {
			String(repeating: " ", count: self * 4)
		}
	}

	extension String {
		fileprivate func withColor(
			_ colors: Utils.TerminalColor...
		) -> String {
			let colorCodes = colors.map { $0.rawValue }.joined()
			return "\(colorCodes)\(self)\(Utils.TerminalColor.reset.rawValue)"
		}
	}

	extension Semantic.DefinitionsContext {
		public func display(indent: Int) -> String {
			self.functionDefinitions.map { (signature, expression) -> String in
				indent.indentString()
					+ signature.display(indent: indent)
					+ " {\n".withColor(.dim, .brightBlack)
					+ expression.display(indent: indent + 1)
					+ "\n}".withColor(.dim)
			}.joined(separator: "\n\n")
		}
	}

	extension Semantic.FunctionSignature {
		func display(indent: Int) -> String {
			indent.indentString()
				+ inputType.type.display().withColor(.bgRed, .bold)
				+ ".".withColor(.dim, .brightBlack)
				+ identifier.display()
				+ "(".withColor(.dim, .brightBlack)
				+ arguments.map {
					"\($0.key.display()):_"
				}.joined(separator: ", ")
				+ ")".withColor(.dim, .brightBlack)
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
				return nominal.display()
			case let .raw(raw):
				if raw == .record([:]) {
					return ""
					// input is nothing and can be omitted
				}
				return raw.display()
			}
		}
	}

	extension Semantic.RawTypeSpecifier {
		func display() -> String {
			switch self {
			case let .record(fields):
				"record [(\(fields.map { "\($0.key.display()): \($0.value.display())" }.joined(separator: ", "))])"
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
		func display(indent: Int) -> String {
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
					"\(type.display())(\(op.rawValue) \(expression.display(indent: indent)))"
			case let .binary(op, left, right, _):
				return
					"\(type.display())(\(left.display(indent: indent)) \(op.rawValue) \(right.display(indent: indent)))"
			case let .call(signature, input, arguments, _):
				return
					"\(signature.display(indent: indent))(in: \(input.display(indent: indent)), )"
			// case let .branched(matrix, _):
			// 	return matrix.rows.map { row in
			// 		"\(row.pattern.display()) -> \(row.body.display(indent: indent))"
			// 	}.joined(separator: "\n")
			default:
				// print(self)
				fatalError("\(self) not implemented")
			// return ""
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
			return "{"
				+ fields.map { "\($0.key.display()): \($0.value.display())" }
				.joined(separator: ", ") + "}"
		case let .binding(name):
			return "$\(name.display())"
		case .wildcard:
			return "_"
		}
	}
}
#endif
#endif
