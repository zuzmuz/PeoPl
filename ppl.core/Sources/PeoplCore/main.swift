import Foundation

do {
    let module = try Syntax.Module(
        source: """
            other: [a: Int] -> Int {
                |if a = 5| 10
                |_| 1
            }
            main: () -> Int {
                other(a: 5)
            }
            """,
        path: "main")

    let result = module.semanticCheck()

    switch result {
    case let .success(context):
        print(context.display())

        // var llvm = LLVM.Builder(name: "name")

        // try context.llvmBuildStatement(llvm: &llvm)

        print("llvm")
        // print(llvm.generate())

    case let .failure(error):
        print("Semantic check failed with errors: \(error.errors)")
    }
} catch {
    print("we catching \(error)")
}
