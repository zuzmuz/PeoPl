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
				LspComand.self,
				// AnalyzeCommand.self,
				BuildCommand.self,
			]
		)
	#else
		static let configuration = CommandConfiguration(
			commandName: "peopl",
			abstract: "The PeoPl's Lang",
			version: "0.0.0.0",
			subcommands: [
				LspComand.self
			]
		)
	#endif
}
