import ArgumentParser
import Foundation

extension Peopl {
	struct PrintASTCommand: AsyncParsableCommand {
		static let configuration = CommandConfiguration(
			commandName: "ast",
			abstract: "Print the AST of a PeoPl source file",
			discussion:
				"Parses a .ppl file and prints its Abstract Syntax Tree representation."
		)

		@Argument(help: "Path to the .ppl file to parse")
		var filePath: String

		@Flag(name: .shortAndLong, help: "Print only syntax errors if any")
		var errorsOnly: Bool = false

		func run() async throws {
			let fileURL = URL(filePath: filePath)

			// Check if file exists
			guard FileManager.default.fileExists(atPath: fileURL.path) else {
				throw Syntax.Error.fileNotFound(path: filePath)
			}

			// Check if file has .ppl extension
			if fileURL.pathExtension != "ppl" {
				print("Warning: File does not have .ppl extension")
			}

			// Parse the file
			let source = try Syntax.Source(url: fileURL)
			let module = TreeSitterModulParser.parseModule(source: source)

			// Print the AST
			if errorsOnly {
				if module.syntaxErrors.isEmpty {
					print("No syntax errors found.")
				} else {
					print("Syntax Errors (\(module.syntaxErrors.count)):")
					for (index, error) in module.syntaxErrors.enumerated() {
						print("[\(index + 1)] \(error)")
					}
				}
			} else {
				print(module.debugDescription)
			}
		}
	}
}
