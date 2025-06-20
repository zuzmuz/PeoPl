import Foundation

do {
    let module = try Syntax.Module(
        source: """
            other: [c: Int, d: Int] -> Int {
                c * d
            }
            other: [a: Int, b: Int] -> Bool {
                a = b 
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
