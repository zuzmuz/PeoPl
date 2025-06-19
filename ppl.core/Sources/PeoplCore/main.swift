import Foundation

do {
    let module = try Syntax.Module(
        source: """
            other: () -> Int {
                3
            }
            main: () -> Int {
                other()
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
