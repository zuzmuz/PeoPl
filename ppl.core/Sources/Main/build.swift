struct BuildCommand {
    let llvm: Bool
    
    init(args: [String]) throws(CommandLineError) {
        guard args.count > 2 else {
            throw CommandLineError.invalidArguments("no build command provided")
        }

        for i in 2..<args.count {
        }
        switch args[2] {
        case "llvm":
            self.llvm = true
        default:
            throw CommandLineError.invalidArguments(
                "unknown build command \(args[2])")
        }
    }
}
