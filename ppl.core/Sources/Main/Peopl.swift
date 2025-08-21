import ArgumentParser
import Foundation

@main
struct Peopl: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "peopl",
		abstract: "The PeoPl's Lang",
		version: "0.0.0.0",
		subcommands: [LspComand.self, BuildCommand.self]
	)
}
