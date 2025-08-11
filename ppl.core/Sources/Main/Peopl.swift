import ArgumentParser
import Foundation

@main
struct Peopl: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "peopl",
        abstract: "The PeoPl's Lang",
        version: "0.0.0.0",
        subcommands: [LspComand.self, Build.self],
    )

    struct Build: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "build",
            abstract: "Build the PeoPl project",
            discussion: "Builds the PeoPl project using the specified backend."
        )

        @Flag(name: .shortAndLong, help: "Use LLVM as the backend")
        var llvm: Bool = false

        func run() async throws {
            if llvm {
                print("Building with LLVM backend...")
                // Implement LLVM build logic here
            } else {
                print("No backend specified. Use --llvm to build with LLVM.")
            }
        }
    }
}
