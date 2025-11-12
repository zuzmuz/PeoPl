import ArgumentParser
import Foundation

extension Peopl {
	struct BuildCommand: AsyncParsableCommand {
		static let configuration = CommandConfiguration(
			commandName: "build",
			abstract: "Build the PeoPl project",
			discussion: "Builds the PeoPl project using the specified backend."
		)

		@Flag(name: .shortAndLong, help: "output llvm ir")
		var llvm: Bool = false

		@Option(name: .shortAndLong, help: "output file path")
		var output: String?

		func run() async throws {
			let fileManager = FileManager.default
			let currentDirectory = URL(
				filePath: fileManager.currentDirectoryPath
			)

			let contents = try fileManager.contentsOfDirectory(
				at: currentDirectory,
				includingPropertiesForKeys: [.isRegularFileKey],
				options: [.skipsHiddenFiles]
			)

			let modules: [String: Syntax.Module] =
				try contents.reduce(into: [:]) { acc, url in
					guard url.pathExtension == "ppl" else { return }
					let source = try Syntax.Source(url: url)
					acc[url.absoluteString] =
						TreeSitterModulParser.parseModule(source: source)
				}

			let project = Syntax.Project(
				modules: modules
			)

			// let context = try project.semanticCheck().get()
			//
			// print("\nResult of the semantic check:\n")
			//
			// print(context)
			//
			// print("\n-----------------------------\n")
			//
			// var llvmBuilder = LLVM.Builder(name: "PeoPl")
			//
			// try context.llvmBuild(llvm: &llvmBuilder)
			// if llvm {
			// 	llvmBuilder.save(to: output ?? "output.ll")
			// } else {
			// 	print("\nGenerated LLVM IR:\n")
			// 	print(llvmBuilder.generate())
			// }
		}
	}
}
