import Foundation

do {
    let module = try Syntax.Module(
        source: """
            other: [a: Int, b: Int, c: Int] -> Int {
                other(b: 1, a: 0)
            }
            other: [a: Int, b: Int] -> Int {
                3
            }
            main: () -> Int {
                other(a: 10, b: 1)
            }
            """,
        path: "main")

    let result = module.semanticCheck()

    switch result {
    case let .success(context):
        context.display()
        
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
