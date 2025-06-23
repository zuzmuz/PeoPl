import Foundation

do {
    let module = try Syntax.Module(
        source: """
            factorial: [a: Int, b: Int] -> Int {
                |if a = b| 10
                |if a > b| 20
                |if a < b| 30
            }
            main: () -> Int {
                other(a: 1, b: 2)
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
