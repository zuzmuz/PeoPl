import Foundation
import ArgumentParser

enum CommandLineError: LocalizedError {
    case invalidArguments(String)

    var errorDescription: String? {
        switch self {
        case .invalidArguments(let message):
            return message
        }
    }
}

enum Command {
    case lsp(LspCommand)
    case build(BuildCommand)

    init(args: [String]) throws(CommandLineError) {
        guard args.count > 1 else {
            throw CommandLineError.invalidArguments("no command provided")
        }

        switch args[1] {
        case "lsp":
            self = try .lsp(.init(args: args))
        default:
            throw CommandLineError.invalidArguments(
                "unknown command \(args[1])")
        }
    }

    func run() async throws {
        switch self {
        case .lsp(let command):
            try await command.run()
        default:
            break
        }
    }
}

func printUsage() {
    print("usage: ppl <command>")
    print("commands:")
    print(
        "- lsp               Run the language server protocol server using standard input and output as transport"
    )  // swiftlint:disable:previous line_length
    print(
        "- lsp socket <port> Run the language server protocol server using a TCP socket as transport on selected port"
    )  // swiftlint:disable:previous line_length
    print(
        "- lsp proxy <port>  Run the proxy language server protocol server using standard input and output as transport communicating with a socket server on selected port"
    )  // swiftlint:disable:previous line_length
}

// let args = CommandLine.arguments
// do {
//     let command = try Command.init(args: args)
//     try await command.run()
//
// } catch {
//     print("error: \(error.localizedDescription)")
//     print()
//     printUsage()
// }


// @main
// struct PplCommand: AsyncParsableCommand {
//     static let configuration = CommandConfiguration(
//         commandName: "peopl",
//         abstract: "The PeoPl's Lang",
//         version: "0.0.0.0",
//         subcommands: [Lsp.self, Build.self, Run.self],
//     )
//
//     struct Lsp: AsyncParsableCommand {
//         static let configuration = CommandConfiguration(
//             abstract: "Start the Language Server Protocol server"
//         )
//         
//         // @OptionGroup var globalOptions: GlobalOptions
//
//         @Flag(name: .shortAndLong, help: "Run as Proxy LSP server")
//         var proxy: Bool = false
//
//         // @Flag
//         
//         @Option(name: .shortAndLong, help: "Port to run LSP server on")
//         var proxy: Int = 8080
//         
//         // @Option(help: "Host address to bind to")
//         // var host: String = "localhost"
//         // 
//         // @Flag(help: "Enable LSP debug logging")
//         // var debugLSP = false
//         
//         func run() throws {
//             if globalOptions.verbose {
//                 print("Starting LSP server in verbose mode...")
//             }
//             
//             print("Starting LSP server on \(host):\(port)")
//             
//             if debugLSP {
//                 print("LSP debug logging enabled")
//             }
//             
//             // Your LSP server implementation here
//             startLSPServer(host: host, port: port, verbose: globalOptions.verbose)
//         }
//     }
//
//     struct Build: AsyncParsableCommand {
//         static let configuration = CommandConfiguration(
//             commandName: "build",
//             abstract: "Build the PeoPl project",
//             discussion: "Builds the PeoPl project using the specified backend."
//         )
//
//         @Flag(name: .shortAndLong, help: "Use LLVM as the backend")
//         var llvm: Bool = false
//
//         func run() async throws {
//             if llvm {
//                 print("Building with LLVM backend...")
//                 // Implement LLVM build logic here
//             } else {
//                 print("No backend specified. Use --llvm to build with LLVM.")
//             }
//         }
//     }
// }
//
//
