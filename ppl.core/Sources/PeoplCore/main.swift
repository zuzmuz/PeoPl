import Foundation

do {
    let module = try Syntax.Module(
        source: """
            other: [a: Int, b: Int] -> Int {
                42
            }
            other: [a: Int] -> Int {
                42
            }
            main: () -> Int {
                other(a: 2)
            }
            """,
        path: "main")

    let result = module.semanticCheck()

    switch result {
    case let .success(context):
        for (signature, definition) in context.definitions.valueDefinitions {
            print("definition: \(definition)")
            print("---")
        }
    case let .failure(error):
        print("Semantic check failed with errors: \(error.errors)")
    }

} catch {
    print("we catching \(error)")
}
