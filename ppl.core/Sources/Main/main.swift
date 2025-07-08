import Foundation

func printUsage() {
    print("Usage: ppl <command>")
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

do {
    switch CommandLine.arguments {

    case let args where args.count == 2 && args[1] == "lsp":
        try await runLsp()
    case let args where args.count == 4:
        switch (args[1], args[2], args[3]) {
        case ("lsp", "proxy", let port):
            break
        case ("lsp", "socket", let port):
            break
        default:
            print("Wrong arguments")
            printUsage()
        }
    default:
        printUsage()
    }
} catch {
    print("Error: \(error)")
    printUsage()
}
