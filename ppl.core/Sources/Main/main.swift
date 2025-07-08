import Foundation

enum CommandLineError: LocalizedError {
    case invalidArguments(String)

    var errorDescription: String? {
        switch self {
        case .invalidArguments(let message):
            return message
        }
    }
}

enum Command: String {
    case lsp
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

let args = CommandLine.arguments
do {
    guard args.count > 1 else {
        throw CommandLineError.invalidArguments("no command provided")
    }
    switch Command(rawValue: args[1]) {

    case .lsp:
        switch args.count {
        case 2:
            try await runLsp()
        case 3:
            throw CommandLineError.invalidArguments(
                "port missing for lsp command")
        case 4:
            switch (LspCommand(rawValue: args[2]), UInt16(args[3])) {
            case (.socket, let .some(port)):
                try await runLspSocket(port: port)
            case (.proxy, let .some(port)):
                try await runLspProxy(port: port)
            case (.some, .none):
                throw CommandLineError.invalidArguments(
                    "port <\(args[3])> is not a valid UInt16")
            case (.none, _):
                throw CommandLineError.invalidArguments(
                    "subcommand <\(args[2])> is not valid, choices [proxy, socket]")
            }
        default:
            throw CommandLineError.invalidArguments(
                "wrong number of arguments for lsp command")
        }
    default:
        throw CommandLineError.invalidArguments(
            "unknown command \(args[1])")
    }
} catch {
    print("error: \(error.localizedDescription)")
    print()
    printUsage()
}
