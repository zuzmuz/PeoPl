import Foundation

func compileExample() {
    do {
        let module = try Syntax.Module(
            source: """
                factorial: [a: Int] -> Int {
                    |1| 1
                }
                main: [] -> Int {
                    facotrial(a: 5)
                }
                """,
            path: "main")

        let result = module.semanticCheck()

        switch result {
        case let .success(context):
            print(context.display())

            var llvm = LLVM.Builder(name: "name")

            try context.llvmBuildStatement(llvm: &llvm)

            print("llvm")
            print(llvm.generate())

        case let .failure(error):
            print("Semantic check failed with errors: \(error.errors)")
        }
    } catch {
        print("we catching \(error)")
    }
}

if CommandLine.arguments.count == 2 {
    let argument = CommandLine.arguments[1]
    switch argument {
    case "--lsp":
        try await runLSP()
    default:
        compileExample()
    }
} else {
    compileExample()
}
