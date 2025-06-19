import Foundation

do {
    let module = try Syntax.Module(
        source: """
            other: (Int) [a: Int, b: Int, c: Int] -> Int {
                - a |> other()
            }
            other: (Int) -> Int {
                - 2
            }
            main: () -> Int {
                1 |> other(a: 10, b: 1, c: 5)
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
