import ArgumentParser
import Foundation

@main
struct Peopl: AsyncParsableCommand {
	#if RELEASE
		static let configuration = CommandConfiguration(
			commandName: "peopl",
			abstract: "The PeoPl's Lang",
			version: "0.0.0.0",
			subcommands: [
				LspComand.self
			]
		)
	#else
		static let configuration = CommandConfiguration(
			commandName: "peopl",
			abstract: "The PeoPl's Lang",
			version: "0.0.0.0",
			subcommands: [
				LspComand.self,
				// Semantic.AnalyzeCommand.self,
				BuildCommand.self,
			]
		)
	#endif
}
